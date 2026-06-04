#include "functions.hh"
#include <algorithm>
#include <filesystem>
#include <stdexcept>
#include <vector>

using json = nlohmann::json;
namespace fs = std::filesystem;
using xmlNode = tinyxml2::XMLNode;
using xmlEl = tinyxml2::XMLElement;
using xmlErr = tinyxml2::XMLError;
using xmlDoc = tinyxml2::XMLDocument;
using xmlAttr = tinyxml2::XMLAttribute;
#define XML_SUCCESS tinyxml2::XML_SUCCESS
#define XML_FAIL tinyxml2::XML_FAIL
#define SEQUENCE_CHAR '@'

enum permanent_t { FALLBACK = 0, USER_DEFINED = 1 };

namespace
{
const std::string PLUGIN_ID = "firewalld";
const std::string PLUGIN_BUS = "org.themis.FirewalldPlugin";
const std::string THEMIS_BUS = "org.themis.ProjectThemis";
const fs::path PLUGIN_ROOT = "/etc/themis/plugins/firewalld";
const std::string PERMANENT_CONFIG_PREFIX = "permanent@";
const std::string FALLBACK_CONFIG_PREFIX = "fallback@";

struct FirewalldConfigEntry {
	std::string configId;
	std::string relativeId;
	bool isFallback;
};

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

void sendReadyMessage(const std::string &credKey, bool state)
{
	const fs::path dbusCredPath = PLUGIN_ROOT / "dbus_cred.json";
	json cred = get_json(dbusCredPath.string());
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
} // namespace

std::string trim(const std::string &s)
{
	size_t start = 0;
	while (start < s.size() &&
	       std::isspace(static_cast<unsigned char>(s[start]))) {
		start++;
	}

	size_t end = s.size();
	while (end > start &&
	       std::isspace(static_cast<unsigned char>(s[end - 1]))) {
		end--;
	}

	return s.substr(start, end - start);
}

bool testFunction(std::string str)
{
	(void)str;
	printf("You hit the test function for firewalld plugin!\n");
	sendReadyMessage("testReady");
	return true;
}

bool getFirewalldConf(std::string outputPath)
{
	std::string inputPath =
		"/etc/firewalld/firewalld.conf"; // Will be changed to CONFIG_FIREWALLD_CONF later
	json j = json::object();
	std::ifstream file(inputPath);

	std::string line;
	if (file.is_open()) {
		while (std::getline(file, line)) {
			line = trim(line);

			if (line.empty() || line[0] == '#') {
				continue;
			}

			size_t eq = line.find('=');
			if (eq == std::string::npos) {
				continue;
			}

			std::string key = trim(line.substr(0, eq));
			std::string value = trim(line.substr(eq + 1));

			if (!key.empty()) {
				j[key] = value;
			}
		}
	}
	const fs::path outputParent = fs::path(outputPath).parent_path();
	if (!outputParent.empty()) {
		fs::create_directories(outputParent);
	}
	std::ofstream out(outputPath);
	if (!out.is_open()) {
		return false;
	}
	out << j.dump(JSON_DUMP_INDENT) << '\n';

	json response;
	response["plugin_id"] = PLUGIN_ID;
	response["state"] = "true";

	std::string newMessage = response.dump(JSON_DUMP_INDENT);
	std::string dest = THEMIS_BUS;
	Themis::SenderThread::instance().addMessage(
		newMessage, "org.themis.GenericBus", dest, "default",
		"jsonGenerated", Themis::OsFlag_t::NOFLAG);
	return true;
}

bool setFirewalldConf(std::string inputPath)
{
	std::string outputPath =
		"/etc/firewalld/firewalld.conf"; // Will be changed to CONFIG_FIREWALLD_CONF later

	nlohmann::json j;
	std::ifstream file(inputPath);

	if (!file.is_open()) {
		return false;
	}

	try {
		file >> j;
	} catch (...) {
		return false;
	}

	const fs::path outputParent = fs::path(outputPath).parent_path();
	if (!outputParent.empty()) {
		fs::create_directories(outputParent);
	}
	std::ofstream out(outputPath);
	if (!out.is_open()) {
		return false;
	}

	for (auto it = j.begin(); it != j.end(); ++it) {
		if (it.value().is_string()) {
			out << it.key() << "=" << it.value().get<std::string>()
			    << "\n";
		} else {
			out << it.key() << "=" << it.value() << "\n";
		}
	}

	json response;
	response["plugin_id"] = PLUGIN_ID;
	response["state"] = "true";

	std::string newMessage = response.dump(JSON_DUMP_INDENT);
	std::string dest = THEMIS_BUS;
	Themis::SenderThread::instance().addMessage(
		newMessage, "org.themis.GenericBus", dest, "default",
		"confGenerated", Themis::OsFlag_t::NOFLAG);

	return true;
}

std::string trimXmlText(const std::string &s)
{
	size_t start = 0;
	while (start < s.size() &&
	       std::isspace(static_cast<unsigned char>(s[start]))) {
		start++;
	}

	size_t end = s.size();
	while (end > start &&
	       std::isspace(static_cast<unsigned char>(s[end - 1]))) {
		end--;
	}

	return s.substr(start, end - start);
}

std::string jsonScalarToString(const json &value)
{
	if (value.is_string()) {
		return value.get<std::string>();
	}
	return value.dump();
}

bool isRepeatableXmlElement(const std::string &name)
{
	return name == "interface" || name == "source" || name == "service" ||
	       name == "port" || name == "protocol" || name == "source-port" ||
	       name == "forward-port" || name == "icmp-block" ||
	       name == "ingress-zone" || name == "egress-zone" ||
	       name == "entry" || name == "option" || name == "destination" ||
	       name == "module" || name == "include";
}

json xmlElementToJson(const xmlEl *elem)
{
	json result = json::object();

	// Attributes
	if (elem->FirstAttribute() != nullptr) {
		json attrs = json::object();
		for (const xmlAttr *attr = elem->FirstAttribute();
		     attr != nullptr; attr = attr->Next()) {
			attrs[attr->Name()] = attr->Value();
		}
		result["@attributes"] = attrs;
	}

	// Child elements and text
	bool hasChildElements = false;

	for (const xmlNode *node = elem->FirstChild(); node != nullptr;
	     node = node->NextSibling()) {
		if (const auto *childElem = node->ToElement()) {
			hasChildElements = true;
			std::string childName = childElem->Name();
			json childJson = xmlElementToJson(childElem);

			if (result.contains(childName)) {
				if (!result[childName].is_array()) {
					json oldValue = result[childName];
					result[childName] = json::array();
					result[childName].push_back(oldValue);
				}
				result[childName].push_back(childJson);
			} else if (isRepeatableXmlElement(childName)) {
				result[childName] = json::array({ childJson });
			} else {
				result[childName] = childJson;
			}
		} else if (const auto *textNode = node->ToText()) {
			std::string text = trimXmlText(
				textNode->Value() ? textNode->Value() : "");
			if (!text.empty()) {
				result["#text"] = text;
			}
		}
	}

	if (!hasChildElements && !result.contains("@attributes") &&
	    result.contains("#text") && result.size() == 1) {
		return result["#text"];
	}

	return result;
}

void jsonToXmlElement(xmlDoc &doc, xmlEl *element, const json &j)
{
	if (j.is_null()) {
		return;
	}

	if (j.is_primitive()) {
		const std::string text = jsonScalarToString(j);
		element->SetText(text.c_str());
		return;
	}

	if (j.is_array()) {
		/* Arrays should normally be handled by the parent key.
		 * If one somehow reaches here, serialize items as text-ish fallback.
		 */
		const std::string text = j.dump();
		element->SetText(text.c_str());
		return;
	}

	/* Attributes */
	auto attrIt = j.find("@attributes");
	if (attrIt != j.end() && attrIt->is_object()) {
		for (auto it = attrIt->begin(); it != attrIt->end(); ++it) {
			const std::string attrValue =
				jsonScalarToString(it.value());
			element->SetAttribute(it.key().c_str(),
					      attrValue.c_str());
		}
	}

	/* Text */
	auto textIt = j.find("#text");
	if (textIt != j.end() && textIt->is_primitive()) {
		const std::string text = jsonScalarToString(*textIt);
		element->SetText(text.c_str());
	}

	auto altTextIt = j.find("_text");
	if (altTextIt != j.end() && altTextIt->is_primitive()) {
		const std::string text = jsonScalarToString(*altTextIt);
		element->SetText(text.c_str());
	}

	/* Children */
	for (auto it = j.begin(); it != j.end(); ++it) {
		const std::string &key = it.key();
		const json &value = it.value();

		if (key == "@attributes" || key == "#text" || key == "_text") {
			continue;
		}

		if (value.is_array()) {
			for (const auto &item : value) {
				xmlEl *child = doc.NewElement(key.c_str());
				jsonToXmlElement(doc, child, item);
				element->InsertEndChild(child);
			}
		} else {
			xmlEl *child = doc.NewElement(key.c_str());
			jsonToXmlElement(doc, child, value);
			element->InsertEndChild(child);
		}
	}
}

bool xmlFileToJsonFile(const std::string &xmlPath, const std::string &jsonPath,
		       bool flattenRoot)
{
	xmlDoc doc;
	xmlErr err = doc.LoadFile(xmlPath.c_str());
	if (err != XML_SUCCESS) {
		return false;
	}

	const xmlEl *root = doc.RootElement();
	if (root == nullptr) { /* No permanent configuration yet */
		return false;
	}

	json out = json::object();
	if (flattenRoot) {
		out = xmlElementToJson(root);
		if (!out.is_object()) {
			out = json::object({ { "#text", out } });
		}
	} else {
		out[root->Name()] = xmlElementToJson(root);
	}

	std::ofstream ofs(jsonPath);
	if (!ofs.is_open()) {
		return false;
	}

	ofs << out.dump(JSON_DUMP_INDENT) << '\n';
	return true;
}

bool jsonFileToXmlFile(const std::string &jsonPath, const std::string &xmlPath,
		       const std::string &rootNameOverride)
{
	std::ifstream ifs(jsonPath);
	if (!ifs.is_open()) {
		return false;
	}

	json in;
	try {
		ifs >> in;
	} catch (...) {
		return false;
	}

	if (!in.is_object() || in.empty()) {
		return false;
	}

	std::string rootName;
	json rootJson;
	if (!rootNameOverride.empty()) {
		rootName = rootNameOverride;
		rootJson = in;
	} else {
		/* Expect one top-level root element */
		auto rootIt = in.begin();
		rootName = rootIt.key();
		rootJson = rootIt.value();
	}

	xmlDoc doc;

	xmlEl *root = doc.NewElement(rootName.c_str());
	if (root == nullptr) {
		return false;
	}

	doc.InsertEndChild(root);
	jsonToXmlElement(doc, root, rootJson);

	return doc.SaveFile(xmlPath.c_str()) == XML_SUCCESS;
}

std::string getXmlRootNameFromConfigId(std::string configId)
{
	if (configId.rfind(PERMANENT_CONFIG_PREFIX, 0) == 0) {
		configId.erase(0, PERMANENT_CONFIG_PREFIX.size());
	} else if (configId.rfind(FALLBACK_CONFIG_PREFIX, 0) == 0) {
		configId.erase(0, FALLBACK_CONFIG_PREFIX.size());
	}

	const size_t separator = configId.find(SEQUENCE_CHAR);
	const std::string topDir = separator == std::string::npos ?
					   configId :
					   configId.substr(0, separator);

	if (topDir == "zones") {
		return "zone";
	}
	if (topDir == "services") {
		return "service";
	}
	if (topDir == "policies") {
		return "policy";
	}
	if (topDir == "ipsets") {
		return "ipset";
	}
	if (topDir == "icmptypes") {
		return "icmptype";
	}
	if (topDir == "helpers") {
		return "helper";
	}

	return "";
}

bool getPermanentConfigInfoFromType(const std::string &configType,
				    std::string &directory,
				    std::string &rootName)
{
	if (configType == "firewalldPermanentZones") {
		directory = "zones";
		rootName = "zone";
	} else if (configType == "firewalldPermanentServices") {
		directory = "services";
		rootName = "service";
	} else if (configType == "firewalldPermanentPolicies") {
		directory = "policies";
		rootName = "policy";
	} else if (configType == "firewalldPermanentIpsets") {
		directory = "ipsets";
		rootName = "ipset";
	} else if (configType == "firewalldPermanentIcmptypes") {
		directory = "icmptypes";
		rootName = "icmptype";
	} else if (configType == "firewalldPermanentHelpers") {
		directory = "helpers";
		rootName = "helper";
	} else {
		return false;
	}

	return true;
}

bool isSafeConfigLeafName(const std::string &name)
{
	return !name.empty() && name.find('/') == std::string::npos &&
	       name.find('\\') == std::string::npos &&
	       name.find("..") == std::string::npos &&
	       name.find(SEQUENCE_CHAR) == std::string::npos;
}

bool getConfigPathFromId(std::string config_id, std::string &path,
			 permanent_t type = USER_DEFINED)
{
	std::string tmp = config_id;
	if (tmp.rfind(PERMANENT_CONFIG_PREFIX, 0) == 0) {
		tmp.erase(0, PERMANENT_CONFIG_PREFIX.size());
	} else if (tmp.rfind(FALLBACK_CONFIG_PREFIX, 0) == 0) {
		tmp.erase(0, FALLBACK_CONFIG_PREFIX.size());
	}
	std::replace(tmp.begin(), tmp.end(), SEQUENCE_CHAR, '/');
	tmp.append(".xml");
	if (type == FALLBACK) {
		path = "/usr/lib/firewalld/" + tmp;
		return true;
	}
	path = "/etc/firewalld/" + tmp;
	return true;
}

std::string getConfigIdFromOutputPath(const std::string &outputPath)
{
	size_t slashPos = outputPath.find_last_of('/');
	size_t start = (slashPos == std::string::npos) ? 0 : slashPos + 1;

	size_t jsonPos = outputPath.rfind(".json");
	if (jsonPos == std::string::npos || jsonPos < start) {
		return outputPath.substr(start);
	}

	return outputPath.substr(start, jsonPos - start);
}

bool generatePermanentConf(std::string inputPath)
{
	bool success = false;

	try {
		json body = get_json(inputPath);
		std::string configId = body.value("configId", std::string());
		const std::string configType =
			body.value("configType", std::string());
		std::string directory;
		std::string rootName;

		if (!getPermanentConfigInfoFromType(configType, directory,
						    rootName) ||
		    !isSafeConfigLeafName(configId)) {
			throw std::runtime_error("invalid firewalld config request");
		}

		const std::string canonicalConfigId =
			PERMANENT_CONFIG_PREFIX + directory + SEQUENCE_CHAR +
			configId;
		std::string xmlPathString;
		if (!getConfigPathFromId(canonicalConfigId, xmlPathString)) {
			throw std::runtime_error("invalid firewalld config id");
		}

		const fs::path xmlPath = xmlPathString;
		if (fs::exists(xmlPath)) {
			throw std::runtime_error("firewalld config already exists");
		}

		fs::create_directories(xmlPath.parent_path());

		xmlDoc doc;
		xmlEl *root = doc.NewElement(rootName.c_str());
		if (root == nullptr) {
			throw std::runtime_error("failed to create xml root");
		}
		doc.InsertEndChild(root);
		if (doc.SaveFile(xmlPath.string().c_str()) != XML_SUCCESS) {
			throw std::runtime_error("failed to save xml config");
		}

		const fs::path jsonPath =
			PLUGIN_ROOT / (canonicalConfigId + ".json");
		if (!xmlFileToJsonFile(xmlPath.string(), jsonPath.string(),
				       true)) {
			throw std::runtime_error("failed to cache json config");
		}

		if (!reloadAllPermanentFiles("")) {
			throw std::runtime_error("failed to refresh firewalld config metadata");
		}
		success = true;
	} catch (const std::exception &) {
		success = false;
	}

	sendReadyMessage("jsonGenerated", success);
	return success;
}

bool removePermanentConf(std::string inputPath)
{
	bool success = false;

	try {
		const std::string configId = getConfigIdFromOutputPath(inputPath);
		if (configId.rfind(PERMANENT_CONFIG_PREFIX, 0) != 0 ||
		    getXmlRootNameFromConfigId(configId).empty()) {
			throw std::runtime_error("invalid permanent firewalld config id");
		}

		std::string xmlPathString;
		if (!getConfigPathFromId(configId, xmlPathString)) {
			throw std::runtime_error("invalid permanent firewalld config path");
		}

		const fs::path xmlPath = xmlPathString;
		if (!fs::exists(xmlPath)) {
			throw std::runtime_error("permanent firewalld config does not exist");
		}

		std::error_code ec;
		if (!fs::remove(xmlPath, ec) || ec) {
			throw std::runtime_error("failed to remove permanent firewalld config");
		}

		const fs::path jsonPath = inputPath;
		if (fs::exists(jsonPath)) {
			fs::remove(jsonPath, ec);
			if (ec) {
				throw std::runtime_error("failed to remove cached firewalld config");
			}
		}

		reloadAllPermanentFiles("");
		success = true;
	} catch (const std::exception &) {
		success = false;
	}

	sendReadyMessage("confGenerated", success);
	return success;
}

bool getPermanentConf(std::string outputPath)
{
	std::string configId = getConfigIdFromOutputPath(outputPath);
	std::string path = "";
	json response;
	response["plugin_id"] = PLUGIN_ID;
	if (!getConfigPathFromId(configId, path)) {
		goto fail;
	}
	if (!xmlFileToJsonFile(path, outputPath, true)) {
		goto fail;
	}
	{
		response["state"] = "true";
		std::string newMessage = response.dump(JSON_DUMP_INDENT);
		std::string dest = THEMIS_BUS;
		Themis::SenderThread::instance().addMessage(
			newMessage, "org.themis.GenericBus", dest, "default",
			"jsonGenerated", Themis::OsFlag_t::NOFLAG);
		return true;
	}

fail:
	response["state"] = "false";
	std::string newMessage = response.dump(JSON_DUMP_INDENT);
	std::string dest = THEMIS_BUS;
	Themis::SenderThread::instance().addMessage(
		newMessage, "org.themis.GenericBus", dest, "default",
		"jsonGenerated", Themis::OsFlag_t::NOFLAG);

	return true;
}

bool getFallbackConf(std::string outputPath)
{
	std::string configId = getConfigIdFromOutputPath(outputPath);
	std::string path = "";
	json response;
	response["plugin_id"] = PLUGIN_ID;
	if (!getConfigPathFromId(configId, path, FALLBACK)) {
		goto fail;
	}
	if (!xmlFileToJsonFile(path, outputPath, true)) {
		goto fail;
	}
	{
		response["state"] = "true";
		std::string newMessage = response.dump(JSON_DUMP_INDENT);
		std::string dest = THEMIS_BUS;
		Themis::SenderThread::instance().addMessage(
			newMessage, "org.themis.GenericBus", dest, "default",
			"jsonGenerated", Themis::OsFlag_t::NOFLAG);
		return true;
	}
fail:
	response["state"] = "false";
	std::string newMessage = response.dump(JSON_DUMP_INDENT);
	std::string dest = THEMIS_BUS;
	Themis::SenderThread::instance().addMessage(
		newMessage, "org.themis.GenericBus", dest, "default",
		"jsonGenerated", Themis::OsFlag_t::NOFLAG);

	return true;
}

bool setPermanentConf(std::string inputPath)
{
	std::string configId = getConfigIdFromOutputPath(inputPath);
	std::string path = "";
	json response;
	response["plugin_id"] = PLUGIN_ID;
	if (!getConfigPathFromId(configId, path)) {
		goto fail;
	}
	if (!jsonFileToXmlFile(inputPath, path,
			       getXmlRootNameFromConfigId(configId))) {
		goto fail;
	}
	{
		response["state"] = "true";
		std::string newMessage = response.dump(JSON_DUMP_INDENT);
		std::string dest = THEMIS_BUS;
		Themis::SenderThread::instance().addMessage(
			newMessage, "org.themis.GenericBus", dest, "default",
			"confGenerated", Themis::OsFlag_t::NOFLAG);
		return true;
	}

fail:
	response["state"] = "false";
	std::string newMessage = response.dump(JSON_DUMP_INDENT);
	std::string dest = THEMIS_BUS;
	Themis::SenderThread::instance().addMessage(
		newMessage, "org.themis.GenericBus", dest, "default",
		"confGenerated", Themis::OsFlag_t::NOFLAG);
	return false;
}

void sendRuleReady()
{
	sendReadyMessage("ruleReady");
}

std::string makeTitleFromConfigId(const std::string &configId,
				  bool isFallback = false)
{
	if (configId == "firewalld.conf") {
		return "Firewalld Main Configuration";
	}

	std::string title = configId;
	if (title.rfind(PERMANENT_CONFIG_PREFIX, 0) == 0) {
		title.erase(0, PERMANENT_CONFIG_PREFIX.size());
	} else if (title.rfind(FALLBACK_CONFIG_PREFIX, 0) == 0) {
		title.erase(0, FALLBACK_CONFIG_PREFIX.size());
	}
	std::replace(title.begin(), title.end(), SEQUENCE_CHAR, '/');
	return std::string("Firewalld ") +
	       (isFallback ? "Fallback" : "Permanent") + " Config - " + title;
}

std::string makeConfigId(const fs::path &relativePath)
{
	std::string configId = relativePath.string();
	std::replace(configId.begin(), configId.end(), '/', SEQUENCE_CHAR);
	size_t dotPos = configId.find(".xml");
	if (dotPos != std::string::npos) {
		configId.erase(dotPos);
	}
	return configId;
}

bool isSupportedFirewalldConfigFile(const fs::path &relativePath)
{
	if (relativePath.empty()) {
		return false;
	}

	if (relativePath == fs::path("firewalld.conf")) {
		return true;
	}

	if (relativePath.extension() != ".xml") {
		return false;
	}

	auto it = relativePath.begin();
	if (it == relativePath.end()) {
		return false;
	}

	const std::string topDir = it->string();

	return topDir == "helpers" || topDir == "icmptypes" ||
	       topDir == "services" || topDir == "zones" ||
	       topDir == "policies" || topDir == "ipsets";
}

std::string makeConfigTypeFromPath(const fs::path &relativePath,
				   bool isFallback)
{
	if (relativePath == fs::path("firewalld.conf")) {
		return "firewalldMain";
	}

	auto it = relativePath.begin();
	if (it == relativePath.end()) {
		return isFallback ? "firewalldFallback" : "firewalldPermanent";
	}

	const std::string topDir = it->string();
	std::string suffix;
	if (topDir == "zones") {
		suffix = "Zones";
	} else if (topDir == "services") {
		suffix = "Services";
	} else if (topDir == "policies") {
		suffix = "Policies";
	} else if (topDir == "ipsets") {
		suffix = "Ipsets";
	} else if (topDir == "icmptypes") {
		suffix = "Icmptypes";
	} else if (topDir == "helpers") {
		suffix = "Helpers";
	}

	return std::string("firewalld") +
	       (isFallback ? "Fallback" : "Permanent") + suffix;
}

bool reloadAllPermanentFiles(std::string input)
{
	(void)input;

	const fs::path firewalldRoot = "/etc/firewalld";
	const fs::path firewalldFallbackRoot = "/usr/lib/firewalld";
	const fs::path pluginRoot = PLUGIN_ROOT;
	const fs::path dbusCredPath = pluginRoot / "dbus_cred.json";
	const fs::path confTypePath = pluginRoot / "conf_type.json";

	try {
		fs::create_directories(pluginRoot);

		json confType = json::array();
		json dbusCred;
		dbusCred["test"] = { { "interface", "org.themis.GenericBus" },
				     { "bus", PLUGIN_BUS },
				     { "member", "testFirewalld" } };
		dbusCred["getConfig"] = json::object();
		dbusCred["setConfig"] = json::object();
		dbusCred["removeConfig"] = json::object();
		dbusCred["generateConfig"] = json::object();
		for (const std::string configType :
		     { "firewalldPermanentZones",
		       "firewalldPermanentServices",
		       "firewalldPermanentPolicies",
		       "firewalldPermanentIpsets",
		       "firewalldPermanentIcmptypes",
		       "firewalldPermanentHelpers" }) {
			dbusCred["generateConfig"][configType] = {
				{ "interface", "org.themis.GenericBus" },
				{ "bus", PLUGIN_BUS },
				{ "member", "generatePermanentConf" }
			};
		}
		dbusCred["jsonGenerated"] = { { "interface",
						"org.themis.GenericBus" },
					      { "bus", THEMIS_BUS },
					      { "member", "jsonGenerated" } };
		dbusCred["confGenerated"] = { { "interface",
						"org.themis.GenericBus" },
					      { "bus", THEMIS_BUS },
					      { "member", "confGenerated" } };
		dbusCred["ruleReady"] = { { "interface",
					    "org.themis.GenericBus" },
					  { "bus", THEMIS_BUS },
					  { "member", "ruleReady" } };
		dbusCred["testReady"] = { { "interface",
					    "org.themis.GenericBus" },
					  { "bus", THEMIS_BUS },
					  { "member", "testReady" } };

		std::vector<FirewalldConfigEntry> configs;

		auto collectConfigs = [&](const fs::path &root,
					  bool isFallback) -> void {
			if (!fs::exists(root) || !fs::is_directory(root)) {
				return;
			}

			for (const auto &entry :
			     fs::recursive_directory_iterator(root)) {
				if (!entry.is_regular_file()) {
					continue;
				}

				const fs::path fullPath = entry.path();
				const fs::path relativePath =
					fs::relative(fullPath, root);

				if (!isSupportedFirewalldConfigFile(
					    relativePath)) {
					continue;
				}
				if (relativePath ==
				    fs::path("firewalld.conf")) {
					continue;
				}

				const std::string configId =
					(isFallback ? FALLBACK_CONFIG_PREFIX :
						      PERMANENT_CONFIG_PREFIX) +
					makeConfigId(relativePath);
				configs.push_back({ configId,
						    relativePath.string(),
						    isFallback });
			}
		};

		collectConfigs(firewalldRoot, false);
		collectConfigs(firewalldFallbackRoot, true);
		configs.push_back(
			{ "firewalld.conf", "firewalld.conf", false });

		for (const auto &config : configs) {
			json confEntry;
			confEntry["pluginId"] = PLUGIN_ID;
			confEntry["configId"] = config.configId;
			confEntry["configType"] =
				config.configId == "firewalld.conf" ?
					"firewalldMain" :
					makeConfigTypeFromPath(
						fs::path(config.relativeId),
						config.isFallback);
			confEntry["title"] = makeTitleFromConfigId(
				config.configId, config.isFallback);
			confType.push_back(confEntry);

			std::string getMember;
			std::string setMember;
			bool hasSetMember = true;

			if (config.configId == "firewalld.conf") {
				getMember = "getFirewalldConf";
				setMember = "setFirewalldConf";
			} else if (config.isFallback) {
				getMember = "getFallbackConf";
				hasSetMember = false;
			} else {
				getMember = "getPermanentConf";
				setMember = "setPermanentConf";
			}

			dbusCred["getConfig"][config.configId] = {
				{ "interface", "org.themis.GenericBus" },
				{ "bus", PLUGIN_BUS },
				{ "member", getMember }
			};

			if (hasSetMember) {
				dbusCred["setConfig"][config.configId] = {
					{ "interface",
					  "org.themis.GenericBus" },
					{ "bus", PLUGIN_BUS },
					{ "member", setMember }
				};
			}

			if (!config.isFallback &&
			    config.configId != "firewalld.conf") {
				dbusCred["removeConfig"][config.configId] = {
					{ "interface",
					  "org.themis.GenericBus" },
					{ "bus", PLUGIN_BUS },
					{ "member", "removePermanentConf" }
				};
			}
		}

		{
			std::ofstream confOut(confTypePath);
			if (!confOut.is_open()) {
				return false;
			}
			confOut << confType.dump(JSON_DUMP_INDENT) << '\n';
		}

		{
			std::ofstream dbusOut(dbusCredPath);
			if (!dbusOut.is_open()) {
				return false;
			}
			dbusOut << dbusCred.dump(JSON_DUMP_INDENT) << '\n';
		}

		return true;
	} catch (const std::exception &) {
		return false;
	}
}
