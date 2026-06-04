#ifndef C87FB7B1_6270_47C7_BA68_3330AFA95A99
#define C87FB7B1_6270_47C7_BA68_3330AFA95A99

#include <fstream>
#include <string>
#include <cctype>
#include <cstdio>
#include <dbus.hh>
#include "senderThread.hh"
#include <nlohmann/json.hpp>
#include <tinyxml2.h>

bool testFunction(std::string str);
bool getFirewalldConf(std::string outputPath);
bool setFirewalldConf(std::string inputPath);
bool getPermanentConf(std::string outputPath);
bool setPermanentConf(std::string inputPath);
bool getFallbackConf(std::string outputPath);
bool generatePermanentConf(std::string inputPath);
bool removePermanentConf(std::string inputPath);
bool xmlFileToJsonFile(const std::string &xmlPath, const std::string &jsonPath, bool flattenRoot = false);
bool jsonFileToXmlFile(const std::string &jsonPath, const std::string &xmlPath, const std::string &rootNameOverride = "");
bool reloadAllPermanentFiles(std::string input);
void sendRuleReady();

#endif // C87FB7B1_6270_47C7_BA68_3330AFA95A99
