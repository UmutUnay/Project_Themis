#include <unistd.h>
#include <dbus.hh>
#include "senderThread.hh"
#include "listenerThread.hh"
#include "functions.hh"

using json = nlohmann::json;
namespace fs = std::filesystem;

#define SUCCESS 0
#define PING_FAILED 1
#define DOWNLOAD_FAILED 2
#define ALREADY_INITIALIZED 3

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
	// Define the paths
	const fs::path themisRoot = "/etc/themis";
	const fs::path rulesDir = themisRoot / "rules";
	const fs::path pluginDir = themisRoot / "plugins/example";
	const fs::path uiDir = pluginDir / "ui";
	const fs::path dbusDir = "/usr/share/dbus-1/system.d";
	std::string baseUrl = CONTENTS_URL;
	const std::string pluginBaseUrl = baseUrl + "/example";

	fs::create_directories(themisRoot);
	fs::create_directories(rulesDir);
	fs::create_directories(pluginDir);
	fs::create_directories(uiDir);

	// Ping the server https://umutunay.github.io/projectthemis-info to check the internet connection.
	if (std::system("curl -fsSL --connect-timeout 5 " BASE_URL
			"> /dev/null")) {
		return PING_FAILED;
	}

	// Get the rule, then put it to /etc/themis/rules
	if (!downloadFile(pluginBaseUrl + "/themis.example.rule.csv",
			  rulesDir / "themis.example.rule.csv")) {
		return DOWNLOAD_FAILED;
	}

	// Get the template, then put it to /usr/share/dbus-1/system.d
	if (!downloadFile(pluginBaseUrl + "/org.themis.ExamplePlugin.conf",
			  dbusDir / "org.themis.ExamplePlugin.conf")) {
		return DOWNLOAD_FAILED;
	}

	// Get the ui, then put it to /etc/themis/plugins/example/ui
	if (!downloadFile(pluginBaseUrl + "/ui.json", uiDir / "ui.json")) {
		return DOWNLOAD_FAILED;
	}
	return SUCCESS;
}

void setDbus()
{
	std::string dbusName = "org.themis.ExamplePlugin";
	Themis::dbus::instance().setName(dbusName);
	Themis::dbus::instance().connect();

	// Loading rules from its path
	Themis::dbus::instance().loadRules(
		"/etc/themis/rules/themis.example.rule.csv");

	// Applying rules
	Themis::dbus::instance().applyRules();
}

void enableThreads()
{
	// Listener Thread Configuring and Enabling
	Themis::ListenerThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::ListenerThread::instance().addFunction("testExample",
						       testFunction);
	Themis::ListenerThread::instance().addFunction("getExampleConfig",
						       getExampleConfig);
	Themis::ListenerThread::instance().addFunction("setExampleConfig",
						       setExampleConfig);
	Themis::ListenerThread::instance().enable();

	// Sender Thread Configuring and Enabling
	Themis::SenderThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::SenderThread::instance().enable();
}

int main()
{
	printf("Example Plugin STARTED!\n");
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
		printf("Example plugin initialization failed, Error: %s\n",
		       error.c_str());
		return -1;
	}
	generateImportantFiles();
	setDbus();
	enableThreads();
	sendRuleReady();
	while (1) {
		sleep(UINT32_MAX);
	}
	return 0; // Should not be reachable!
}
