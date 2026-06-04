#include <unistd.h>
#include <cstdlib>
#include <filesystem>
#include <string>
#include <dbus.hh>
#include "senderThread.hh"
#include "listenerThread.hh"
#include "functions.hh"

namespace fs = std::filesystem;

#define SUCCESS 0
#define PING_FAILED 1
#define DOWNLOAD_FAILED 2

bool downloadFile(const std::string &url, const fs::path &outputPath)
{
	fs::create_directories(outputPath.parent_path());

	std::string cmd = "curl -fsSL --connect-timeout 10000 "
			  "\"" +
			  url +
			  "\" "
			  "-o \"" +
			  outputPath.string() + "\"";

	return std::system(cmd.c_str()) == 0;
}

int firstInit()
{
	const fs::path themisRoot = "/etc/themis";
	const fs::path rulesDir = themisRoot / "rules";
	const fs::path pluginDir = themisRoot / "plugins/firewalld";
	const fs::path uiDir = pluginDir / "ui";
	const fs::path dbusDir = "/usr/share/dbus-1/system.d";
	std::string baseUrl = CONTENTS_URL;
	const std::string pluginBaseUrl = baseUrl + "/firewalld";

	fs::create_directories(themisRoot);
	fs::create_directories(rulesDir);
	fs::create_directories(pluginDir);
	fs::create_directories(uiDir);
	fs::create_directories(dbusDir);

	if (std::system("curl -fsSL --connect-timeout 5 " BASE_URL
			"> /dev/null")) {
		return PING_FAILED;
	}

	if (!downloadFile(pluginBaseUrl + "/themis.firewalld.rule.csv",
			  rulesDir / "themis.firewalld.rule.csv")) {
		return DOWNLOAD_FAILED;
	}

	if (!downloadFile(pluginBaseUrl + "/org.themis.FirewalldPlugin.conf",
			  dbusDir / "org.themis.FirewalldPlugin.conf")) {
		return DOWNLOAD_FAILED;
	}

	if (!downloadFile(pluginBaseUrl + "/ui.json", uiDir / "ui.json")) {
		return DOWNLOAD_FAILED;
	}

	return SUCCESS;
}

void setDbus()
{
	std::string dbusName = "org.themis.FirewalldPlugin";
	Themis::dbus::instance().setName(dbusName);
	Themis::dbus::instance().connect();

	// Loading rules from its path
	Themis::dbus::instance().loadRules(
		"/etc/themis/rules/themis.firewalld.rule.csv");

	// Applying rules
	Themis::dbus::instance().applyRules();
}

void enableThreads()
{
	// Listener Thread Configuring and Enabling
	Themis::ListenerThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::ListenerThread::instance().addFunction("testFirewalld",
						       testFunction);
	Themis::ListenerThread::instance().addFunction("getFirewalldConf",
						       getFirewalldConf);
	Themis::ListenerThread::instance().addFunction("setFirewalldConf",
						       setFirewalldConf);
	Themis::ListenerThread::instance().addFunction("getPermanentConf",
						       getPermanentConf);
	Themis::ListenerThread::instance().addFunction("setPermanentConf",
						       setPermanentConf);
	Themis::ListenerThread::instance().addFunction("getFallbackConf",
						       getFallbackConf);
	Themis::ListenerThread::instance().addFunction("generatePermanentConf",
						       generatePermanentConf);
	Themis::ListenerThread::instance().addFunction("removePermanentConf",
						       removePermanentConf);
	Themis::ListenerThread::instance().enable();

	// Sender Thread Configuring and Enabling
	Themis::SenderThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::SenderThread::instance().enable();
}

int main()
{
	printf("Firewalld STARTED!\n");
	int err = firstInit();
	if (err != SUCCESS) {
		std::string error = "";
		switch (err) {
		case PING_FAILED:
			error = "Ping to the server failed.";
			break;
		case DOWNLOAD_FAILED:
			error = "Download failed.";
			break;
		default:
			error = "Unidentified error.";
			break;
		}
		printf("Firewalld plugin initialization failed, Error: %s\n",
		       error.c_str());
		return -1;
	}
	reloadAllPermanentFiles("");
	setDbus();
	enableThreads();
	sendRuleReady();
	while (1) {
		sleep(UINT32_MAX);
	}
	return 0; // Should not be reachable!
}
