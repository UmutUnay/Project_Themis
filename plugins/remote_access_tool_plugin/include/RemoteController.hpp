#pragma once
// remote_access_tool/src/RemoteController.hpp

#include "Client.hpp"
#include "TCPHandler.hpp"
#include "RulesManager.hpp"
#include <string>
#include <vector>
#include <memory>

// ---------------------------------------------------------------------------
// RemoteController
//
// Top-level coordinator: loads the client list, owns the TCP server, and
// dispatches CLI commands to SSH/SCP/Shell/Plugin subsystems.
//
// The "Public" suffixed methods below are thin wrappers around the private
// implementations.  They exist so the Themis D-Bus plugin (functions.cpp)
// can call them without becoming a friend class or duplicating logic.
// They are intentionally narrow — each does exactly one thing and returns
// immediately (all SSH/SCP ops are already async internally).
// ---------------------------------------------------------------------------

class RemoteController {
public:
    RemoteController();
    ~RemoteController();

    using StatusChangeCallback = std::function<void(const std::string&)>;
    void setStatusChangeCallback(StatusChangeCallback callback) { m_statusCallback = callback; }
    void notifyStatusChange();
    
    // ── Startup ───────────────────────────────────────────────────────────────
    bool loadClients(const std::string& configPath);

    // ── Config push (SCP) ────────────────────────────────────────────────────
    // serverIp defaults to auto-detected local IP when empty.
    void pushConfigToClients  (const std::string& serverIp = "");
    void pushMsgConfigToClients();
    void pushAgentBinaryToClients();

    // ── TCP server ────────────────────────────────────────────────────────────
    void startTCPServer();
    void stopTCPServer();

    // ── Top-level CLI dispatch ────────────────────────────────────────────────
    void parseAndExecute(const std::string& line);

    // ── Help text ─────────────────────────────────────────────────────────────
    void printHelp()      const;
    void printRulesHelp() const;

    // ── Utilities (also used by main.cpp) ─────────────────────────────────────
    std::string trim(const std::string& str) const;
    std::string getServerStatus() const;

    // ── Themis plugin accessors ───────────────────────────────────────────────
    // Read-only view of the full client list (used by getClientList, getStatus).
    const std::vector<Client>& getClients() const { return m_clients; }

    // Raw pointer to the TCP handler so the plugin can call broadcastToAll()
    // and getConnectedClients() directly.  Never null after startTCPServer().
    TCPHandler* getTCPHandler() const { return m_tcpHandler.get(); }

    // Wrappers that delegate to the private SSH/SCP implementations.
    // All SSH/SCP operations are dispatched asynchronously and return
    // immediately — the result is streamed to stdout by the manager threads.
    void executeCommandPublic   (const std::string& clientId,
                                 const std::string& command);
    void executeCommandByTagPublic(const std::string& tag,
                                   const std::string& command);
    void executeCommandOnAllPublic(const std::string& command);
    void uploadFilePublic       (const std::string& clientId,
                                 const std::string& localPath,
                                 const std::string& remotePath);
    void downloadFilePublic     (const std::string& clientId,
                                 const std::string& remotePath,
                                 const std::string& localPath);

    // Push the current in-memory rules config to one connected client via TCP.
    void pushConfigToClientPublic(const std::string& clientId);

    // Access the rules manager for list/add/remove/enable/disable/settings.
    RulesManager& getRulesManager() { return m_rulesManager; }

private:
    // ── Command handlers ──────────────────────────────────────────────────────
    void handleRunCommandOriginal  (const std::string& line);
    void handleScpCommandOriginal  (const std::string& line);
    void handleShellCommandOriginal(const std::string& line);
    void handlePluginCommand       (const std::string& line);

    // ── Plugin sub-commands ───────────────────────────────────────────────────
    void cmdStatus();
    void cmdClients();
    void cmdConnected();
    void cmdMsg      (const std::string& clientId, const std::string& text);
    void cmdBroadcast(const std::string& text);
    void cmdTag      (const std::string& tag,      const std::string& text);

    void cmdRulesList    (const std::string& clientId);
    void cmdRulesAdd     (const std::string& clientId, const std::string& filterArgs);
    void cmdRulesRemove  (const std::string& clientId, const std::string& name);
    void cmdRulesSet     (const std::string& clientId, const std::string& name, bool enabled);
    void cmdRulesSettings(const std::string& clientId);
    void cmdRulesSetLog  (const std::string& clientId, const std::string& val);
    void cmdRulesSetFwd  (const std::string& clientId, const std::string& val);
    void cmdRulesPush    (const std::string& clientId);

    // Push the current in-memory config to a connected client over TCP.
    void pushConfigToClient(const std::string& clientId);

    // ── SSH / SCP / Shell dispatch ────────────────────────────────────────────
    void executeCommand      (const std::string& clientId, const std::string& command);
    void executeCommandByTag (const std::string& tag,      const std::string& command);
    void executeCommandOnAll (const std::string& command);
    void uploadFile          (const std::string& clientId, const std::string& localPath,
                              const std::string& remotePath);
    void downloadFile        (const std::string& clientId, const std::string& remotePath,
                              const std::string& localPath);
    void openInteractiveShell(const std::string& clientId);

    // ── Helpers ───────────────────────────────────────────────────────────────
    Client*              getClientById  (const std::string& id);
    std::vector<Client>  getClientsByTag(const std::string& tag) const;
    std::vector<std::string> tokenize   (const std::string& str, char delimiter = ' ') const;
    bool                 isBlank        (const std::string& str) const;

    // ── State ─────────────────────────────────────────────────────────────────
    std::vector<Client>         m_clients;
    std::unique_ptr<TCPHandler> m_tcpHandler;
    RulesManager                m_rulesManager;
    std::string                 m_serverIp;
    
    StatusChangeCallback m_statusCallback;
};
