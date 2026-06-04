// remote_access_tool/src/main.cpp
//
// The RAT server process now also acts as a Themis D-Bus plugin.
// After the RemoteController is fully initialised the Themis D-Bus is
// registered and the listener/sender threads are started.  From that point
// Themis ProjectThemis can invoke any operation on the RAT through D-Bus,
// exactly as it controls the firewalld plugin.
//
#include <iostream>
#include <csignal>
#include <sys/wait.h>
#include <atomic>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>
#include "RemoteController.hpp"
#include "SSHManager.hpp"
#include "ShellManager.hpp"
#include "SCPManager.hpp"
#include "LockfileManager.hpp"

// Themis D-Bus plugin headers
#include <dbus.hh>
#include "senderThread.hh"
#include "listenerThread.hh"
#include "functions.hh"   // rat_plugin/src/functions.hh

static std::atomic<bool> g_shutdownRequested(false);
static LockfileManager*  g_lockManager = nullptr;
// Non-static so functions.cpp can reach it via:
//   extern RemoteController* g_controller;
RemoteController*        g_controller  = nullptr;
static int               g_pipe[2]     = {-1, -1};

static void signalHandler(int sig) {
    if (g_shutdownRequested.exchange(true))
        return;
    if (g_pipe[1] != -1) {
        char x = 'x';
        write(g_pipe[1], &x, 1);
    }
}

static void sigchldHandler(int) {
    while (waitpid(-1, nullptr, WNOHANG) > 0)
        ;
}

int main(int argc, char* argv[]) {
    struct sigaction sa;
    sa.sa_handler = signalHandler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;   // no SA_RESTART → select() gets interrupted
    sigaction(SIGINT,  &sa, nullptr);
    sigaction(SIGTERM, &sa, nullptr);
    sigaction(SIGQUIT, &sa, nullptr);
    sigaction(SIGABRT, &sa, nullptr);
    sigaction(SIGHUP,  &sa, nullptr);

    struct sigaction sa_chld;
    sa_chld.sa_handler = sigchldHandler;
    sigemptyset(&sa_chld.sa_mask);
    sa_chld.sa_flags = SA_RESTART;
    sigaction(SIGCHLD, &sa_chld, nullptr);

    if (pipe(g_pipe) < 0) {
        std::cerr << "Warning: Failed to create shutdown pipe\n";
        g_pipe[0] = g_pipe[1] = -1;
    } else {
        int flags = fcntl(g_pipe[0], F_GETFL, 0);
        fcntl(g_pipe[0], F_SETFL, flags | O_NONBLOCK);
    }

    LockfileManager lockManager;
    g_lockManager = &lockManager;

    if (!lockManager.acquireLock())
        return 1;

    const std::string sshKey = "/home/yeet/.ssh/id_ed25519";
    SSHManager::getInstance().setSSHKeyPath(sshKey);
    ShellManager::getInstance().setSSHKeyPath(sshKey);
    SCPManager::getInstance().setSSHKeyPath(sshKey);

    std::string configPath = "/etc/themis/plugins/remote_access_tool/clients.json";
    if (argc > 1)
        configPath = argv[1];

    RemoteController controller;
    g_controller = &controller;
    std::cout << "[DEBUG] configPath = '" << configPath << "'" << std::endl;
    
    if (!controller.loadClients(configPath)) {
        std::cerr << "Failed to load clients from " << configPath << std::endl;
        lockManager.releaseLock();
        g_lockManager = nullptr;
        return 1;
    }

    controller.startTCPServer();
    controller.pushConfigToClients();
    controller.pushMsgConfigToClients();
    controller.pushAgentBinaryToClients();

    // ── Themis D-Bus plugin registration ──────────────────────────────────────
    reloadPluginMetadata("");

    // Use init() not connect(): init() is the server/producer call —
    // it requests ownership with DBUS_NAME_FLAG_REPLACE_EXISTING.
    // connect() is the client call (DBUS_NAME_FLAG_DO_NOT_QUEUE) and will
    // be denied for a plugin that needs to own its name on the system bus.
    if (!Themis::dbus::instance().init("org.themis.remote_access_tool")) {
        std::cerr << "[Themis] FATAL: Failed to register org.themis.remote_access_tool on D-Bus.\n"
                  << "  Ensure /usr/share/dbus-1/system.d/org.themis.remote_access_tool.conf\n"
                  << "  grants <allow own> to user '"
                  << (getenv("USER") ? getenv("USER") : "?") << "'\n"
                  << "  then run: sudo systemctl reload dbus\n";
    } else {
        std::cout << "[Themis] Registered as org.themis.remote_access_tool\n";
    }

    Themis::dbus::instance().loadRules(
        "/etc/themis/rules/themis.remote_access_tool.rule.csv");
    Themis::dbus::instance().applyRules();

    // Wire up the listener callbacks — each name matches the "member" field
    // written into dbus_cred.json by reloadPluginMetadata().
    Themis::ListenerThread::instance().setBus(&(Themis::dbus::instance()));
    Themis::ListenerThread::instance().addFunction("testRAT",          testRAT);
    Themis::ListenerThread::instance().addFunction("getClientList",     getClientList);
    Themis::ListenerThread::instance().addFunction("runCommand",        runCommand);
    Themis::ListenerThread::instance().addFunction("runCommandAll",     runCommandAll);
    Themis::ListenerThread::instance().addFunction("runCommandTag",     runCommandTag);
    Themis::ListenerThread::instance().addFunction("scpUpload",         scpUpload);
    Themis::ListenerThread::instance().addFunction("scpDownload",       scpDownload);
    Themis::ListenerThread::instance().addFunction("sendMessage",       sendMessage);
    Themis::ListenerThread::instance().addFunction("broadcastMessage",  broadcastMessage);
    Themis::ListenerThread::instance().addFunction("pushRules",         pushRules);
    Themis::ListenerThread::instance().addFunction("getStatus",         getStatus);
    Themis::ListenerThread::instance().addFunction("getRatConfig",      getRatConfig);
    Themis::ListenerThread::instance().addFunction("setRatConfig",      setRatConfig);
    Themis::ListenerThread::instance().enable();

    Themis::SenderThread::instance().setBus(&(Themis::dbus::instance()));
    Themis::SenderThread::instance().enable();

    std::cout << "[Themis] RAT plugin registered as org.themis.remote_access_tool\n";
    // ── End Themis registration ───────────────────────────────────────────────

    controller.printHelp();

    // Reset terminal after all SSH background operations have finished
    {
        struct termios t;
        if (tcgetattr(STDIN_FILENO, &t) == 0) {
            t.c_lflag |= ICANON | ECHO | ISIG;
            t.c_iflag |= ICRNL;
            t.c_iflag &= ~(IXON | IXOFF);
            t.c_cc[VINTR] = 3;
            t.c_cc[VERASE] = '\b';
            t.c_cc[VKILL]  = '\21';
            t.c_cc[VEOF]   = 4;
            tcsetattr(STDIN_FILENO, TCSANOW, &t);
        }
        tcflush(STDIN_FILENO, TCIFLUSH);
    }

    std::string inputBuf;
    char ch;

    while (!g_shutdownRequested) {
        std::cout << "\n> " << std::flush;
        inputBuf.clear();

        while (!g_shutdownRequested) {
            fd_set fds;
            FD_ZERO(&fds);
            FD_SET(STDIN_FILENO, &fds);
            if (g_pipe[0] != -1)
                FD_SET(g_pipe[0], &fds);
            int maxFd = std::max(STDIN_FILENO, g_pipe[0]) + 1;
            int ret = select(maxFd, &fds, nullptr, nullptr, nullptr);

            if (g_shutdownRequested) goto done;
            if (ret < 0) {
                if (errno == EINTR) continue;
                goto done;
            }
            if (g_pipe[0] != -1 && FD_ISSET(g_pipe[0], &fds)) goto done;
            if (!FD_ISSET(STDIN_FILENO, &fds)) continue;

            ssize_t n = read(STDIN_FILENO, &ch, 1);
            if (n < 0) {
                if (errno == EINTR) continue;
                goto done;
            }
            if (n == 0) {
                std::cout << "\nEOF\n";
                goto done;
            }
            if (ch == '\n' || ch == '\r') break;
            inputBuf += ch;
        }

        if (g_shutdownRequested) break;

        std::string line = controller.trim(inputBuf);
        if (line.empty()) continue;
        if (line == "quit" || line == "exit") break;
        if (line == "help" || line == "?")  { controller.printHelp(); continue; }
        if (line == "rules-help")           { controller.printRulesHelp(); continue; }
        controller.parseAndExecute(line);
    }
    done:

    std::cout << "\nShutting down...\n";
    if (ShellManager::isTerminalSaved()) {
        struct termios orig = ShellManager::getOriginalTerminalSettings();
        tcsetattr(STDIN_FILENO, TCSANOW, &orig);
    }
    controller.stopTCPServer();
    SSHManager::getInstance().killAllSessions();
    g_lockManager = nullptr;
    lockManager.releaseLock();
    if (g_pipe[0] != -1) close(g_pipe[0]);
    if (g_pipe[1] != -1) close(g_pipe[1]);
    std::cout << "Shutdown complete.\n";
    _exit (0);
}