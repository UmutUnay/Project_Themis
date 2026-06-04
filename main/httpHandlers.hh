#ifndef C77C0225_C79B_4762_AFFB_D2CCD131BC3F
#define C77C0225_C79B_4762_AFFB_D2CCD131BC3F

#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <utility>
#include <dbus.hh>
#include <unistd.h>
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <stdexcept>
#include <atomic>
#include <chrono>
#include <mutex>
#include <condition_variable>
#include "HttpThread.hh"
#include "helpers.hh"
#include <nlohmann/json.hpp>

using json = nlohmann::json;

// Semaphores
struct PluginSemaphore {
	std::mutex mtx;
	std::condition_variable cv;
	bool getReady = false;
	bool setReady = false;
	bool deleteReady = false;
	bool generateReady = false;
	bool generateOk = false;
	bool ruleReady = false;
	bool testReady = false;
};

std::unordered_map<std::string, std::shared_ptr<PluginSemaphore> > semaphores;
std::mutex semaphoresMapMutex;

void generateSemaphore(const std::string &plugin_id)
{
	std::lock_guard<std::mutex> lock(semaphoresMapMutex);

	if (semaphores.find(plugin_id) == semaphores.end()) {
		semaphores[plugin_id] = std::make_shared<PluginSemaphore>();
	}
}

std::shared_ptr<PluginSemaphore> getSemaphore(const std::string &plugin_id)
{
	std::lock_guard<std::mutex> lock(semaphoresMapMutex);

	auto it = semaphores.find(plugin_id);
	if (it == semaphores.end()) {
		auto sem = std::make_shared<PluginSemaphore>();
		semaphores[plugin_id] = sem;
		return sem;
	}

	return it->second;
}
// End of Semaphores

json get_json(const std::string &path)
{
	std::ifstream ifs(path);
	if (!ifs.is_open()) {
		throw std::runtime_error("Failed to open JSON file: " + path);
	}
	json j;
	ifs >> j;
	return j;
}

json get_json_no_except(const std::string &path)
{
	std::ifstream ifs(path);
	json j;
	if (!ifs.is_open()) {
		return j;
	}
	ifs >> j;
	return j;
}

void addCorsHeaders(const httplib::Request &req, httplib::Response &res)
{
	const auto origin = req.get_header_value("Origin");
	printf("Origin:%s\n", origin.c_str());

	if (!origin.empty()) {
		res.set_header("Access-Control-Allow-Origin", origin.c_str());
		res.set_header("Vary", "Origin");
	}

	res.set_header("Access-Control-Allow-Methods",
		       "GET, POST, OPTIONS, PUT, DELETE");
	res.set_header("Access-Control-Allow-Headers",
		       "Content-Type, Authorization");
	res.set_header("Access-Control-Max-Age", "86400");
	res.set_header("Access-Control-Allow-Credentials", "true");
}

void corsHandler(const httplib::Request &req, httplib::Response &res)
{
	addCorsHeaders(req, res);
	res.status = 204;
}

void getUiHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[getUiHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	//auto ui_id = req.path_params.at("ui_id");
	try {
		printf("Plugin id: %s\n", plugin_id.c_str());
		//std::string path = "/etc/themis/plugins/" + plugin_id + "/ui/" +
		//		   ui_id + ".json";
		std::string path =
			"/etc/themis/plugins/" + plugin_id + "/ui/ui.json";
		printf("Path: %s\n", path.c_str());
		json j = get_json(path);
		addCorsHeaders(req, res);
		res.set_content(j.dump(2), "application/json");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void getBriefHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[getBriefHandler] Message received.\n");
	try {
		json j = get_json("/etc/themis/plugins/brief.json");
		addCorsHeaders(req, res);
		res.set_content(j.dump(2), "application/json");
	} catch (const std::exception &e) {
		const fs::path briefPath = "/etc/themis/plugins/brief.json";
		fs::create_directories(briefPath.parent_path());
		json brief = json::array();
		std::ofstream ofs(briefPath);
		if (ofs.is_open()) {
			ofs << brief.dump(2) << '\n';
		}
		res.status = 200;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void configTypeHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[configTypeHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	try {
		std::string path =
			"/etc/themis/plugins/" + plugin_id + "/conf_type.json";
		json j = get_json(path);
		addCorsHeaders(req, res);
		res.set_content(j.dump(2), "application/json");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void restartPlugin(const httplib::Request &req, httplib::Response &res)
{
	printf("[restartPlugin] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	try {
		// Restart by finding the service file
		std::string path = "/etc/themis/plugins/service_details.json";
		json j = get_json(path);
		std::string service = j[plugin_id];
		std::string service_name = service + ".service";
		//std::string service_name = "firewalld.service";
		json message;
		message["args"] = { service_name, "replace" };
		printf("[restartPlugin]: %s\n", message.dump().c_str());
		Themis::SenderThread::instance().addMessage(
			message.dump(), "org.freedesktop.systemd1.Manager",
			"org.freedesktop.systemd1", "/org/freedesktop/systemd1",
			"RestartUnit", Themis::OsFlag_t::PARSE);
		addCorsHeaders(req, res);
		res.status = 200;
		res.set_content("OK\n", "text/plain"); // Default response
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void testHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[testHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	try {
		std::string dbusCredPath =
			"/etc/themis/plugins/" + plugin_id + "/dbus_cred.json";
		json cred = get_json(dbusCredPath);
		json getConfigCred = cred["test"];
		auto sem = getSemaphore(plugin_id);
		{
			std::lock_guard<std::mutex> lock(sem->mtx);
			sem->testReady = false;
		}
		Themis::SenderThread::instance().addMessage(
			"test", getConfigCred["interface"],
			getConfigCred["bus"], "default",
			getConfigCred["member"], Themis::OsFlag_t::NOFLAG);
		{
			std::unique_lock<std::mutex> lock(sem->mtx);
			bool ok = sem->cv.wait_for(
				lock, std::chrono::seconds(100),
				[sem]() { return sem->testReady; });

			if (!ok) {
				throw std::runtime_error(
					"Timed out waiting for test response");
			}
			sem->testReady = false;
		}
		addCorsHeaders(req, res);
		res.set_content("OK\n", "text/plain"); // Default response
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

bool confGeneratedHandler(std::string msg)
{
	json message = json::parse(msg);
	std::string plugin_id = message.at("plugin_id").get<std::string>();
	std::string state = message.at("state").get<std::string>();
	auto sem = getSemaphore(plugin_id);
	{
		std::lock_guard<std::mutex> lock(sem->mtx);
		sem->setReady = true;
		sem->deleteReady = true;
		sem->generateReady = true;
		sem->generateOk = state == "true";
		sem->cv.notify_all();
	}
	return state == "true" ? true : false;
}

bool jsonGeneratedHandler(std::string msg)
{
	printf("Message: %s\n", msg.c_str());
	json message = json::parse(msg);
	std::string plugin_id = message.at("plugin_id").get<std::string>();
	std::string state = message.at("state").get<std::string>();
	auto sem = getSemaphore(plugin_id);
	{
		std::lock_guard<std::mutex> lock(sem->mtx);
		sem->getReady = true;
		sem->generateReady = true;
		sem->generateOk = state == "true";
		sem->cv.notify_all();
	}
	return state == "true" ? true : false;
}

bool ruleReadyHandler(std::string msg)
{
	json message = json::parse(msg);
	std::string plugin_id = message.at("plugin_id").get<std::string>();
	std::string state = message.at("state").get<std::string>();
	auto sem = getSemaphore(plugin_id);
	{
		std::lock_guard<std::mutex> lock(sem->mtx);
		sem->ruleReady = true;
		sem->cv.notify_all();
	}
	return state == "true" ? true : false;
}

bool testReadyHandler(std::string msg)
{
	json message = json::parse(msg);
	std::string plugin_id = message.at("plugin_id").get<std::string>();
	std::string state = message.at("state").get<std::string>();
	auto sem = getSemaphore(plugin_id);
	{
		std::lock_guard<std::mutex> lock(sem->mtx);
		sem->testReady = true;
		sem->cv.notify_all();
	}
	return state == "true" ? true : false;
}

void getConfigHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[getConfigHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	auto conf_id = req.path_params.at("conf_id");
	std::string dataPath =
		"/etc/themis/plugins/" + plugin_id + "/" + conf_id + ".json";
	std::string dbusCredPath =
		"/etc/themis/plugins/" + plugin_id + "/dbus_cred.json";

	try {
		json data = get_json_no_except(dataPath);
		json cred = get_json(dbusCredPath);

		if (data.is_null()) { // We have to generate the file first
			printf("[getConfigHandler] No data found\n");
			json getConfigCred = cred["getConfig"][conf_id];

			auto sem = getSemaphore(plugin_id);
			{
				std::lock_guard<std::mutex> lock(sem->mtx);
				sem->getReady = false;
			}

			Themis::SenderThread::instance().addMessage(
				dataPath, getConfigCred["interface"],
				getConfigCred["bus"], "default",
				getConfigCred["member"],
				Themis::OsFlag_t::NOFLAG);

			{
				std::unique_lock<std::mutex> lock(sem->mtx);
				bool ok = sem->cv.wait_for(
					lock, std::chrono::seconds(100),
					[sem]() { return sem->getReady; });

				if (!ok) {
					throw std::runtime_error(
						"Timed out waiting for generated config");
				}
				sem->getReady = false;
			}
		}

		data = get_json(dataPath);

		addCorsHeaders(req, res);
		res.set_content(data.dump(2), "application/json");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void setConfigHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[setConfigHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	auto conf_id = req.path_params.at("conf_id");
	std::string dataPath =
		"/etc/themis/plugins/" + plugin_id + "/" + conf_id + ".json";
	std::string dbusCredPath =
		"/etc/themis/plugins/" + plugin_id + "/dbus_cred.json";
	std::ofstream out(dataPath, std::ios::binary | std::ios::trunc);
	if (!out.is_open()) {
		throw std::runtime_error("Failed to open file");
	}

	out.write(req.body.data(),
		  static_cast<std::streamsize>(req.body.size()));
	out.flush();

	if (!out.good()) {
		throw std::runtime_error("Write failed");
	}

	try {
		json cred = get_json(dbusCredPath);
		json setConfigCred = cred["setConfig"][conf_id];

		auto sem = getSemaphore(plugin_id);
		{
			std::lock_guard<std::mutex> lock(sem->mtx);
			sem->setReady = false;
		}

		Themis::SenderThread::instance().addMessage(
			dataPath, setConfigCred["interface"],
			setConfigCred["bus"], "default",
			setConfigCred["member"], Themis::OsFlag_t::NOFLAG);

		{
			std::unique_lock<std::mutex> lock(sem->mtx);
			bool ok = sem->cv.wait_for(
				lock, std::chrono::seconds(100),
				[sem]() { return sem->setReady; });

			if (!ok) {
				throw std::runtime_error(
					"Timed out waiting for generated config");
			}
			sem->setReady = false;
		}

		addCorsHeaders(req, res);
		res.set_content("OK\n", "text/plain");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void removeConfigHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[removeConfigHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	auto conf_id = req.path_params.at("conf_id");
	std::string dataPath =
		"/etc/themis/plugins/" + plugin_id + "/" + conf_id + ".json";
	std::string dbusCredPath =
		"/etc/themis/plugins/" + plugin_id + "/dbus_cred.json";

	try {
		json cred = get_json(dbusCredPath);
		json removeConfigCred = cred["removeConfig"][conf_id];

		auto sem = getSemaphore(plugin_id);
		{
			std::lock_guard<std::mutex> lock(sem->mtx);
			sem->deleteReady = false;
		}

		Themis::SenderThread::instance().addMessage(
			dataPath, removeConfigCred["interface"],
			removeConfigCred["bus"], "default",
			removeConfigCred["member"], Themis::OsFlag_t::NOFLAG);

		{
			std::unique_lock<std::mutex> lock(sem->mtx);
			bool ok = sem->cv.wait_for(
				lock, std::chrono::seconds(100),
				[sem]() { return sem->deleteReady; });

			if (!ok) {
				throw std::runtime_error(
					"Timed out waiting for removed config");
			}
			sem->deleteReady = false;
		}

		addCorsHeaders(req, res);
		res.set_content("OK\n", "text/plain");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void generateConfigHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[generateConfigHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	auto conf_id = req.path_params.at("conf_id");
	std::string dataPath =
		"/etc/themis/plugins/" + plugin_id + "/" + conf_id + ".json";
	std::string dbusCredPath =
		"/etc/themis/plugins/" + plugin_id + "/dbus_cred.json";

	try {
		json body = json::parse(req.body);
		const std::string configType =
			body.value("configType", std::string());
		if (configType.empty()) {
			throw std::runtime_error("missing configType");
		}

		std::ofstream out(dataPath, std::ios::binary | std::ios::trunc);
		if (!out.is_open()) {
			throw std::runtime_error("Failed to open file");
		}
		out << body.dump(2) << '\n';
		out.flush();
		if (!out.good()) {
			throw std::runtime_error("Write failed");
		}

		json cred = get_json(dbusCredPath);
		if (!cred.contains("generateConfig") ||
		    !cred["generateConfig"].is_object()) {
			throw std::runtime_error(
				"plugin has no generateConfig handlers");
		}

		json generateConfigCred;
		if (cred["generateConfig"].contains(configType)) {
			generateConfigCred = cred["generateConfig"][configType];
		} else {
			throw std::runtime_error(
				"no generateConfig handler for " + configType);
		}

		auto sem = getSemaphore(plugin_id);
		{
			std::lock_guard<std::mutex> lock(sem->mtx);
			sem->generateReady = false;
			sem->generateOk = false;
		}

		Themis::SenderThread::instance().addMessage(
			dataPath, generateConfigCred["interface"],
			generateConfigCred["bus"], "default",
			generateConfigCred["member"], Themis::OsFlag_t::NOFLAG);

		{
			std::unique_lock<std::mutex> lock(sem->mtx);
			bool ok = sem->cv.wait_for(
				lock, std::chrono::seconds(100),
				[sem]() { return sem->generateReady; });

			if (!ok) {
				throw std::runtime_error(
					"Timed out waiting for generated config");
			}
			if (!sem->generateOk) {
				throw std::runtime_error(
					"plugin failed to generate config");
			}
			sem->generateReady = false;
		}

		addCorsHeaders(req, res);
		res.set_content("OK\n", "text/plain");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void checkDownloadHandler(const httplib::Request &req, httplib::Response &res)
{
	json body;

	try {
		body = json::parse(req.body);
	} catch (...) {
		res.status = 400;
		addCorsHeaders(req, res);
		res.set_content(R"({"error":"invalid json body"})",
				"application/json");
		return;
	}

	if (!body.contains("path") || !body["path"].is_string()) {
		res.status = 400;
		addCorsHeaders(req, res);
		res.set_content(R"({"error":"missing path"})",
				"application/json");
		return;
	}

	const fs::path srcBinPath = body["path"].get<std::string>();

	if (!fs::exists(srcBinPath) || !fs::is_regular_file(srcBinPath)) {
		res.status = 404;
		addCorsHeaders(req, res);
		res.set_content(R"({"error":"binary path does not exist"})",
				"application/json");
		return;
	}

	const std::string binName = srcBinPath.filename().string();
	const std::string marker = "_Plugin_";
	const size_t markerPos = binName.find(marker);

	if (markerPos == std::string::npos) {
		res.status = 400;
		addCorsHeaders(req, res);
		res.set_content(R"({"error":"invalid binary name format"})",
				"application/json");
		return;
	}

	std::string pluginId = binName.substr(0, markerPos);

	std::transform(pluginId.begin(), pluginId.end(), pluginId.begin(),
		       [](unsigned char c) {
			       return static_cast<char>(std::tolower(c));
		       });

	const fs::path pluginDir = fs::path("/etc/themis/plugins") / pluginId;
	const fs::path dstBinPath = pluginDir / binName;

	std::error_code ec;

	fs::create_directories(pluginDir, ec);
	if (ec) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(
			R"({"error":"failed to create plugin directory"})",
			"application/json");
		return;
	}

	fs::rename(srcBinPath, dstBinPath, ec);
	if (ec) {
		ec.clear();

		fs::copy_file(srcBinPath, dstBinPath,
			      fs::copy_options::overwrite_existing, ec);
		if (ec) {
			res.status = 500;
			addCorsHeaders(req, res);
			res.set_content(
				R"({"error":"failed to move plugin binary"})",
				"application/json");
			return;
		}

		fs::remove(srcBinPath, ec);
	}

	fs::permissions(dstBinPath,
			fs::perms::owner_exec | fs::perms::group_exec |
				fs::perms::others_exec,
			fs::perm_options::add, ec);

	if (ec) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(
			R"({"error":"failed to make plugin executable"})",
			"application/json");
		return;
	}

	const fs::path pluginsRoot = "/etc/themis/plugins";
	const fs::path binCsvPath = pluginsRoot / "bin_name.csv";
	const fs::path serviceDetailsPath =
		pluginsRoot / "service_details.json";
	const fs::path briefPath = pluginsRoot / "brief.json";

	fs::create_directories(pluginsRoot, ec);
	if (ec) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(
			R"({"error":"failed to create plugins metadata directory"})",
			"application/json");
		return;
	}

	std::vector<std::string> binCsvLines;
	bool binEntryFound = false;
	{
		std::ifstream in(binCsvPath);
		std::string line;

		while (std::getline(in, line)) {
			const size_t commaPos = line.find(',');
			if (commaPos != std::string::npos &&
			    line.substr(0, commaPos) == pluginId) {
				binCsvLines.push_back(pluginId + "," + binName);
				binEntryFound = true;
			} else {
				binCsvLines.push_back(line);
			}
		}
	}

	if (binCsvLines.empty()) {
		binCsvLines.push_back("# plugin_id,binary_name");
	}

	if (!binEntryFound) {
		binCsvLines.push_back(pluginId + "," + binName);
	}

	{
		std::ofstream out(binCsvPath,
				  std::ios::binary | std::ios::trunc);
		if (!out.is_open()) {
			res.status = 500;
			addCorsHeaders(req, res);
			res.set_content(
				R"({"error":"failed to write binary metadata"})",
				"application/json");
			return;
		}

		for (const std::string &line : binCsvLines) {
			out << line << '\n';
		}
	}

	json serviceDetails = json::object();
	if (fs::exists(serviceDetailsPath)) {
		serviceDetails = get_json(serviceDetailsPath);
		if (!serviceDetails.is_object()) {
			serviceDetails = json::object();
		}
	}
	serviceDetails[pluginId] = pluginId;

	{
		std::ofstream out(serviceDetailsPath,
				  std::ios::binary | std::ios::trunc);
		if (!out.is_open()) {
			res.status = 500;
			addCorsHeaders(req, res);
			res.set_content(
				R"({"error":"failed to write service metadata"})",
				"application/json");
			return;
		}
		out << serviceDetails.dump(4) << '\n';
	}

	json brief = json::array();
	if (fs::exists(briefPath)) {
		brief = get_json(briefPath);
		if (!brief.is_array()) {
			brief = json::array();
		}
	}

	std::string pluginVersion = "unknown";
	const size_t versionPos = binName.rfind("_v");
	if (versionPos != std::string::npos) {
		pluginVersion = binName.substr(versionPos + 1);
	}

	json briefEntry;
	briefEntry["pluginId"] = pluginId;
	briefEntry["pluginVersion"] = pluginVersion;
	briefEntry["title"] = pluginId;
	briefEntry["subtitle"] = pluginId + " plugin";

	bool briefEntryFound = false;
	for (json &entry : brief) {
		if (entry.is_object() &&
		    entry.value("pluginId", "") == pluginId) {
			entry = briefEntry;
			briefEntryFound = true;
			break;
		}
	}

	if (!briefEntryFound) {
		brief.push_back(briefEntry);
	}

	{
		std::ofstream out(briefPath,
				  std::ios::binary | std::ios::trunc);
		if (!out.is_open()) {
			res.status = 500;
			addCorsHeaders(req, res);
			res.set_content(
				R"({"error":"failed to write plugin brief metadata"})",
				"application/json");
			return;
		}
		out << brief.dump(4) << '\n';
	}

	auto sem = getSemaphore(pluginId);
	{
		std::lock_guard<std::mutex> lock(sem->mtx);
		sem->ruleReady = false;
	}

	runPlugin(dstBinPath, binName);

	{
		std::unique_lock<std::mutex> lock(sem->mtx);
		bool ok = sem->cv.wait_for(lock, std::chrono::seconds(10000),
					   [sem]() { return sem->ruleReady; });

		if (!ok) {
			res.status = 504;
			addCorsHeaders(req, res);
			res.set_content(
				R"({"error":"timed out waiting for plugin ruleReady"})",
				"application/json");
			return;
		}
		sem->ruleReady = false;
	}

	std::string ruleName = "themis." + pluginId + ".rule.csv";
	std::string rulePath = "/etc/themis/rules/" + ruleName;
	Themis::dbus::instance().loadRules(rulePath);

	json out;
	out["success"] = true;
	out["plugin_id"] = pluginId;
	out["plugin_dir"] = pluginDir.string();
	out["bin_path"] = dstBinPath.string();

	res.status = 200;
	addCorsHeaders(req, res);
	res.set_content(out.dump(4), "application/json");
}

void manuelSaveHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[manuelSaveHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	try {
		std::string pluginPath = "/etc/themis/plugins/" + plugin_id;
		std::string backupPath = pluginPath + "/backup";
		fs::create_directories(backupPath);

		std::time_t now = std::time(nullptr);
		std::tm tm{};
		localtime_r(&now, &tm);
		char dateBuffer[32];
		std::strftime(dateBuffer, sizeof(dateBuffer), "%Y.%m.%d:%H.%M",
			      &tm);

		std::string backup_id = dateBuffer;
		std::string zipPath = backupPath + "/" + backup_id + ".zip";
		for (int i = 1; fs::exists(zipPath); i++) {
			backup_id = std::string(dateBuffer) + "_" +
				    std::to_string(i);
			zipPath = backupPath + "/" + backup_id + ".zip";
		}

		std::string dbusCredPath = pluginPath + "/dbus_cred.json";
		std::string confTypePath = pluginPath + "/conf_type.json";
		json cred = get_json(dbusCredPath);
		json confTypes = get_json(confTypePath);

		for (const json &confType : confTypes) {
			std::string conf_id = confType["configId"];
			std::string configType = confType["configType"];

			if (conf_id != "firewalld.conf" &&
			    configType.rfind("firewalldPermanent", 0) != 0) {
				continue;
			}

			std::string dataPath =
				pluginPath + "/" + conf_id + ".json";
			json getConfigCred = cred["getConfig"][conf_id];

			auto sem = getSemaphore(plugin_id);
			{
				std::lock_guard<std::mutex> lock(sem->mtx);
				sem->getReady = false;
			}

			Themis::SenderThread::instance().addMessage(
				dataPath, getConfigCred["interface"],
				getConfigCred["bus"], "default",
				getConfigCred["member"],
				Themis::OsFlag_t::NOFLAG);

			{
				std::unique_lock<std::mutex> lock(sem->mtx);
				bool ok = sem->cv.wait_for(
					lock, std::chrono::seconds(100),
					[sem]() { return sem->getReady; });

				if (!ok) {
					throw std::runtime_error(
						"Timed out waiting for backup config");
				}
				sem->getReady = false;
			}
		}

		std::string command = "cd '" + pluginPath + "' && zip -q '" +
				      zipPath + "' *.json";
		if (std::system(command.c_str()) != 0) {
			throw std::runtime_error(
				"Zip command failes, please make sure you have zip and unzip installed in your system");
		}
		res.status = 200;
		addCorsHeaders(req, res);
		res.set_content("OK\n", "text/plain");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void manuelLoadListHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[manuelLoadListHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	try {
		std::string backupPath =
			"/etc/themis/plugins/" + plugin_id + "/backup";
		json j = json::array();

		if (fs::exists(backupPath)) {
			for (const auto &entry :
			     fs::directory_iterator(backupPath)) {
				if (!entry.is_regular_file() ||
				    entry.path().extension() != ".zip") {
					continue;
				}

				json backup;
				backup["backup_id"] =
					entry.path().stem().string();
				backup["path"] = entry.path().string();
				j.push_back(backup);
			}
		}
		res.status = 200;
		addCorsHeaders(req, res);
		res.set_content(j.dump(2), "application/json");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

void manuelLoadHandler(const httplib::Request &req, httplib::Response &res)
{
	printf("[manuelLoadHandler] Message received.\n");
	auto plugin_id = req.path_params.at("plugin_id");
	auto backup_id = req.path_params.at("backup_id");
	try {
		std::string pluginPath = "/etc/themis/plugins/" + plugin_id;
		std::string backupPath = pluginPath + "/backup";
		std::string zipName = backup_id;
		if (zipName.size() < 4 ||
		    zipName.substr(zipName.size() - 4) != ".zip") {
			zipName += ".zip";
		}
		std::string zipPath = backupPath + "/" + zipName;

		if (!fs::exists(zipPath)) {
			res.status = 404;
			addCorsHeaders(req, res);
			res.set_content(R"({"error":"backup not found"})",
					"application/json");
			return;
		}

		std::string command = "cd '" + pluginPath +
				      "' && unzip -o -q '" + zipPath + "'";
		if (std::system(command.c_str()) != 0) {
			throw std::runtime_error(
				"Unzip command failes, please make sure you have zip and unzip installed in your system");
		}

		std::string dbusCredPath = pluginPath + "/dbus_cred.json";
		json cred = get_json(dbusCredPath);

		// Save each file
		for (const auto &entry : fs::directory_iterator(pluginPath)) {
			if (!entry.is_regular_file() ||
			    entry.path().extension() != ".json") {
				continue;
			}

			std::string fileName = entry.path().filename().string();
			if (fileName == "dbus_cred.json" ||
			    fileName == "conf_type.json") {
				continue;
			}

			std::string conf_id = entry.path().stem().string();
			json setConfigCred = cred["setConfig"][conf_id];
			std::string dataPath = entry.path().string();

			auto sem = getSemaphore(plugin_id);
			{
				std::lock_guard<std::mutex> lock(sem->mtx);
				sem->setReady = false;
			}

			Themis::SenderThread::instance().addMessage(
				dataPath, setConfigCred["interface"],
				setConfigCred["bus"], "default",
				setConfigCred["member"],
				Themis::OsFlag_t::NOFLAG);

			{
				std::unique_lock<std::mutex> lock(sem->mtx);
				bool ok = sem->cv.wait_for(
					lock, std::chrono::seconds(100),
					[sem]() { return sem->setReady; });

				if (!ok) {
					throw std::runtime_error(
						"Timed out waiting for restored config");
				}
				sem->setReady = false;
			}
		}

		res.status = 200;
		addCorsHeaders(req, res);
		res.set_content("OK\n", "text/plain");
	} catch (const std::exception &e) {
		res.status = 500;
		addCorsHeaders(req, res);
		res.set_content(std::string("{\"error\":\"") + e.what() + "\"}",
				"application/json");
	}
}

#endif // C77C0225_C79B_4762_AFFB_D2CCD131BC3F
