#include <unistd.h>
#include <cstdlib>
#include <filesystem>
#include <string>
#include <dbus.hh>
#include "senderThread.hh"
#include "listenerThread.hh"
#include "apache_functions.hh"

#define SUCCESS 0
#define PING_FAILED 1
#define DOWNLOAD_FAILED 2

bool downloadFile(const std::string &url,
		  const std::filesystem::path &outputPath)
{
	std::filesystem::create_directories(outputPath.parent_path());

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
	const std::filesystem::path themisRoot = "/etc/themis";
	const std::filesystem::path rulesDir = themisRoot / "rules";
	const std::filesystem::path pluginDir = themisRoot / "plugins/apache";
	const std::filesystem::path uiDir = pluginDir / "ui";
	const std::filesystem::path dbusDir = "/usr/share/dbus-1/system.d";
	std::string baseUrl = CONTENTS_URL;
	const std::string pluginBaseUrl = baseUrl + "/apache";

	std::filesystem::create_directories(themisRoot);
	std::filesystem::create_directories(rulesDir);
	std::filesystem::create_directories(pluginDir);
	std::filesystem::create_directories(uiDir);
	std::filesystem::create_directories(dbusDir);

	if (std::system("curl -fsSL --connect-timeout 5 " BASE_URL
			"> /dev/null")) {
		return PING_FAILED;
	}

	if (!downloadFile(pluginBaseUrl + "/themis.apache.rule.csv",
			  rulesDir / "themis.apache.rule.csv")) {
		return DOWNLOAD_FAILED;
	}

	if (!downloadFile(pluginBaseUrl + "/org.themis.ApachePlugin.conf",
			  dbusDir / "org.themis.ApachePlugin.conf")) {
		return DOWNLOAD_FAILED;
	}

	if (!downloadFile(pluginBaseUrl + "/ui.json", uiDir / "ui.json")) {
		return DOWNLOAD_FAILED;
	}

	return SUCCESS;
}

void setDbus()
{
	std::string dbusName = "org.themis.ApachePlugin";
	Themis::dbus::instance().setName(dbusName);
	Themis::dbus::instance().connect();

	Themis::dbus::instance().loadRules(
		"/etc/themis/rules/themis.apache.rule.csv");

	Themis::dbus::instance().applyRules();
}

void enableThreads()
{
	Themis::ListenerThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::ListenerThread::instance().addFunction("testApache",
						       testApache);
	Themis::ListenerThread::instance().addFunction("getApacheConfig",
						       getApacheConfig);
	Themis::ListenerThread::instance().addFunction("setApacheConfig",
						       setApacheConfig);
	Themis::ListenerThread::instance().addFunction("removeApacheConfig",
						       removeApacheConfig);
	Themis::ListenerThread::instance().addFunction("generateApacheConfig",
						       generateApacheConfig);
	Themis::ListenerThread::instance().enable();

	Themis::SenderThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::SenderThread::instance().enable();
}

int main()
{
	printf("Apache STARTED!\n");
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
		printf("Apache plugin initialization failed, Error: %s\n",
		       error.c_str());
		return -1;
	}
	if (!reloadApacheMetadata("")) {
		printf("Apache plugin metadata generation failed.\n");
		return -1;
	}
	setDbus();
	enableThreads();
	sendRuleReady();
	while (1) {
		sleep(UINT32_MAX);
	}
	return 0; // Should not be reachable!
}
