#ifndef BFB35364_F99F_4A34_86CC_F20799D9A765
#define BFB35364_F99F_4A34_86CC_F20799D9A765

#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <stdio.h>
#include <string>
#include <vector>
#include <stdexcept>
#include <filesystem>

namespace fs = std::filesystem;

static std::vector<std::pair<std::string, pid_t> > plugins;

bool isPluginLoaded(std::string name)
{
	for (std::pair<std::string, pid_t> element : plugins) {
		if (name == element.first) {
			return true;
		}
	}
	return false;
}

pid_t runPlugin(std::string path, std::string bin)
{
	pid_t pid = fork();
	if (pid == 0) { // Child
		execl(path.c_str(), bin.c_str(), (char *)nullptr);
	}
	return pid;
}

std::string getBinaryName(std::string plugin_id)
{
	std::string path = "/etc/themis/plugins/bin_name.csv";
	std::ifstream file(path);
	if (!file.is_open()) {
		printf("Binary name file open failed: %s\n", path.c_str());
		return "";
	}
	std::string line;

	while (std::getline(file, line)) {
		if (line.empty() || line[0] == '#')
			continue;

		std::stringstream ss(line);

		std::string plugin_name;
		std::string binary_name;

		std::getline(ss, plugin_name, ',');
		std::getline(ss, binary_name, ',');

		if (plugin_name == plugin_id) {
			return binary_name;
		}
	}
	return "";
}

void loadPlugins()
{
	for (size_t i = 0; i < plugins.size(); i++) {
		std::pair<std::string, pid_t> element = plugins[i];
		std::string plugin_id = element.first;
		pid_t pid = element.second;
		if (pid == 0) {
			std::string bin = getBinaryName(plugin_id);
			std::string path =
				"/etc/themis/plugins/" + plugin_id + "/" + bin;
			runPlugin(path, bin);
		}
		printf("Plugin loaded: %s, %d\n", plugin_id.c_str(), pid);
	}
}

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

bool setUpWeb()
{
	const fs::path themisRoot = "/etc/themis";
	const fs::path guiDir = themisRoot / "gui";
	std::string baseUrl = CONTENTS_URL;
	const std::string guiBaseUrl = baseUrl + "/gui";

	fs::create_directories(themisRoot);
	fs::create_directories(guiDir);

	// Ping to check the site
	if (std::system("curl -fsSL --connect-timeout 5 " BASE_URL
			"> /dev/null")) {
		printf("Server is not active.\n");
		return false;
	}
	// Download the web.zip
	if (!downloadFile(guiBaseUrl + "/web.zip", guiDir / "web.zip")) {
		printf("Web.zip download failed.\n");
		return false;
	}
	// Download the web server
	if (!downloadFile(guiBaseUrl + "/run_web", guiDir / "run_web")) {
		printf("Run_web download failed.\n");
		return false;
	}

	return true;
}

bool initSelf()
{
	const fs::path themisRoot = "/etc/themis";
	const fs::path rulesDir = themisRoot / "rules";
	const fs::path pluginsDir = themisRoot / "plugins";
	const fs::path dbusDir = "/usr/share/dbus-1/system.d";
	std::string baseUrl = CONTENTS_URL;
	const std::string mainBaseUrl = baseUrl + "/main";

	fs::create_directories(themisRoot);
	fs::create_directories(rulesDir);
	fs::create_directories(pluginsDir);

	// Ping to check the site
	if (std::system("curl -fsSL --connect-timeout 5 " BASE_URL
			"> /dev/null")) {
		printf("Server is not active.\n");
		return false;
	}
	// Download the web.zip
	if (!downloadFile(mainBaseUrl + "/themis.main.rule.csv",
			  rulesDir / "themis.main.rule.csv")) {
		printf("themis.main.rule.csv download failed.\n");
		return false;
	}
	// Download the web server
	if (!downloadFile(mainBaseUrl + "/org.themis.ProjectThemis.conf",
			  dbusDir / "org.themis.ProjectThemis.conf")) {
		printf("org.themis.ProjectThemis.conf download failed.\n");
		return false;
	}

	return true;
}

#endif // BFB35364_F99F_4A34_86CC_F20799D9A765
