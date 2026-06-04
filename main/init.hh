#ifndef A8A5353B_109F_44D8_B6EA_611D9E360BDA
#define A8A5353B_109F_44D8_B6EA_611D9E360BDA

#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <stdio.h>
#include <string>
#include <dbus.hh>
#include <stdexcept>
#include <filesystem>
#include "listenerThread.hh"
#include "senderThread.hh"
#include "HttpThread.hh"
#include "httpHandlers.hh"

namespace fs = std::filesystem;

void initDbus()
{
	std::string dbusName = "org.themis.ProjectThemis";
	Themis::dbus::instance().init(dbusName);

	const fs::path rulesDir{ "/etc/themis/rules" };

	// Create the directory tree if it does not exist.
	std::error_code ec;
	fs::create_directories(rulesDir, ec);
	if (ec) {
		printf("Failed to create rules directory '%s': %s\n",
		       rulesDir.c_str(), ec.message().c_str());
		return;
	}

	// Load every .csv file under /etc/themis/rules
	for (const auto &entry : fs::directory_iterator(rulesDir, ec)) {
		if (ec) {
			printf("Failed to iterate rules directory '%s': %s\n",
			       rulesDir.c_str(), ec.message().c_str());
			break;
		}
		if (!entry.is_regular_file()) {
			continue;
		}
		if (entry.path().extension() != ".csv") {
			continue;
		}
		Themis::dbus::instance().loadRules(entry.path());
	}
	Themis::dbus::instance().applyRules();
}

void initComm()
{
	// Listener init
	Themis::ListenerThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::ListenerThread::instance().addFunction("jsonGenerated",
						       jsonGeneratedHandler);
	Themis::ListenerThread::instance().addFunction("confGenerated",
						       confGeneratedHandler);
	Themis::ListenerThread::instance().addFunction("ruleReady",
						       ruleReadyHandler);
	Themis::ListenerThread::instance().addFunction("testReady",
						       testReadyHandler);
	Themis::ListenerThread::instance().enable();

	// Sender init
	Themis::SenderThread::instance().setBus(&(Themis::dbus::instance()));
	Themis::SenderThread::instance().enable();
}

void registerHttpAPI()
{
	Themis::HttpThread::instance().setIpv4(THEMIS_IPV4, THEMIS_PORT);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::OPTIONS, R"((?:/.*)?)", corsHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET, "/themis/plugins", getBriefHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET, "/themis/plugins/:plugin_id/ui",
		getUiHandler);
	//Themis::HttpThread::instance().registerUri(
	//	Themis::httpMethod_t::GET, "/themis/plugins/:plugin_id/ui/:ui_id",
	//	getUiHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::PUT, "/themis/plugins/:plugin_id/restart",
		restartPlugin);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET, "/themis/plugins/:plugin_id/test",
		testHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET, "/themis/plugins/:plugin_id/config",
		configTypeHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET,
		"/themis/plugins/:plugin_id/config/:conf_id", getConfigHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::POST,
		"/themis/plugins/:plugin_id/config/:conf_id", setConfigHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::DELETE,
		"/themis/plugins/:plugin_id/config/:conf_id",
		removeConfigHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::PUT,
		"/themis/plugins/:plugin_id/config/:conf_id",
		generateConfigHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::POST, "/themis/plugins/local_install",
		checkDownloadHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET, "/themis/plugins/:plugin_id/save",
		manuelSaveHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET,
		"/themis/plugins/:plugin_id/load_list", manuelLoadListHandler);
	Themis::HttpThread::instance().registerUri(
		Themis::httpMethod_t::GET,
		"/themis/plugins/:plugin_id/load/:backup_id",
		manuelLoadHandler);
	Themis::HttpThread::instance().enable();
}

void restorePlugins()
{
	std::string path = "/etc/themis/plugins/bin_name.csv";
	std::ifstream file(path);
	if (!file.is_open()) {
		printf("Binary name file open failed: %s\n", path.c_str());
		return;
	}
	std::string line;

	while (std::getline(file, line)) {
		if (line.empty() || line[0] == '#')
			continue;

		std::stringstream ss(line);

		std::string plugin_id;
		std::string binary_name;

		std::getline(ss, plugin_id, ',');
		std::getline(ss, binary_name, ',');

		plugins.push_back(std::make_pair(plugin_id, 0));
		generateSemaphore(plugin_id);
	}
	loadPlugins();
	return;
}

void startWebUi()
{
	pid_t pid = fork();
	if (pid == 0) { // Child
		execl("/bin/bash", "bash", "/etc/themis/gui/run_web",
		      (char *)nullptr);
	}
}

#endif // A8A5353B_109F_44D8_B6EA_611D9E360BDA
