#ifndef RAT_PLUGIN_FUNCTIONS_HH
#define RAT_PLUGIN_FUNCTIONS_HH

#include <string>
#include <fstream>
#include <nlohmann/json.hpp>
#include <dbus.hh>
#include "senderThread.hh"

// ── Themis listener callbacks ─────────────────────────────────────────────────
// Each function is registered with ListenerThread::addFunction().
// The string argument is the path to a JSON file that acts as the I/O
// payload, exactly mirroring the firewalld plugin convention.

// Connectivity probe — returns true and sends an ACK over the sender thread.
bool testRAT(std::string str);

// Client list — writes a JSON array of all configured clients to outputPath.
bool getClientList(std::string outputPath);

// Run a shell command on one client (JSON payload: {"client":"id","cmd":"..."}).
bool runCommand(std::string inputPath);

// Run a shell command on every client (JSON payload: {"cmd":"..."}).
bool runCommandAll(std::string inputPath);

// Run a shell command on all clients that carry a given tag
// (JSON payload: {"tag":"t","cmd":"..."}).
bool runCommandTag(std::string inputPath);

// Upload a file to one client
// (JSON payload: {"client":"id","local":"path","remote":"path"}).
bool scpUpload(std::string inputPath);

// Download a file from one client
// (JSON payload: {"client":"id","remote":"path","local":"path"}).
bool scpDownload(std::string inputPath);

// Send a TCP message to a connected client
// (JSON payload: {"client":"id","message":"text"}).
bool sendMessage(std::string inputPath);

// Broadcast a TCP message to all connected clients
// (JSON payload: {"message":"text"}).
bool broadcastMessage(std::string inputPath);

// Push the current msg_config rules to one client over TCP
// (JSON payload: {"client":"id"}).
bool pushRules(std::string inputPath);

// Get runtime connection status for all clients — writes JSON to outputPath.
bool getStatus(std::string outputPath);

// Get the main RAT config object used by the Themis GUI.
bool getRatConfig(std::string outputPath);

// Apply the RAT config — dispatches actions from the flat config map.
bool setRatConfig(std::string inputPath);

// ── Startup helper ────────────────────────────────────────────────────────────
// Called once from main() before setDbus(). Builds the Themis plugin metadata
// files (conf_type.json, dbus_cred.json, ui/ui.json) under
// /etc/themis/plugins/rat/.
bool reloadPluginMetadata(std::string input);

#endif // RAT_PLUGIN_FUNCTIONS_HH
