// rat_plugin/src/TCPHandler.cpp
#include "TCPHandler.hpp"
#include <iostream>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>
#include <vector>
#include <chrono>
#include <thread>

// Static port utilities
bool TCPHandler::isPortInUse(int port) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return false;
    
    int opt = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    
    bool inUse = (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0 && errno == EADDRINUSE);
    close(sock);
    return inUse;
}

bool TCPHandler::freePort(int port) {
    pid_t currentPid = getpid();
    
    char cmd[256];
    snprintf(cmd, sizeof(cmd), 
             "lsof -ti :%d 2>/dev/null | grep -v %d | xargs -r kill -9 2>/dev/null", 
             port, currentPid);
    system(cmd);
    
    snprintf(cmd, sizeof(cmd), 
             "fuser -k %d/tcp 2>/dev/null | grep -v %d | xargs -r kill -9 2>/dev/null", 
             port, currentPid);
    system(cmd);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    return !isPortInUse(port);
}

void TCPHandler::cleanupPort(int port) {
    if (isPortInUse(port)) {
        std::cout << "[TCPHandler] Port " << port << " is in use. Attempting to free it..." << std::endl;
        freePort(port);
    }
}

// Server mode constructor
TCPHandler::TCPHandler(int port, MessageCallback msgCb, ConnectionCallback connCb)
    : m_isServerMode(true)
    , m_serverPort(port)
    , m_serverFd(-1)
    , m_running(false)
    , m_connected(false)
    , m_messageCallback(msgCb)
    , m_connectionCallback(connCb) {
    
    std::cout << "[TCPHandler] Created in SERVER mode on port " << port << std::endl;
}

// Client mode constructor
TCPHandler::TCPHandler(const std::string& serverIp, int serverPort, 
                       const std::string& clientId,
                       MessageCallback msgCb, ConnectionCallback connCb)
    : m_isServerMode(false)
    , m_serverIp(serverIp)
    , m_serverPort(serverPort)
    , m_ownClientId(clientId)
    , m_clientFd(-1)
    , m_running(false)
    , m_connected(false)
    , m_messageCallback(msgCb)
    , m_connectionCallback(connCb) {
    
    std::cout << "[TCPHandler] Created in CLIENT mode for server " 
              << serverIp << ":" << serverPort << " as " << clientId << std::endl;
}

TCPHandler::~TCPHandler() {
    stop();
}

bool TCPHandler::start() {
    if (m_running) return true;
    
    m_running = true;
    
    if (m_isServerMode) {
        // ===== SERVER MODE =====
        cleanupPort(m_serverPort);
        
        // Create socket
        m_serverFd = socket(AF_INET, SOCK_STREAM, 0);
        if (m_serverFd < 0) {
            std::cerr << "[TCPHandler] Failed to create server socket: " << strerror(errno) << std::endl;
            m_running = false;
            return false;
        }
        
        // Set socket options
        int opt = 1;
        if (setsockopt(m_serverFd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
            std::cerr << "[TCPHandler] Failed to set socket options: " << strerror(errno) << std::endl;
            close(m_serverFd);
            m_running = false;
            return false;
        }
        
        // Bind
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;
        addr.sin_port = htons(m_serverPort);
        
        if (bind(m_serverFd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            std::cerr << "[TCPHandler] Failed to bind to port " << m_serverPort << ": " << strerror(errno) << std::endl;
            close(m_serverFd);
            m_running = false;
            return false;
        }
        
        // Listen
        if (listen(m_serverFd, 10) < 0) {
            std::cerr << "[TCPHandler] Failed to listen: " << strerror(errno) << std::endl;
            close(m_serverFd);
            m_running = false;
            return false;
        }
        
        // Set non-blocking
        int flags = fcntl(m_serverFd, F_GETFL, 0);
        fcntl(m_serverFd, F_SETFL, flags | O_NONBLOCK);
        
        // Start accept thread
        m_acceptThread = std::thread(&TCPHandler::serverAcceptThread, this);
        
        std::cout << "[TCPHandler] Server started on port " << m_serverPort << std::endl;
        
    } else {
        // ===== CLIENT MODE =====
        if (connectToServer()) {
            // Send identification immediately
            std::string idMsg = "ID:" + m_ownClientId + "\n";
            send(m_clientFd, idMsg.c_str(), idMsg.length(), MSG_NOSIGNAL);
            
            m_receiveThread = std::thread(&TCPHandler::clientReceiveThread, this);
            std::cout << "[TCPHandler] Client connected to " << m_serverIp << ":" << m_serverPort << std::endl;
            
            if (m_connectionCallback) {
                m_connectionCallback(m_ownClientId, true);
            }
        } else {
            std::cerr << "[TCPHandler] Failed to connect to server" << std::endl;
            m_running = false;
            return false;
        }
    }
    
    return true;
}

void TCPHandler::stop() {
    if (!m_running) return;
    
    std::cout << "[TCPHandler] Stopping..." << std::endl;
    m_running = false;
    
    if (m_isServerMode) {
        // ===== STOP SERVER MODE - AGGRESSIVE =====
        
        // 1. Close server socket immediately to stop accept()
        {
            std::lock_guard<std::mutex> lock(m_socketMutex);
            if (m_serverFd >= 0) {
                std::cout << "[TCPHandler] Closing server socket" << std::endl;
                shutdown(m_serverFd, SHUT_RDWR);
                close(m_serverFd);
                m_serverFd = -1;
            }
        }
        
        // 2. Close ALL client sockets immediately
        {
            std::lock_guard<std::mutex> lock(m_clientsMutex);
            std::cout << "[TCPHandler] Force closing " << m_clientsByFd.size() << " client connections" << std::endl;
            
            for (auto& pair : m_clientsByFd) {
                std::cout << "[TCPHandler] Closing socket for client: " << pair.second->clientId << std::endl;
                shutdown(pair.first, SHUT_RDWR);
                close(pair.first);
            }
            
            // Clear maps immediately
            m_clientsByFd.clear();
            m_clientsById.clear();
        }
        
        // 3. Don't wait for accept thread - detach it
        if (m_acceptThread.joinable()) {
            std::cout << "[TCPHandler] Detaching accept thread" << std::endl;
            m_acceptThread.detach();
        }
        
        // 4. Don't wait for client threads - detach them all
        std::cout << "[TCPHandler] Detaching " << m_clientThreads.size() << " client threads" << std::endl;
        for (auto& pair : m_clientThreads) {
            if (pair.second.joinable()) {
                pair.second.detach();
            }
        }
        m_clientThreads.clear();
        
    } else {
        // ===== STOP CLIENT MODE =====
        {
            std::lock_guard<std::mutex> lock(m_socketMutex);
            if (m_clientFd >= 0) {
                shutdown(m_clientFd, SHUT_RDWR);
                close(m_clientFd);
                m_clientFd = -1;
            }
        }
        m_connected = false;
        
        // Don't wait for receive thread
        if (m_receiveThread.joinable()) {
            m_receiveThread.detach();
        }
        
        if (m_connectionCallback) {
            m_connectionCallback(m_ownClientId, false);
        }
    }
    
    std::cout << "[TCPHandler] Stopped" << std::endl;
}

// ===== SERVER MODE METHODS =====

void TCPHandler::serverAcceptThread() {
    std::cout << "[TCPHandler] Accept thread started" << std::endl;
    
    // Set socket to non-blocking mode
    int flags = fcntl(m_serverFd, F_GETFL, 0);
    fcntl(m_serverFd, F_SETFL, flags | O_NONBLOCK);
    
    while (m_running) {
        struct sockaddr_in clientAddr;
        socklen_t addrLen = sizeof(clientAddr);
        
        int clientFd = accept(m_serverFd, (struct sockaddr*)&clientAddr, &addrLen);
        
        if (clientFd < 0) {
            if (errno != EAGAIN && errno != EWOULDBLOCK) {
                if (m_running) {  // Only log if we're still running
                    std::cerr << "[TCPHandler] Accept failed: " << strerror(errno) << std::endl;
                }
            }
            // Check m_running more frequently - shorter sleep
            for (int i = 0; i < 10 && m_running; i++) {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
            continue;
        }
        
        if (!m_running) {
            close(clientFd);
            break;
        }
        
        // Get client IP
        char ipStr[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(clientAddr.sin_addr), ipStr, INET_ADDRSTRLEN);
        int clientPort = ntohs(clientAddr.sin_port);
        
        std::cout << "[TCPHandler] New connection from " << ipStr << ":" << clientPort << std::endl;
        
        // Create connection object
        auto conn = std::make_shared<ClientConnection>();
        conn->socketFd = clientFd;
        conn->ipAddress = ipStr;
        conn->port = clientPort;
        conn->isAuthenticated = false;
        
        {
            std::lock_guard<std::mutex> lock(m_clientsMutex);
            m_clientsByFd[clientFd] = conn;
        }
        
        // Start client thread
        m_clientThreads[clientFd] = std::thread(&TCPHandler::serverClientThread, this, 
                                                clientFd, std::string(ipStr), clientPort);
    }
    
    std::cout << "[TCPHandler] Accept thread stopped" << std::endl;
}

void TCPHandler::serverClientThread(int clientFd, const std::string& ip, int port) {
    std::cout << "[TCPHandler] Client thread started for " << ip << ":" << port << std::endl;
    
    char buffer[4096];
    std::string leftover;
    
    while (m_running) {
        fd_set readfds;
        FD_ZERO(&readfds);
        FD_SET(clientFd, &readfds);
        
        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 100000;
        
        int activity = select(clientFd + 1, &readfds, NULL, NULL, &tv);
        
        if (!m_running) break;
        
        if (activity < 0) {
            if (errno != EINTR) {
                std::cerr << "[TCPHandler] Select error: " << strerror(errno) << std::endl;
            }
            continue;
        }
        
        if (activity == 0) continue;
        
        ssize_t bytesRead = recv(clientFd, buffer, sizeof(buffer) - 1, 0);
        
        if (bytesRead <= 0) {
            // Connection closed
            std::cout << "[TCPHandler] Client " << ip << ":" << port << " disconnected" << std::endl;
            break;
        }
        
        buffer[bytesRead] = '\0';
        
        // Process messages
        std::string data = leftover + std::string(buffer, bytesRead);
        size_t pos = 0;
        size_t newline;
        
        while ((newline = data.find('\n', pos)) != std::string::npos) {
            std::string message = data.substr(pos, newline - pos);
            
            if (!message.empty() && message.back() == '\r') {
                message.pop_back();
            }
            
            if (!message.empty()) {
                std::string clientId;
                {
                    std::lock_guard<std::mutex> lock(m_clientsMutex);
                    auto it = m_clientsByFd.find(clientFd);
                    if (it != m_clientsByFd.end()) {
                        auto conn = it->second;
                        
                        // If not authenticated, first message should be ID:<clientId>
                        if (!conn->isAuthenticated) {
                            if (message.find("ID:") == 0) {
                                clientId = message.substr(3);
                                
                                // VALIDATE CLIENT ID HERE
                                if (m_validationCallback && !m_validationCallback(clientId)) {
                                    std::cout << "[TCPHandler] Rejected unknown client: " << clientId << std::endl;
                                    std::string rejectMsg = "ERROR: Unknown client ID - not in configuration\n";
                                    send(clientFd, rejectMsg.c_str(), rejectMsg.length(), MSG_NOSIGNAL);
                                    shutdown(clientFd, SHUT_RDWR);
                                    close(clientFd);
                                    {
                                        std::lock_guard<std::mutex> lock(m_clientsMutex);
                                        m_clientsByFd.erase(clientFd);
                                    }
                                    std::cout << "[TCPHandler] Rejected client " << clientId << " disconnected" << std::endl;
                                    return;
                                }
                                
                                conn->clientId = clientId;
                                conn->isAuthenticated = true;
                                
                                // Map by ID as well
                                m_clientsById[clientId] = conn;
                                
                                std::cout << "[TCPHandler] Client authenticated as: " << clientId << std::endl;
                                
                                // Notify connection callback
                                if (m_connectionCallback) {
                                    m_connectionCallback(clientId, true);
                                }
                                
                                // Send welcome
                                std::string welcome = "Welcome " + clientId + "!\n";
                                send(clientFd, welcome.c_str(), welcome.length(), MSG_NOSIGNAL);
                            }
                        } else {
                            clientId = conn->clientId;
                        }
                    }
                }
                
                // Handle authenticated message
                if (!clientId.empty() && m_messageCallback) {
                    m_messageCallback(clientId, message);
                }
            }
            
            pos = newline + 1;
        }
        
        leftover = data.substr(pos);
    }
    
    // Clean up
    {
        std::lock_guard<std::mutex> lock(m_clientsMutex);
        auto it = m_clientsByFd.find(clientFd);
        if (it != m_clientsByFd.end()) {
            std::string clientId = it->second->clientId;
            if (!clientId.empty()) {
                m_clientsById.erase(clientId);
                if (m_connectionCallback) {
                    m_connectionCallback(clientId, false);
                }
            }
            m_clientsByFd.erase(it);
        }
    }
    
    close(clientFd);
    std::cout << "[TCPHandler] Client thread stopped for " << ip << ":" << port << std::endl;
}

void TCPHandler::disconnectClient(const std::string& clientId) {
    std::lock_guard<std::mutex> lock(m_clientsMutex);
    
    auto it = m_clientsById.find(clientId);
    if (it != m_clientsById.end()) {
        int fd = it->second->socketFd;
        
        std::cout << "[TCPHandler] Forcefully disconnecting unknown client: " << clientId << std::endl;
        
        // Send rejection message
        std::string rejectMsg = "ERROR: Unknown client ID - not in configuration. Goodbye.\n";
        send(fd, rejectMsg.c_str(), rejectMsg.length(), MSG_NOSIGNAL);
        
        // Shutdown immediately to prevent reconnections
        shutdown(fd, SHUT_RDWR);
        
        // Close socket
        close(fd);
        
        // Remove from all maps
        m_clientsByFd.erase(fd);
        m_clientsById.erase(it);
        
        // Also clean up the client thread if it exists
        auto threadIt = m_clientThreads.find(fd);
        if (threadIt != m_clientThreads.end()) {
            if (threadIt->second.joinable()) {
                threadIt->second.detach(); // Detach instead of join to avoid blocking
            }
            m_clientThreads.erase(threadIt);
        }
        
        std::cout << "[TCPHandler] Client " << clientId << " disconnected and cleaned up" << std::endl;
    }
}

bool TCPHandler::sendToClient(const std::string& clientId, const std::string& message) {
    if (!m_isServerMode) return false;
    
    std::lock_guard<std::mutex> lock(m_clientsMutex);
    
    auto it = m_clientsById.find(clientId);
    if (it != m_clientsById.end()) {
        std::string formatted = message + "\n";
        ssize_t sent = send(it->second->socketFd, formatted.c_str(), formatted.length(), MSG_NOSIGNAL);
        return (sent > 0);
    }
    
    return false;
}

void TCPHandler::broadcastToAll(const std::string& message) {
    if (!m_isServerMode) return;
    
    std::lock_guard<std::mutex> lock(m_clientsMutex);
    
    std::string formatted = message + "\n";
    for (auto& pair : m_clientsByFd) {
        send(pair.first, formatted.c_str(), formatted.length(), MSG_NOSIGNAL);
    }
}

std::vector<std::string> TCPHandler::getConnectedClients() const {
    std::lock_guard<std::mutex> lock(m_clientsMutex);
    
    std::vector<std::string> clients;
    for (auto& pair : m_clientsById) {
        clients.push_back(pair.first);
    }
    return clients;
}

bool TCPHandler::isClientConnected(const std::string& clientId) const {
    std::lock_guard<std::mutex> lock(m_clientsMutex);
    return m_clientsById.find(clientId) != m_clientsById.end();
}

void TCPHandler::removeClient(const std::string& clientId) {
    std::lock_guard<std::mutex> lock(m_clientsMutex);
    
    auto it = m_clientsById.find(clientId);
    if (it != m_clientsById.end()) {
        int fd = it->second->socketFd;
        m_clientsByFd.erase(fd);
        m_clientsById.erase(it);
        close(fd);
    }
}

void TCPHandler::removeClient(int socketFd) {
    std::lock_guard<std::mutex> lock(m_clientsMutex);
    
    auto it = m_clientsByFd.find(socketFd);
    if (it != m_clientsByFd.end()) {
        std::string clientId = it->second->clientId;
        if (!clientId.empty()) {
            m_clientsById.erase(clientId);
        }
        m_clientsByFd.erase(it);
        close(socketFd);
    }
}

// ===== CLIENT MODE METHODS =====

bool TCPHandler::connectToServer() {
    m_clientFd = socket(AF_INET, SOCK_STREAM, 0);
    if (m_clientFd < 0) {
        std::cerr << "[TCPHandler] Failed to create client socket: " << strerror(errno) << std::endl;
        return false;
    }
    
    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(m_serverPort);
    
    if (inet_pton(AF_INET, m_serverIp.c_str(), &serverAddr.sin_addr) <= 0) {
        std::cerr << "[TCPHandler] Invalid server IP: " << m_serverIp << std::endl;
        close(m_clientFd);
        return false;
    }
    
    if (::connect(m_clientFd, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        std::cerr << "[TCPHandler] Failed to connect to server: " << strerror(errno) << std::endl;
        close(m_clientFd);
        return false;
    }
    
    m_connected = true;
    return true;
}

void TCPHandler::clientReceiveThread() {
    std::cout << "[TCPHandler] Client receive thread started" << std::endl;
    
    char buffer[4096];
    std::string leftover;
    
    while (m_running && m_connected) {
        fd_set readfds;
        FD_ZERO(&readfds);
        FD_SET(m_clientFd, &readfds);
        
        struct timeval tv;
        tv.tv_sec = 1;
        tv.tv_usec = 0;
        
        int activity = select(m_clientFd + 1, &readfds, NULL, NULL, &tv);
        
        if (!m_running) break;
        
        if (activity < 0) {
            if (errno != EINTR) {
                std::cerr << "[TCPHandler] Select error: " << strerror(errno) << std::endl;
            }
            continue;
        }
        
        if (activity == 0) continue;
        
        ssize_t bytesRead = recv(m_clientFd, buffer, sizeof(buffer) - 1, 0);
        
        if (bytesRead <= 0) {
            std::cout << "[TCPHandler] Server disconnected" << std::endl;
            m_connected = false;
            if (m_connectionCallback) {
                m_connectionCallback(m_ownClientId, false);
            }
            break;
        }
        
        buffer[bytesRead] = '\0';
        
        // Process messages
        std::string data = leftover + std::string(buffer, bytesRead);
        size_t pos = 0;
        size_t newline;
        
        while ((newline = data.find('\n', pos)) != std::string::npos) {
            std::string message = data.substr(pos, newline - pos);
            
            if (!message.empty() && message.back() == '\r') {
                message.pop_back();
            }
            
            if (!message.empty() && m_messageCallback) {
                m_messageCallback(m_ownClientId, message);
            }
            
            pos = newline + 1;
        }
        
        leftover = data.substr(pos);
    }
    
    std::cout << "[TCPHandler] Client receive thread stopped" << std::endl;
}

bool TCPHandler::sendToServer(const std::string& message) {
    if (m_isServerMode) return false;
    
    std::lock_guard<std::mutex> lock(m_socketMutex);
    
    if (!m_connected || m_clientFd < 0) {
        return false;
    }
    
    std::string formatted = message + "\n";
    ssize_t sent = send(m_clientFd, formatted.c_str(), formatted.length(), MSG_NOSIGNAL);
    
    return (sent > 0);
}