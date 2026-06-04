#include "functions.hh"
#include <cstdio>
#include <fstream>
#include <stdexcept>
#include <system_error>
#include <vector>
#include <nlohmann/json.hpp>
#include "senderThread.hh"

using json = nlohmann::json;
namespace fs = std::filesystem;

namespace
{
const std::string PLUGIN_ID = "example";
const std::string PLUGIN_BUS = "org.themis.ExamplePlugin";
const std::string THEMIS_BUS = "org.themis.ProjectThemis";
const fs::path PLUGIN_ROOT = "/etc/themis/plugins/example";

struct ExampleConfig {
	std::string id;
	std::string type;
	std::string title;
	json defaults;
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

bool writeJsonFile(const fs::path &path, const json &value)
{
	std::error_code ec;
	const fs::path parent = path.parent_path();
	if (!parent.empty()) {
		fs::create_directories(parent, ec);
		if (ec) {
			return false;
		}
	}

	std::ofstream out(path);
	if (!out.is_open()) {
		return false;
	}

	out << value.dump(JSON_DUMP_INDENT) << '\n';
	return out.good();
}

std::string configIdFromPath(const std::string &path)
{
	std::string configId = fs::path(path).filename().string();
	const std::string suffix = ".json";
	if (configId.size() >= suffix.size() &&
	    configId.compare(configId.size() - suffix.size(), suffix.size(),
			     suffix) == 0) {
		configId.erase(configId.size() - suffix.size());
	}
	return configId;
}

/*
 * This is written as an UI example. This is not a real configuration file.
 * This is for just viewing UI elements.
 */
json makeExampleConfig(const std::string &secondaryName, bool secondaryEnabled,
		       const std::string &secondaryNotes)
{
	return {
		{ "info_text",
		  "This text is loaded from the active example config." },
		{ "toggle_enabled", "enabled" },
		{ "action_button", false },
		{ "long_text",
		  "Example multi-line text.\nEdit this value and save to exercise the text item." },
		{ "short_text", "example-value" },
		{ "release_channel", "stable" },
		{ "schedule", "daily" },
		{ "enabled_modules", json::array({ "networking", "logging" }) },
		{ "secondary_name", secondaryName },
		{ "secondary_enabled", secondaryEnabled },
		{ "secondary_notes", secondaryNotes },
		{ "map_list", json::array({ { { "name", "Allow SSH" },
					      { "enabled", true },
					      { "mode", "audit" } },
					    { { "name", "Log denied traffic" },
					      { "enabled", false },
					      { "mode", "enforce" } } }) },
		{ "plain_list",
		  json::array({ "first plain item", "second plain item" }) },
		{ "map_map",
		  { { "alpha",
		      { { "enabled", true }, { "note", "Alpha entry" } } },
		    { "beta",
		      { { "enabled", false }, { "note", "Beta entry" } } } } },
		{ "plain_map",
		  { { "feature-a", true }, { "feature-b", false } } }
	};
}

const std::vector<ExampleConfig> &exampleConfigs()
{
	static const std::vector<ExampleConfig> configs = {
		{ "mainConfig", "exampleMain", "Example UI Showcase",
		  makeExampleConfig(
			  "Main showcase config", true,
			  "The primary config used by the main example page.") },
		{ "secondaryAlpha", "exampleSecondary", "Secondary Alpha",
		  makeExampleConfig(
			  "Secondary Alpha", true,
			  "A seeded secondary config rendered by config-typed widgets.") },
		{ "secondaryBeta", "exampleSecondary", "Secondary Beta",
		  makeExampleConfig(
			  "Secondary Beta", false,
			  "Another seeded secondary config for page-button rendering.") }
	};
	return configs;
}

const ExampleConfig *findExampleConfig(const std::string &configId)
{
	for (const auto &config : exampleConfigs()) {
		if (config.id == configId) {
			return &config;
		}
	}
	return nullptr;
}

json makeConfigTypeJson()
{
	json confType = json::array();
	for (const auto &config : exampleConfigs()) {
		confType.push_back({ { "pluginId", PLUGIN_ID },
				     { "configId", config.id },
				     { "configType", config.type },
				     { "title", config.title } });
	}
	return confType;
}

json makeDbusCredJson()
{
	json dbusCred;
	dbusCred["test"] = { { "interface", "org.themis.GenericBus" },
			     { "bus", PLUGIN_BUS },
			     { "member", "testExample" } };
	dbusCred["getConfig"] = json::object();
	dbusCred["setConfig"] = json::object();

	for (const auto &config : exampleConfigs()) {
		dbusCred["getConfig"][config.id] = {
			{ "interface", "org.themis.GenericBus" },
			{ "bus", PLUGIN_BUS },
			{ "member", "getExampleConfig" }
		};
		dbusCred["setConfig"][config.id] = {
			{ "interface", "org.themis.GenericBus" },
			{ "bus", PLUGIN_BUS },
			{ "member", "setExampleConfig" }
		};
	}

	dbusCred["jsonGenerated"] = { { "interface", "org.themis.GenericBus" },
				      { "bus", THEMIS_BUS },
				      { "member", "jsonGenerated" } };
	dbusCred["confGenerated"] = { { "interface", "org.themis.GenericBus" },
				      { "bus", THEMIS_BUS },
				      { "member", "confGenerated" } };
	dbusCred["ruleReady"] = { { "interface", "org.themis.GenericBus" },
				  { "bus", THEMIS_BUS },
				  { "member", "ruleReady" } };
	dbusCred["testReady"] = { { "interface", "org.themis.GenericBus" },
				  { "bus", THEMIS_BUS },
				  { "member", "testReady" } };
	return dbusCred;
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

bool testFunction(std::string str)
{
	(void)str;
	printf("You hit the test function for example plugin!\n");
	sendReadyMessage("testReady");
	return true;
}

bool getExampleConfig(std::string outputPath)
{
	/*
	 * [POINT 1]
	 * Normally if a file is not existing and path is valid, you generate the json versions
	 * of those configuration files in here, but for the sake of ease-of-learn, I decided to
	 * do that on initialization.
	 */
	const std::string configId = configIdFromPath(outputPath);
	const ExampleConfig *config = findExampleConfig(configId);
	bool ok = config != nullptr;

	if (ok && !fs::exists(outputPath)) {
		ok = writeJsonFile(outputPath, config->defaults);
	}

	json response;
	response["plugin_id"] = PLUGIN_ID;
	response["state"] = "true";
	Themis::SenderThread::instance().addMessage(
		response.dump(JSON_DUMP_INDENT), "org.themis.GenericBus",
		"org.themis.ProjectThemis", "default", "jsonGenerated",
		Themis::OsFlag_t::NOFLAG);
	return ok;
}

bool setExampleConfig(std::string inputPath)
{
	const std::string configId = configIdFromPath(inputPath);
	bool ok = findExampleConfig(configId) != nullptr;

	if (ok) {
		try {
			json posted = get_json(inputPath);
			ok = posted.is_object() &&
			     writeJsonFile(inputPath, posted);
		} catch (const std::exception &) {
			ok = false;
		}
	}

	json response;
	response["plugin_id"] = PLUGIN_ID;
	response["state"] = "true";
	Themis::SenderThread::instance().addMessage(
		response.dump(JSON_DUMP_INDENT), "org.themis.GenericBus",
		"org.themis.ProjectThemis", "default", "confGenerated",
		Themis::OsFlag_t::NOFLAG);
	return ok;
}

void sendRuleReady()
{
	sendReadyMessage("ruleReady");
}

void generateImportantFiles()
{
	const fs::path dbusCredPath = PLUGIN_ROOT / "dbus_cred.json";
	const fs::path confTypePath = PLUGIN_ROOT / "conf_type.json";

	try {
		fs::create_directories(PLUGIN_ROOT);

		/*
		 * For normal use cases, please generate any configuration file on demand.
		 * You can have a look into any of our self-written plugins for how to do that.
		 * Such as, Firewalld, Apache, Remote Plugins.
		 * Please refer to - [POINT 1] -
		 */
		if (!writeJsonFile(confTypePath, makeConfigTypeJson())) {
			return;
		}
		if (!writeJsonFile(dbusCredPath, makeDbusCredJson())) {
			return;
		}

		for (const auto &config : exampleConfigs()) {
			const fs::path configPath =
				PLUGIN_ROOT / (config.id + ".json");
			if (!fs::exists(configPath) &&
			    !writeJsonFile(configPath, config.defaults)) {
				return;
			}
		}
	} catch (const std::exception &) {
		return;
	}
}
