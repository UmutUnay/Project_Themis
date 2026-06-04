#ifndef C9224F17_6AB1_4202_87FA_3F44E391AF64
#define C9224F17_6AB1_4202_87FA_3F44E391AF64

#include <fstream>
#include <string>
#include <cstdio>
#include <dbus.hh>
#include "listenerThread.hh"
#include "senderThread.hh"
#include <nlohmann/json.hpp>

void sendRuleReady();

bool testApache(std::string input);
bool getApacheConfig(std::string outputPath);
bool setApacheConfig(std::string inputPath);
bool removeApacheConfig(std::string inputPath);
bool generateApacheConfig(std::string inputPath);
bool reloadApacheMetadata(std::string input);

#endif // C9224F17_6AB1_4202_87FA_3F44E391AF64
