#include "apache_functions.hh"

#include <algorithm>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

using json = nlohmann::json;
namespace fs = std::filesystem;

namespace
{
const std::string PLUGIN_ID = "apache";
const std::string PLUGIN_BUS = "org.themis.ApachePlugin";
const std::string THEMIS_BUS = "org.themis.ProjectThemis";
const fs::path PLUGIN_ROOT = "/etc/themis/plugins/apache";

const fs::path APACHE_ROOT = "/etc/apache2";
const fs::path APACHE_MAIN_CONF = APACHE_ROOT / "apache2.conf";
const fs::path APACHE_PORTS_CONF = APACHE_ROOT / "ports.conf";
const fs::path APACHE_SITES_AVAILABLE = APACHE_ROOT / "sites-available";
const fs::path APACHE_SITES_ENABLED = APACHE_ROOT / "sites-enabled";
const fs::path APACHE_MODS_AVAILABLE = APACHE_ROOT / "mods-available";
const fs::path APACHE_MODS_ENABLED = APACHE_ROOT / "mods-enabled";
const fs::path APACHE_CONF_AVAILABLE = APACHE_ROOT / "conf-available";
const fs::path APACHE_CONF_ENABLED = APACHE_ROOT / "conf-enabled";

enum class ApacheConfigKind { Hub, Main, Ports, Site, Mod, Conf, Unknown };

struct ApacheConfigTarget {
	ApacheConfigKind kind = ApacheConfigKind::Unknown;
	std::string configId;
	std::string configType;
	std::string title;
	std::string fileName;
	fs::path availablePath;
	fs::path enabledPath;
	bool hasEnable = false;
	bool protectedFile = false;
};

struct ApacheEntry {
	std::string kind;
	std::string name;
	std::string args;
	std::vector<ApacheEntry> children;
};

json get_json(const fs::path &path)
{
	std::ifstream ifs(path);
	if (!ifs.is_open()) {
		throw std::runtime_error("Failed to open JSON file: " +
					 path.string());
	}

	json j;
	ifs >> j;
	return j;
}

bool writeJsonFile(const fs::path &path, const json &j)
{
	const fs::path parent = path.parent_path();
	if (!parent.empty()) {
		fs::create_directories(parent);
	}

	std::ofstream out(path);
	if (!out.is_open()) {
		return false;
	}

	out << j.dump(JSON_DUMP_INDENT) << '\n';
	return out.good();
}

bool readTextFile(const fs::path &path, std::string &contents)
{
	std::ifstream in(path, std::ios::binary);
	if (!in.is_open()) {
		return false;
	}

	std::ostringstream buffer;
	buffer << in.rdbuf();
	contents = buffer.str();
	return true;
}

bool writeTextFile(const fs::path &path, const std::string &contents)
{
	const fs::path parent = path.parent_path();
	if (!parent.empty()) {
		fs::create_directories(parent);
	}

	std::ofstream out(path, std::ios::binary | std::ios::trunc);
	if (!out.is_open()) {
		return false;
	}

	out << contents;
	return out.good();
}

std::string trim(const std::string &value)
{
	const size_t start = value.find_first_not_of(" \t\r\n");
	if (start == std::string::npos) {
		return "";
	}

	const size_t end = value.find_last_not_of(" \t\r\n");
	return value.substr(start, end - start + 1);
}

bool startsWith(const std::string &value, const std::string &prefix)
{
	return value.size() >= prefix.size() &&
	       value.compare(0, prefix.size(), prefix) == 0;
}

bool isSafeFileName(const std::string &fileName,
		    const std::string &requiredExtension)
{
	if (fileName.empty() || fileName == "." || fileName == "..") {
		return false;
	}

	if (fileName.find('/') != std::string::npos ||
	    fileName.find('\\') != std::string::npos) {
		return false;
	}

	return fs::path(fileName).extension() == requiredExtension;
}

std::string ensureExtension(std::string fileName,
			    const std::string &extension)
{
	if (fs::path(fileName).extension() != extension) {
		fileName += extension;
	}
	return fileName;
}

std::string configIdFromPath(const std::string &dataPath)
{
	return fs::path(dataPath).stem().string();
}

bool pathExistsOrSymlink(const fs::path &path)
{
	std::error_code ec;
	return fs::exists(path, ec) || fs::is_symlink(path, ec);
}

bool removeIfPresent(const fs::path &path)
{
	std::error_code ec;
	if (pathExistsOrSymlink(path)) {
		fs::remove(path, ec);
	}
	return !ec;
}

bool createEnabledSymlink(const fs::path &source, const fs::path &linkPath)
{
	if (!fs::exists(source)) {
		return false;
	}

	std::error_code ec;
	fs::create_directories(linkPath.parent_path(), ec);
	if (ec) {
		return false;
	}

	if (!removeIfPresent(linkPath)) {
		return false;
	}

	fs::create_symlink(source, linkPath, ec);
	return !ec;
}

ApacheConfigTarget targetFromConfigId(const std::string &configId)
{
	ApacheConfigTarget target;
	target.configId = configId;

	if (configId == "apacheHub") {
		target.kind = ApacheConfigKind::Hub;
		target.configType = "apacheHub";
		target.title = "Apache Configuration";
		target.protectedFile = true;
		return target;
	}

	if (configId == "apache2.conf") {
		target.kind = ApacheConfigKind::Main;
		target.configType = "apacheMain";
		target.title = "apache2.conf";
		target.fileName = "apache2.conf";
		target.availablePath = APACHE_MAIN_CONF;
		target.protectedFile = true;
		return target;
	}

	if (configId == "ports.conf") {
		target.kind = ApacheConfigKind::Ports;
		target.configType = "apachePorts";
		target.title = "ports.conf";
		target.fileName = "ports.conf";
		target.availablePath = APACHE_PORTS_CONF;
		target.protectedFile = true;
		return target;
	}

	const size_t atPos = configId.find('@');
	if (atPos == std::string::npos) {
		return target;
	}

	const std::string prefix = configId.substr(0, atPos);
	const std::string fileName = configId.substr(atPos + 1);

	if (prefix == "site" && isSafeFileName(fileName, ".conf")) {
		target.kind = ApacheConfigKind::Site;
		target.configType = "apacheSites";
		target.title = fileName;
		target.fileName = fileName;
		target.availablePath = APACHE_SITES_AVAILABLE / fileName;
		target.enabledPath = APACHE_SITES_ENABLED / fileName;
		target.hasEnable = true;
		return target;
	}

	if (prefix == "mod" && isSafeFileName(fileName, ".load")) {
		target.kind = ApacheConfigKind::Mod;
		target.configType = "apacheMods";
		target.title = fileName;
		target.fileName = fileName;
		target.availablePath = APACHE_MODS_AVAILABLE / fileName;
		target.enabledPath = APACHE_MODS_ENABLED / fileName;
		target.hasEnable = true;
		return target;
	}

	if (prefix == "conf" && isSafeFileName(fileName, ".conf")) {
		target.kind = ApacheConfigKind::Conf;
		target.configType = "apacheConfigs";
		target.title = fileName;
		target.fileName = fileName;
		target.availablePath = APACHE_CONF_AVAILABLE / fileName;
		target.enabledPath = APACHE_CONF_ENABLED / fileName;
		target.hasEnable = true;
		return target;
	}

	return target;
}

std::string normalizeGeneratedConfigId(const std::string &configType,
				       const std::string &requestedId)
{
	if (configType == "apacheSites") {
		std::string fileName = startsWith(requestedId, "site@") ?
					       requestedId.substr(5) :
					       requestedId;
		return "site@" + ensureExtension(fileName, ".conf");
	}

	if (configType == "apacheMods") {
		std::string fileName = startsWith(requestedId, "mod@") ?
					       requestedId.substr(4) :
					       requestedId;
		return "mod@" + ensureExtension(fileName, ".load");
	}

	if (configType == "apacheConfigs") {
		std::string fileName = startsWith(requestedId, "conf@") ?
					       requestedId.substr(5) :
					       requestedId;
		return "conf@" + ensureExtension(fileName, ".conf");
	}

	return requestedId;
}

bool configIsEnabled(const ApacheConfigTarget &target)
{
	return target.hasEnable && pathExistsOrSymlink(target.enabledPath);
}

bool jsonValueToBool(const json &value)
{
	if (value.is_boolean()) {
		return value.get<bool>();
	}
	if (value.is_string()) {
		const std::string text = value.get<std::string>();
		return text == "true" || text == "yes" || text == "1";
	}
	return false;
}

json entryToJson(const ApacheEntry &entry)
{
	json result;
	result["kind"] = entry.kind;
	result["name"] = entry.name;
	result["args"] = entry.args;
	result["children"] = json::array();

	for (const ApacheEntry &child : entry.children) {
		result["children"].push_back(entryToJson(child));
	}

	return result;
}

ApacheEntry entryFromJson(const json &value)
{
	ApacheEntry entry;
	entry.kind = value.value("kind", "directive");
	entry.name = value.value("name", "");
	entry.args = value.value("args", "");

	if (value.contains("children") && value["children"].is_array()) {
		for (const json &child : value["children"]) {
			if (child.is_object()) {
				entry.children.push_back(entryFromJson(child));
			}
		}
	}

	if (!entry.children.empty()) {
		entry.kind = "container";
	}

	return entry;
}

std::vector<ApacheEntry> parseApacheEntries(const std::string &contents)
{
	std::istringstream input(contents);
	std::string line;
	std::vector<ApacheEntry> root;
	std::vector<ApacheEntry *> stack;

	auto currentChildren = [&]() -> std::vector<ApacheEntry> & {
		return stack.empty() ? root : stack.back()->children;
	};

	while (std::getline(input, line)) {
		line = trim(line);
		if (line.empty() || line[0] == '#') {
			continue;
		}

		if (startsWith(line, "</")) {
			if (!stack.empty()) {
				stack.pop_back();
			}
			continue;
		}

		if (line.front() == '<' && line.back() == '>') {
			std::string inside = trim(line.substr(1, line.size() - 2));
			if (inside.empty() || startsWith(inside, "!")) {
				continue;
			}

			std::istringstream parts(inside);
			ApacheEntry entry;
			entry.kind = "container";
			parts >> entry.name;
			std::getline(parts, entry.args);
			entry.args = trim(entry.args);

			std::vector<ApacheEntry> &children = currentChildren();
			children.push_back(entry);
			stack.push_back(&children.back());
			continue;
		}

		std::istringstream parts(line);
		ApacheEntry entry;
		entry.kind = "directive";
		parts >> entry.name;
		std::getline(parts, entry.args);
		entry.args = trim(entry.args);

		if (!entry.name.empty()) {
			currentChildren().push_back(entry);
		}
	}

	return root;
}

json entriesToJson(const std::vector<ApacheEntry> &entries)
{
	json result = json::array();
	for (const ApacheEntry &entry : entries) {
		result.push_back(entryToJson(entry));
	}
	return result;
}

void writeApacheEntries(const std::vector<ApacheEntry> &entries,
			std::ostream &out, int indent = 0)
{
	const std::string pad(static_cast<size_t>(indent), ' ');

	for (const ApacheEntry &entry : entries) {
		if (entry.name.empty()) {
			continue;
		}

		if (entry.kind == "container") {
			out << pad << "<" << entry.name;
			if (!entry.args.empty()) {
				out << " " << entry.args;
			}
			out << ">\n";
			writeApacheEntries(entry.children, out, indent + 4);
			out << pad << "</" << entry.name << ">\n";
			continue;
		}

		out << pad << entry.name;
		if (!entry.args.empty()) {
			out << " " << entry.args;
		}
		out << "\n";
	}
}

bool writeEntriesFile(const fs::path &path, const json &entries)
{
	if (!entries.is_array()) {
		return false;
	}

	std::vector<ApacheEntry> parsedEntries;
	for (const json &entry : entries) {
		if (entry.is_object()) {
			parsedEntries.push_back(entryFromJson(entry));
		}
	}

	const fs::path parent = path.parent_path();
	if (!parent.empty()) {
		fs::create_directories(parent);
	}

	std::ofstream out(path, std::ios::binary | std::ios::trunc);
	if (!out.is_open()) {
		return false;
	}

	writeApacheEntries(parsedEntries, out);
	return out.good();
}

fs::path moduleCompanionConf(const ApacheConfigTarget &target)
{
	return APACHE_MODS_AVAILABLE /
	       (fs::path(target.fileName).stem().string() + ".conf");
}

fs::path moduleCompanionEnabledConf(const ApacheConfigTarget &target)
{
	return APACHE_MODS_ENABLED /
	       (fs::path(target.fileName).stem().string() + ".conf");
}

bool setConfigEnabled(const ApacheConfigTarget &target, bool enabled)
{
	if (!target.hasEnable) {
		return true;
	}

	if (!enabled) {
		bool ok = removeIfPresent(target.enabledPath);
		if (target.kind == ApacheConfigKind::Mod) {
			ok = removeIfPresent(moduleCompanionEnabledConf(target)) &&
			     ok;
		}
		return ok;
	}

	bool ok = createEnabledSymlink(target.availablePath, target.enabledPath);
	if (target.kind == ApacheConfigKind::Mod &&
	    fs::exists(moduleCompanionConf(target))) {
		ok = createEnabledSymlink(moduleCompanionConf(target),
					  moduleCompanionEnabledConf(target)) &&
		     ok;
	}
	return ok;
}

json makeCred(const std::string &member)
{
	return { { "interface", "org.themis.GenericBus" },
		 { "bus", PLUGIN_BUS },
		 { "member", member } };
}

json makeReadyCred(const std::string &member)
{
	return { { "interface", "org.themis.GenericBus" },
		 { "bus", THEMIS_BUS },
		 { "member", member } };
}

void sendReadyMessage(const std::string &credKey, bool state)
{
	const fs::path dbusCredPath = PLUGIN_ROOT / "dbus_cred.json";
	json cred = get_json(dbusCredPath);
	json readyCred = cred[credKey];
	json response;
	response["plugin_id"] = PLUGIN_ID;
	response["state"] = state ? "true" : "false";
	Themis::SenderThread::instance().addMessage(
		response.dump(JSON_DUMP_INDENT), readyCred["interface"],
		readyCred["bus"], "default", readyCred["member"],
		Themis::OsFlag_t::NOFLAG);
}

void sendReadyMessage(const std::string &credKey)
{
	sendReadyMessage(credKey, true);
}

void addConfigMetadata(json &confType, json &dbusCred,
		       const ApacheConfigTarget &target)
{
	json confEntry;
	confEntry["pluginId"] = PLUGIN_ID;
	confEntry["configId"] = target.configId;
	confEntry["configType"] = target.configType;
	confEntry["title"] = target.title;
	confType.push_back(confEntry);

	dbusCred["getConfig"][target.configId] = makeCred("getApacheConfig");
	dbusCred["setConfig"][target.configId] = makeCred("setApacheConfig");
	dbusCred["removeConfig"][target.configId] =
		makeCred("removeApacheConfig");
}

void collectAvailableFiles(std::vector<ApacheConfigTarget> &configs,
			   const fs::path &directory,
			   const std::string &prefix,
			   const std::string &extension)
{
	if (!fs::exists(directory) || !fs::is_directory(directory)) {
		return;
	}

	std::vector<std::string> fileNames;
	for (const auto &entry : fs::directory_iterator(directory)) {
		if (!entry.is_regular_file()) {
			continue;
		}

		const fs::path path = entry.path();
		if (path.extension() == extension) {
			fileNames.push_back(path.filename().string());
		}
	}

	std::sort(fileNames.begin(), fileNames.end());
	for (const std::string &fileName : fileNames) {
		configs.push_back(targetFromConfigId(prefix + "@" + fileName));
	}
}

bool writeApacheServiceDetails(const std::vector<ApacheConfigTarget> &configs)
{
	const fs::path serviceDetailsPath =
		PLUGIN_ROOT.parent_path() / "service_details.json";
	json serviceDetails = json::object();

	try {
		if (fs::exists(serviceDetailsPath)) {
			serviceDetails = get_json(serviceDetailsPath);
			if (!serviceDetails.is_object()) {
				serviceDetails = json::object();
			}
		}
	} catch (const std::exception &) {
		serviceDetails = json::object();
	}

	serviceDetails[PLUGIN_ID] = "apache2";
	serviceDetails["apache2"] = "apache2";
	for (const ApacheConfigTarget &config : configs) {
		if (config.kind != ApacheConfigKind::Unknown) {
			serviceDetails[config.configId] = "apache2";
		}
	}

	return writeJsonFile(serviceDetailsPath, serviceDetails);
}
} // namespace

bool testApache(std::string input)
{
	(void)input;
	const bool ok = fs::exists(APACHE_ROOT) && fs::exists(APACHE_MAIN_CONF);
	sendReadyMessage("testReady", ok);
	return ok;
}

bool getApacheConfig(std::string outputPath)
{
	bool ok = false;

	try {
		const ApacheConfigTarget target =
			targetFromConfigId(configIdFromPath(outputPath));

		json config = json::object();
		if (target.kind == ApacheConfigKind::Hub) {
			ok = true;
		} else if (target.kind != ApacheConfigKind::Unknown) {
			std::string contents;
			ok = readTextFile(target.availablePath, contents);
			if (ok) {
				config["entries"] =
					entriesToJson(parseApacheEntries(contents));
				if (target.hasEnable) {
					config["enabled"] =
						configIsEnabled(target);
				}
			}
		}

		if (ok) {
			ok = writeJsonFile(outputPath, config);
		}
	} catch (const std::exception &) {
		ok = false;
	}

	sendReadyMessage("jsonGenerated", ok);
	return ok;
}

bool setApacheConfig(std::string inputPath)
{
	bool ok = false;

	try {
		const ApacheConfigTarget target =
			targetFromConfigId(configIdFromPath(inputPath));
		const json posted = get_json(inputPath);

		if (target.kind == ApacheConfigKind::Hub) {
			ok = true;
		} else if (target.kind != ApacheConfigKind::Unknown &&
			   posted.is_object()) {
			if (posted.contains("entries")) {
				ok = writeEntriesFile(target.availablePath,
						      posted["entries"]);
			} else if (posted.contains("contents") &&
			    posted["contents"].is_string()) {
				ok = writeTextFile(target.availablePath,
						   posted["contents"]
							   .get<std::string>());
			}

			if (ok && target.hasEnable &&
			    posted.contains("enabled")) {
				ok = setConfigEnabled(
					target,
					jsonValueToBool(posted["enabled"]));
			}
		}
	} catch (const std::exception &) {
		ok = false;
	}

	sendReadyMessage("confGenerated", ok);
	return ok;
}

bool removeApacheConfig(std::string inputPath)
{
	bool ok = false;

	try {
		const ApacheConfigTarget target =
			targetFromConfigId(configIdFromPath(inputPath));
		if (target.kind != ApacheConfigKind::Unknown &&
		    !target.protectedFile) {
			ok = setConfigEnabled(target, false);
			std::error_code ec;
			if (fs::exists(target.availablePath)) {
				fs::remove(target.availablePath, ec);
				ok = !ec && ok;
			}
			ok = reloadApacheMetadata("") && ok;
		}
	} catch (const std::exception &) {
		ok = false;
	}

	sendReadyMessage("confGenerated", ok);
	return ok;
}

bool generateApacheConfig(std::string inputPath)
{
	bool ok = false;

	try {
		const json body = get_json(inputPath);
		const std::string configType =
			body.value("configType", std::string());
		const std::string requestedId =
			body.value("configId", configIdFromPath(inputPath));
		const std::string configId =
			normalizeGeneratedConfigId(configType, requestedId);
		const ApacheConfigTarget target = targetFromConfigId(configId);

		if (target.kind != ApacheConfigKind::Unknown &&
		    !target.protectedFile && target.configType == configType) {
			if (body.contains("entries")) {
				ok = writeEntriesFile(target.availablePath,
						      body["entries"]);
			} else {
				const std::string contents =
					body.value("contents", std::string());
				ok = writeTextFile(target.availablePath,
						   contents);
			}

			if (ok && body.contains("enabled")) {
				ok = setConfigEnabled(
					target, jsonValueToBool(body["enabled"]));
			}

			ok = reloadApacheMetadata("") && ok;
		}
	} catch (const std::exception &) {
		ok = false;
	}

	sendReadyMessage("confGenerated", ok);
	return ok;
}

bool reloadApacheMetadata(std::string input)
{
	(void)input;

	try {
		fs::create_directories(PLUGIN_ROOT / "ui");

		json confType = json::array();
		json dbusCred = json::object();
		dbusCred["test"] = makeCred("testApache");
		dbusCred["getConfig"] = json::object();
		dbusCred["setConfig"] = json::object();
		dbusCred["removeConfig"] = json::object();
		dbusCred["generateConfig"] = json::object();
		dbusCred["jsonGenerated"] = makeReadyCred("jsonGenerated");
		dbusCred["confGenerated"] = makeReadyCred("confGenerated");
		dbusCred["ruleReady"] = makeReadyCred("ruleReady");
		dbusCred["testReady"] = makeReadyCred("testReady");

		for (const std::string configType :
		     { "apacheMain", "apachePorts", "apacheSites",
		       "apacheMods", "apacheConfigs" }) {
			dbusCred["generateConfig"][configType] =
				makeCred("generateApacheConfig");
		}

		std::vector<ApacheConfigTarget> configs;
		configs.push_back(targetFromConfigId("apacheHub"));
		configs.push_back(targetFromConfigId("apache2.conf"));
		configs.push_back(targetFromConfigId("ports.conf"));
		collectAvailableFiles(configs, APACHE_SITES_AVAILABLE, "site",
				      ".conf");
		collectAvailableFiles(configs, APACHE_MODS_AVAILABLE, "mod",
				      ".load");
		collectAvailableFiles(configs, APACHE_CONF_AVAILABLE, "conf",
				      ".conf");

		for (const ApacheConfigTarget &config : configs) {
			if (config.kind != ApacheConfigKind::Unknown) {
				addConfigMetadata(confType, dbusCred, config);
			}
		}

		if (!writeApacheServiceDetails(configs)) {
			return false;
		}

		if (!writeJsonFile(PLUGIN_ROOT / "conf_type.json", confType)) {
			return false;
		}
		if (!writeJsonFile(PLUGIN_ROOT / "dbus_cred.json", dbusCred)) {
			return false;
		}

		const fs::path uiPath = PLUGIN_ROOT / "ui/ui.json";
		if (!fs::exists(uiPath)) {
			std::cerr << "Apache static ui.json is missing at "
				  << uiPath << "\n";
		}

		return true;
	} catch (const std::exception &) {
		return false;
	}
}

void sendRuleReady()
{
	sendReadyMessage("ruleReady");
}
