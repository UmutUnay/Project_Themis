// rat_plugin/src/functions.cpp
//
// Themis listener callbacks for the Remote Access Tool plugin.
//
// Convention (identical to the firewalld plugin):
//   • Every listener callback receives a single std::string that is a
//     filesystem path to a JSON file.  For "get" operations this is the
//     output path; for "set/run" operations it is the input payload path.
//   • After completing work the function posts a response JSON to
//     SenderThread so Themis ProjectThemis is notified.
//   • The response always contains at minimum:
//       { "plugin_id": "rat", "state": "true"|"false" }
//   • The RAT server is reached via its existing RemoteController API,
//     which is compiled into the same binary.  This plugin therefore lives
//     inside the RAT server process — it IS the server process, with a
//     Themis D-Bus front-end bolted on, exactly as the firewalld plugin
//     is the firewalld configuration daemon with a Themis front-end.
//
// NOTE: g_controller is a pointer to the RemoteController instance that is
// created in main() and set before enableThreads() is called.  All callbacks
// reach the controller through this pointer.  It is never null when a
// callback fires because Themis only delivers messages after enableThreads()
// returns, which happens after the controller is fully initialised.

#include "functions.hh"
#include "RemoteController.hpp"
#include "SSHManager.hpp"
#include "SCPManager.hpp"
#include "MessageHandler.hpp"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <chrono>
#include <thread>

using json = nlohmann::json;
namespace fs = std::filesystem;

// Set by main() after the RemoteController is initialised.
// Declared extern so main.cpp can assign it without including every RAT header.
extern RemoteController* g_controller;

static std::atomic<bool> g_autoRefreshEnabled(false);
static std::thread g_autoRefreshThread;
static std::string g_currentConfigPath;

// ── Internal helpers ──────────────────────────────────────────────────────────

static std::string pluginId() { return "remote_access_tool"; }

// Post a response to Themis ProjectThemis.
// member is the D-Bus member name that Themis listens on for this event
// (e.g. "jsonGenerated", "confGenerated", "confGenerated").
static void sendResponse(const json& response, const std::string& member)
{
    std::string msg  = response.dump(4);
    std::string dest = "org.themis.ProjectThemis";
    Themis::SenderThread::instance().addMessage(
        msg, "org.themis.GenericBus", dest, "default",
        member, Themis::OsFlag_t::NOFLAG);
}

// Build the boilerplate response object.
static json makeResponse(bool ok)
{
    json r;
    r["plugin_id"] = pluginId();
    r["state"]     = ok ? "true" : "false";
    return r;
}

// Read and parse a JSON file.  Returns a discarded value on failure.
static json readJson(const std::string& path)
{
    std::ifstream f(path);
    if (!f.is_open()) return json{};
    json j = json::parse(f, nullptr, /*exceptions=*/false);
    return j;
}

// Write pretty-printed JSON to path.  Returns false on failure.
static bool writeJson(const std::string& path, const json& j)
{
    std::ofstream f(path);
    if (!f.is_open()) {
        std::cerr << "[RAT Plugin] Failed to open " << path << " for writing" << std::endl;
        return false;
    }
    f << j.dump(4) << '\n';
    bool success = f.good();
    if (success) {
        std::cout << "[RAT Plugin] Successfully wrote to " << path << std::endl;
    } else {
        std::cerr << "[RAT Plugin] Failed to write to " << path << std::endl;
    }
    return success;
}

/*
static void emitConfigChangedSignal(const std::string& configId) {
    try {
        // Create a simple signal message
        auto& dbus = Themis::dbus::instance();
        dbus.emitSignal(
            "/org/themis/remote_access_tool",
            "org.themis.remote_access_tool",
            "ConfigChanged",
            configId
        );
        std::cout << "[RAT Plugin] Emitted ConfigChanged signal for: " << configId << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "[RAT Plugin] Failed to emit signal: " << e.what() << std::endl;
    }
}
*/

// Real-time status update callback
static void updateStatusOutput(const std::string& status) {
    if (g_currentConfigPath.empty()) return;
    
    json cfg = readJson(g_currentConfigPath);
    if (!cfg.is_discarded()) {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::string timestamp = std::ctime(&time_t);
        timestamp.pop_back();
        
        cfg["status_output"] = "Last updated: " + timestamp + "\n" + status;
        
        if (writeJson(g_currentConfigPath, cfg)) {
            // Emit D-Bus signal to notify Themis
            /*emitConfigChangedSignal("ratConfig");*/
            
            // Also send response for immediate update
            json r = makeResponse(true);
            sendResponse(r, "confGenerated");
        }
    }
}


// Auto-refresh loop (kept for backward compatibility, but real-time is preferred)
static void autoRefreshLoop(const std::string& outputPath) {
    while (g_autoRefreshEnabled) {
        std::this_thread::sleep_for(std::chrono::seconds(3));
        
        if (g_controller && g_autoRefreshEnabled) {
            // Generate status output
            std::string out;
            const auto& clients = g_controller->getClients();
            std::vector<std::string> connected;
            if (g_controller->getTCPHandler())
                connected = g_controller->getTCPHandler()->getConnectedClients();
            
            for (const auto& c : clients) {
                bool isConn = std::find(connected.begin(), connected.end(), c.getId()) != connected.end();
                out += c.getId() + " [" + (isConn ? "● CONNECTED" : "○ DISCONNECTED") + "]\n";
            }
            
            // Read existing config to preserve other settings
            json cfg = readJson(outputPath);
            if (!cfg.is_discarded()) {
                cfg["status_output"] = out;
                writeJson(outputPath, cfg);
            }
        }
    }
}

// ── Listener callbacks ────────────────────────────────────────────────────────

bool testRAT(std::string /*str*/)
{
    printf("[RAT Plugin] testRAT called\n");
    json r = makeResponse(true);
    r["message"] = "RAT plugin is alive";
    sendResponse(r, "jsonGenerated");
    return true;
}

// ── getRatConfig ──────────────────────────────────────────────────────────────
// Returns the main RAT configuration object used by the Themis GUI.
// This is a flat key:value map of all current UI-controllable settings.
// The GUI calls getConfig("ratConfig") after getConfigsOfType("configBrowser").

bool getRatConfig(std::string outputPath)
{
    // Serve saved config if it exists, resetting action switches
    {
        std::ifstream existing(outputPath);
        if (existing.is_open()) {
            json j = json::parse(existing, nullptr, false);
            if (!j.is_discarded()) {
                const char* switches[] = {
                    "status_refresh","run_execute","scp_upload","scp_download",
                    "msg_send","msg_broadcast","rules_push","rules_list_fetch",
                    "rules_enable","rules_disable","rules_add_execute",
                    "rules_rm_execute","rules_cfg_apply",nullptr};
                for (int i = 0; switches[i]; i++) j[switches[i]] = "no";
                writeJson(outputPath, j);
                sendResponse(makeResponse(true), "jsonGenerated");
                return true;
            }
        }
    }
    // First time — build defaults
    json cfg;
    cfg["status_refresh"]       = "no";
    cfg["status_output"]        = "";
    cfg["run_client_id"]        = "";
    cfg["run_tag"]              = "";
    cfg["run_cmd"]              = "";
    cfg["run_execute"]          = "no";
    cfg["run_output"]           = "";
    cfg["scp_client_id"]        = "";
    cfg["scp_local"]            = "";
    cfg["scp_remote"]           = "";
    cfg["scp_upload"]           = "no";
    cfg["scp_dl_client_id"]     = "";
    cfg["scp_dl_remote"]        = "";
    cfg["scp_dl_local"]         = "";
    cfg["scp_download"]         = "no";
    cfg["msg_client_id"]        = "";
    cfg["msg_text"]             = "";
    cfg["msg_send"]             = "no";
    cfg["msg_broadcast"]        = "no";
    cfg["rules_push_client_id"] = "";
    cfg["rules_push"]           = "no";
    cfg["rules_list_client_id"] = "";
    cfg["rules_list_fetch"]     = "no";
    cfg["rules_list_output"]    = "";
    cfg["rules_toggle_name"]    = "";
    cfg["rules_enable"]         = "no";
    cfg["rules_disable"]        = "no";
    cfg["rules_add_client_id"]  = "";
    cfg["rules_add_name"]       = "";
    cfg["rules_add_bus"]        = "session";
    cfg["rules_add_match"]      = "";
    cfg["rules_add_types"]      = "";
    cfg["rules_add_log"]        = "no";
    cfg["rules_add_forward"]    = "no";
    cfg["rules_add_execute"]    = "no";
    cfg["rules_rm_client_id"]   = "";
    cfg["rules_rm_name"]        = "";
    cfg["rules_rm_execute"]     = "no";
    cfg["rules_cfg_client_id"]  = "";
    cfg["rules_cfg_log"]        = "no";
    cfg["rules_cfg_fwd"]        = "no";
    cfg["rules_cfg_apply"]      = "no";

    if (!writeJson(outputPath, cfg)) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }
    sendResponse(makeResponse(true), "jsonGenerated");
    return true;
}

// ── setRatConfig ──────────────────────────────────────────────────────────────
// Called by Themis when the user saves the config (hits the Save button).
// Reads the flat config map and dispatches any action whose switch is "yes".
// After acting, resets all action switches to "no" and writes back.

bool setRatConfig(std::string inputPath)
{
    json cfg = readJson(inputPath);
    if (cfg.is_discarded()) {
        std::cerr << "[RAT Plugin] Failed to read config from: " << inputPath << std::endl;
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }
    
    // Debug: Print what we received
    std::cout << "[RAT Plugin] setRatConfig received: " << cfg.dump(2) << std::endl;
    
    if (!g_controller) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    // ── Register real-time status callback (only once) ──────────────────────
    static bool callbackRegistered = false;
    
    if (!callbackRegistered) {
        // Store the config path for real-time updates
        g_currentConfigPath = inputPath;
        
        // Register the callback with the controller
        g_controller->setStatusChangeCallback(updateStatusOutput);
        callbackRegistered = true;
        std::cout << "[RAT Plugin] Registered real-time status callback" << std::endl;
        
        // Trigger initial status update
        updateStatusOutput(g_controller->getServerStatus());
    }

    auto isTrue = [&](const std::string& key) -> bool {
        if (!cfg.contains(key)) return false;
        
        // Handle different possible types
        if (cfg[key].is_string()) {
            std::string val = cfg[key].get<std::string>();
            return val == "yes" || val == "true" || val == "1";
        }
        else if (cfg[key].is_boolean()) {
            return cfg[key].get<bool>();
        }
        else if (cfg[key].is_number()) {
            return cfg[key].get<int>() != 0;
        }
        return false;
    };
    
    auto str = [&](const std::string& key) -> std::string {
        return cfg.contains(key) && cfg[key].is_string() ? cfg[key].get<std::string>() : "";
    };

    // ── Status refresh (manual button) ────────────────────────────────────
    if (isTrue("status_refresh")) {
        std::cout << "[RAT Plugin] Manual status refresh triggered" << std::endl;
        
        // Get server status using the existing method
        std::string statusOutput = g_controller->getServerStatus();
        
        // Add timestamp
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::string timestamp = std::ctime(&time_t);
        timestamp.pop_back(); // Remove newline
        
        cfg["status_output"] = "Last updated: " + timestamp + "\n" + statusOutput;
        
        // Reset the button - handle both string and boolean types
        if (cfg["status_refresh"].is_string()) {
            cfg["status_refresh"] = "no";
        } else {
            cfg["status_refresh"] = false;
        }
        
        std::cout << "[RAT Plugin] Manual status update completed" << std::endl;
    }

    // ── Run command ───────────────────────────────────────────────────────
    if (isTrue("run_execute")) {
        std::string clientId = str("run_client_id");
        std::string tag      = str("run_tag");
        std::string cmd      = str("run_cmd");
        if (!cmd.empty()) {
            if (!clientId.empty())
                g_controller->executeCommandPublic(clientId, cmd);
            else if (!tag.empty())
                g_controller->executeCommandByTagPublic(tag, cmd);
            else
                g_controller->executeCommandOnAllPublic(cmd);
        }
        cfg["run_execute"] = "no";
        cfg["run_output"]  = "Command dispatched: " + cmd;
    }

    // ── SCP upload ────────────────────────────────────────────────────────
    if (isTrue("scp_upload")) {
        std::string clientId = str("scp_client_id");
        std::string local    = str("scp_local");
        std::string remote   = str("scp_remote");
        if (!clientId.empty() && !local.empty() && !remote.empty())
            g_controller->uploadFilePublic(clientId, local, remote);
        cfg["scp_upload"] = "no";
    }

    // ── SCP download ──────────────────────────────────────────────────────
    if (isTrue("scp_download")) {
        std::string clientId = str("scp_dl_client_id");
        std::string remote   = str("scp_dl_remote");
        std::string local    = str("scp_dl_local");
        if (!clientId.empty() && !remote.empty() && !local.empty())
            g_controller->downloadFilePublic(clientId, remote, local);
        cfg["scp_download"] = "no";
    }

    // ── Send message ──────────────────────────────────────────────────────
    if (isTrue("msg_send")) {
        std::string clientId = str("msg_client_id");
        std::string text     = str("msg_text");
        if (!text.empty())
            MessageHandler::getInstance().sendMsg(clientId, text);
        cfg["msg_send"] = "no";
    }

    // ── Broadcast ─────────────────────────────────────────────────────────
    if (isTrue("msg_broadcast")) {
        std::string text = str("msg_text");
        if (!text.empty() && g_controller->getTCPHandler())
            g_controller->getTCPHandler()->broadcastToAll(text);
        cfg["msg_broadcast"] = "no";
    }

    // ── Rules: push ───────────────────────────────────────────────────────
    if (isTrue("rules_push")) {
        std::string clientId = str("rules_push_client_id");
        if (!clientId.empty())
            g_controller->pushConfigToClientPublic(clientId);
        cfg["rules_push"] = "no";
    }

    // ── Rules: list ───────────────────────────────────────────────────────
    if (isTrue("rules_list_fetch")) {
        std::string clientId = str("rules_list_client_id");
        if (!clientId.empty()) {
            auto filters = g_controller->getRulesManager().listFilters(clientId);
            std::string out;
            for (const auto& f : filters) {
                out += f.name + " [" +
                       (f.enabled ? "enabled" : "disabled") +
                       "] bus=" + f.bus + "\n";
            }
            cfg["rules_list_output"] = out.empty() ? "(no filters)" : out;
        }
        cfg["rules_list_fetch"] = "no";
    }

    // ── Rules: enable ─────────────────────────────────────────────────────
    if (isTrue("rules_enable")) {
        std::string clientId = str("rules_list_client_id");
        std::string name     = str("rules_toggle_name");
        if (!clientId.empty() && !name.empty())
            g_controller->getRulesManager().setFilterEnabled(clientId, name, true);
        cfg["rules_enable"] = "no";
    }

    // ── Rules: disable ────────────────────────────────────────────────────
    if (isTrue("rules_disable")) {
        std::string clientId = str("rules_list_client_id");
        std::string name     = str("rules_toggle_name");
        if (!clientId.empty() && !name.empty())
            g_controller->getRulesManager().setFilterEnabled(clientId, name, false);
        cfg["rules_disable"] = "no";
    }

    // ── Rules: add ────────────────────────────────────────────────────────
    if (isTrue("rules_add_execute")) {
        std::string clientId = str("rules_add_client_id");
        std::string name     = str("rules_add_name");
        if (!clientId.empty() && !name.empty()) {
            DbusFilter f;
            f.name    = name;
            f.bus     = str("rules_add_bus");
            f.match   = str("rules_add_match");
            f.log     = isTrue("rules_add_log");
            f.forward = isTrue("rules_add_forward");
            f.enabled = true;
            // Parse types (comma-separated)
            std::stringstream ss(str("rules_add_types"));
            std::string tok;
            while (std::getline(ss, tok, ',')) {
                tok.erase(0, tok.find_first_not_of(" "));
                tok.erase(tok.find_last_not_of(" ") + 1);
                if (!tok.empty()) f.types.push_back(tok);
            }
            g_controller->getRulesManager().addFilter(clientId, f);
        }
        cfg["rules_add_execute"] = "no";
        if (cfg.contains("rules_add_log")) cfg["rules_add_log"] = "no";
        if (cfg.contains("rules_add_forward")) cfg["rules_add_forward"] = "no";
    }

    // ── Rules: remove ─────────────────────────────────────────────────────
    if (isTrue("rules_rm_execute")) {
        std::string clientId = str("rules_rm_client_id");
        std::string name     = str("rules_rm_name");
        if (!clientId.empty() && !name.empty())
            g_controller->getRulesManager().removeFilter(clientId, name);
        cfg["rules_rm_execute"] = "no";
    }

    // ── Rules: global settings ────────────────────────────────────────────
    if (isTrue("rules_cfg_apply")) {
        std::string clientId = str("rules_cfg_client_id");
        if (!clientId.empty()) {
            GlobalSettings s = g_controller->getRulesManager().getSettings(clientId);
            s.default_log     = isTrue("rules_cfg_log");
            s.default_forward = isTrue("rules_cfg_fwd");
            g_controller->getRulesManager().setSettings(clientId, s);
        }
        cfg["rules_cfg_apply"] = "no";
        if (cfg.contains("rules_cfg_log")) cfg["rules_cfg_log"] = "no";
        if (cfg.contains("rules_cfg_fwd")) cfg["rules_cfg_fwd"] = "no";
    }

    // Write updated config back so the GUI shows reset switches
    writeJson(inputPath, cfg);
    sendResponse(makeResponse(true), "confGenerated");
    return true;
}

// ── getClientList ─────────────────────────────────────────────────────────────
// Writes a JSON array of client objects to outputPath, then notifies Themis.
// Each element: { "id": "...", "user": "...", "ip": "...", "port": N,
//                 "tags": [...], "connected": bool }

bool getClientList(std::string outputPath)
{
    if (!g_controller) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    const auto& clients = g_controller->getClients();
    json arr = json::array();

    for (const auto& c : clients) {
        json entry;
        entry["id"]        = c.getId();
        entry["user"]      = c.getUser();
        entry["ip"]        = c.getIp();
        entry["port"]      = c.getPort();
        entry["tags"]      = c.getTags();
        entry["connected"] = c.isConnected();
        arr.push_back(entry);
    }

    if (!writeJson(outputPath, arr)) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    json r = makeResponse(true);
    sendResponse(r, "jsonGenerated");
    return true;
}

// ── getStatus ─────────────────────────────────────────────────────────────────
// Writes a richer status object: server info + per-client connected state.

bool getStatus(std::string outputPath)
{
    if (!g_controller) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    json out;
    out["plugin_id"] = pluginId();

    // Connected client IDs from the TCP layer
    std::vector<std::string> connected;
    if (g_controller->getTCPHandler())
        connected = g_controller->getTCPHandler()->getConnectedClients();

    json clientsArr = json::array();
    for (const auto& c : g_controller->getClients()) {
        json entry;
        entry["id"]        = c.getId();
        entry["ip"]        = c.getIp();
        entry["connected"] = std::find(connected.begin(),
                           connected.end(),
                           c.getId()) != connected.end();
        clientsArr.push_back(entry);
    }
    out["clients"]           = clientsArr;
    out["connected_count"]   = (int)connected.size();
    out["total_count"]       = (int)g_controller->getClients().size();

    if (!writeJson(outputPath, out)) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    sendResponse(makeResponse(true), "jsonGenerated");
    return true;
}

// ── runCommand ────────────────────────────────────────────────────────────────
// Input JSON: { "client": "<id>", "cmd": "<shell command>" }

bool runCommand(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() || !j.contains("client") || !j.contains("cmd")) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    std::string clientId = j["client"].get<std::string>();
    std::string cmd      = j["cmd"].get<std::string>();

    if (!g_controller) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    // executeCommand is async — it dispatches to SSHManager and returns
    // immediately.  The result is streamed to stdout by SSHManager.
    // We notify Themis that the command was dispatched (not yet completed).
    g_controller->executeCommandPublic(clientId, cmd);

    json r = makeResponse(true);
    r["client"] = clientId;
    r["cmd"]    = cmd;
    sendResponse(r, "confGenerated");
    return true;
}

// ── runCommandAll ─────────────────────────────────────────────────────────────
// Input JSON: { "cmd": "<shell command>" }

bool runCommandAll(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() || !j.contains("cmd")) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    std::string cmd = j["cmd"].get<std::string>();

    if (!g_controller) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    g_controller->executeCommandOnAllPublic(cmd);

    json r = makeResponse(true);
    r["cmd"]   = cmd;
    r["scope"] = "all";
    sendResponse(r, "confGenerated");
    return true;
}

// ── runCommandTag ─────────────────────────────────────────────────────────────
// Input JSON: { "tag": "<tag>", "cmd": "<shell command>" }

bool runCommandTag(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() || !j.contains("tag") || !j.contains("cmd")) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    std::string tag = j["tag"].get<std::string>();
    std::string cmd = j["cmd"].get<std::string>();

    if (!g_controller) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    g_controller->executeCommandByTagPublic(tag, cmd);

    json r = makeResponse(true);
    r["tag"] = tag;
    r["cmd"] = cmd;
    sendResponse(r, "confGenerated");
    return true;
}

// ── scpUpload ─────────────────────────────────────────────────────────────────
// Input JSON: { "client": "<id>", "local": "<path>", "remote": "<path>" }

bool scpUpload(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() ||
        !j.contains("client") || !j.contains("local") || !j.contains("remote")) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    std::string clientId   = j["client"].get<std::string>();
    std::string localPath  = j["local"].get<std::string>();
    std::string remotePath = j["remote"].get<std::string>();

    if (!g_controller) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    g_controller->uploadFilePublic(clientId, localPath, remotePath);

    json r = makeResponse(true);
    r["client"] = clientId;
    sendResponse(r, "confGenerated");
    return true;
}

// ── scpDownload ───────────────────────────────────────────────────────────────
// Input JSON: { "client": "<id>", "remote": "<path>", "local": "<path>" }

bool scpDownload(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() ||
        !j.contains("client") || !j.contains("remote") || !j.contains("local")) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    std::string clientId   = j["client"].get<std::string>();
    std::string remotePath = j["remote"].get<std::string>();
    std::string localPath  = j["local"].get<std::string>();

    if (!g_controller) {
        sendResponse(makeResponse(false), "confGenerated");
        return false;
    }

    g_controller->downloadFilePublic(clientId, remotePath, localPath);

    json r = makeResponse(true);
    r["client"] = clientId;
    sendResponse(r, "confGenerated");
    return true;
}

// ── sendMessage ───────────────────────────────────────────────────────────────
// Input JSON: { "client": "<id>", "message": "<text>" }

bool sendMessage(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() || !j.contains("client") || !j.contains("message")) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    std::string clientId = j["client"].get<std::string>();
    std::string message  = j["message"].get<std::string>();

    if (!g_controller) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    MessageHandler::getInstance().sendMsg(clientId, message);

    json r = makeResponse(true);
    r["client"] = clientId;
    sendResponse(r, "jsonGenerated");
    return true;
}

// ── broadcastMessage ──────────────────────────────────────────────────────────
// Input JSON: { "message": "<text>" }

bool broadcastMessage(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() || !j.contains("message")) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    std::string message = j["message"].get<std::string>();

    if (!g_controller || !g_controller->getTCPHandler()) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    g_controller->getTCPHandler()->broadcastToAll(message);

    json r = makeResponse(true);
    sendResponse(r, "jsonGenerated");
    return true;
}

// ── pushRules ─────────────────────────────────────────────────────────────────
// Input JSON: { "client": "<id>" }

bool pushRules(std::string inputPath)
{
    json j = readJson(inputPath);
    if (j.is_discarded() || !j.contains("client")) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    std::string clientId = j["client"].get<std::string>();

    if (!g_controller) {
        sendResponse(makeResponse(false), "jsonGenerated");
        return false;
    }

    g_controller->pushConfigToClientPublic(clientId);

    json r = makeResponse(true);
    r["client"] = clientId;
    sendResponse(r, "jsonGenerated");
    return true;
}

// ── reloadPluginMetadata ──────────────────────────────────────────────────────
// Builds the two metadata files that Themis expects under /etc/themis/plugins/rat/:
//
//   conf_type.json  — array of config descriptors (one entry per operation)
//   dbus_cred.json  — maps each operation to its D-Bus bus/interface/member
//
// The UI schema is STATIC and must be provided as a pre‑installed file.
// No dynamic generation of ui.json is performed.

bool reloadPluginMetadata(std::string /*input*/)
{
    // Plugin root matches the plugin_id in bin_name.csv and the directory
    // created by plugin_setup.sh.
    const fs::path pluginRoot   = "/etc/themis/plugins/remote_access_tool";
    const fs::path confTypePath = pluginRoot / "conf_type.json";
    const fs::path dbusCredPath = pluginRoot / "dbus_cred.json";
    const fs::path uiPath       = pluginRoot / "ui/ui.json";

    try {
        fs::create_directories(pluginRoot / "ui");

        // ── conf_type.json ────────────────────────────────────────────────
        json confType = json::array();

        // The MainItem's configType is "configBrowser".
        // getConfigsOfType() is called with this type, so there must be
        // exactly one config entry of this type for getData() to succeed.
        // All RAT operations share a single config file ("ratConfig").
        auto addConf = [&](const std::string& configId,
                       const std::string& configType,
                       const std::string& title) {
            json e;
            e["pluginId"]   = pluginId();
            e["configId"]   = configId;
            e["configType"] = configType;
            e["title"]      = title;
            confType.push_back(e);
        };

        // This entry satisfies getConfigsOfType(pluginId, "configBrowser").first
        addConf("ratConfig",        "configBrowser", "RAT - Configuration");

        // Individual operation configs (kept for direct access if needed)
        addConf("clientList",       "JSON", "RAT - Client List");
        addConf("status",           "JSON", "RAT - Connection Status");
        addConf("runCommand",       "JSON", "RAT - Run Command");
        addConf("runCommandAll",    "JSON", "RAT - Run Command (All)");
        addConf("runCommandTag",    "JSON", "RAT - Run Command (Tag)");
        addConf("scpUpload",        "JSON", "RAT - Upload File");
        addConf("scpDownload",      "JSON", "RAT - Download File");
        addConf("sendMessage",      "JSON", "RAT - Send Message");
        addConf("broadcastMessage", "JSON", "RAT - Broadcast Message");
        addConf("pushRules",        "JSON", "RAT - Push Rules");

        if (!writeJson(confTypePath.string(), confType)) {
            fprintf(stderr, "[RAT Plugin] Failed to write %s\n", confTypePath.string().c_str());
            return false;
        }

        // ── dbus_cred.json ────────────────────────────────────────────────
        json dbusCred;
        dbusCred["getConfig"] = json::object();
        dbusCred["setConfig"] = json::object();

        const std::string bus       = "org.themis.remote_access_tool";
        const std::string interface = "org.themis.GenericBus";

        auto addCred = [&](const std::string& configId,
                       const std::string& getMember,
                       const std::string& setMember) {
            dbusCred["getConfig"][configId] = {
                { "interface", interface },
                { "bus",       bus       },
                { "member",    getMember }
            };
            dbusCred["setConfig"][configId] = {
                { "interface", interface },
                { "bus",       bus       },
                { "member",    setMember }
            };
            dbusCred["signals"] = json::array({
                "configChanged"
            });
        };

        addCred("ratConfig",        "getRatConfig",     "setRatConfig");
        addCred("clientList",       "getClientList",    "getClientList");
        addCred("status",           "getStatus",        "getStatus");
        addCred("runCommand",       "runCommand",       "runCommand");
        addCred("runCommandAll",    "runCommandAll",    "runCommandAll");
        addCred("runCommandTag",    "runCommandTag",    "runCommandTag");
        addCred("scpUpload",        "scpUpload",        "scpUpload");
        addCred("scpDownload",      "scpDownload",      "scpDownload");
        addCred("sendMessage",      "sendMessage",      "sendMessage");
        addCred("broadcastMessage", "broadcastMessage", "broadcastMessage");
        addCred("pushRules",        "pushRules",        "pushRules");

        if (!writeJson(dbusCredPath.string(), dbusCred)) {
            fprintf(stderr, "[RAT Plugin] Failed to write %s\n", dbusCredPath.string().c_str());
            return false;
        }

        // ── ui.json ───────────────────────────────────────────────────────
        // UI schema is static and must be provided as a pre‑installed file.
        // No dynamic generation is performed here.  If the file is missing,
        // a warning is logged but the function still returns success because
        // the other metadata files were written correctly.
        if (!fs::exists(uiPath)) {
            fprintf(stderr,
                    "[RAT Plugin] Warning: static UI file %s does not exist. "
                    "Please ensure it is installed.\n",
                    uiPath.string().c_str());
        }

        return true;

    } catch (const std::exception& e) {
        fprintf(stderr, "[RAT Plugin] reloadPluginMetadata: %s\n", e.what());
        return false;
    }
}