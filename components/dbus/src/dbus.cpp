/*
 * Author: UMUT UNAY
 * Date: 2025-11-11 16:06:07
 * LastEditTime: 2025-12-20 18:24:16
 * Description: 
 */

#include "dbus.hh"

using json = nlohmann::json;

Themis::dbus &Themis::dbus::instance()
{
	static dbus obj;
	return obj;
}

Themis::dbus::dbus()
{
	conn = nullptr;
	name = "org.themis.ProjectThemis";
}

Themis::dbus::dbus(std::string newName)
{
	conn = nullptr;
	name = std::move(newName);
}

bool Themis::dbus::init(std::string newName)
{
	DBusError err;
	dbus_error_init(&err);
	conn = dbus_bus_get(DBUS_BUS_SYSTEM, &err);
	name = newName;

	if (dbus_error_is_set(&err)) {
		return false;
	}
	if (!conn) {
		return false;
	}
	dbus_connection_set_exit_on_disconnect(conn, false);

	int ret = dbus_bus_request_name(conn, name.c_str(),
					DBUS_NAME_FLAG_REPLACE_EXISTING, &err);

	if (dbus_error_is_set(&err)) {
		return false;
	}

	if (ret != DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER &&
	    ret != DBUS_REQUEST_NAME_REPLY_ALREADY_OWNER) {
		printf("DBus is not owned by this process.");
		return false;
	}

	dbus_error_free(&err);
	return true;
}

bool Themis::dbus::connect()
{
	DBusError err;
	dbus_error_init(&err);
	conn = dbus_bus_get(DBUS_BUS_SYSTEM, &err);

	if (dbus_error_is_set(&err)) {
		dbus_error_free(&err);
		return false;
	}
	if (!conn) {
		dbus_error_free(&err);
		return false;
	}
	dbus_connection_set_exit_on_disconnect(conn, false);
	int ret = dbus_bus_request_name(conn, name.c_str(),
					DBUS_NAME_FLAG_DO_NOT_QUEUE, &err);

	if (dbus_error_is_set(&err)) {
		return false;
	}

	if (ret != DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER &&
	    ret != DBUS_REQUEST_NAME_REPLY_ALREADY_OWNER) {
		printf("DBus is not owned by this process.");
		return false;
	}
	dbus_error_free(&err);
	return true;
}

void Themis::dbus::setName(std::string newName)
{
	name = std::move(newName);
}

bool Themis::dbus::sendMessage(const std::string &message,
			       const std::string &obj,
			       const std::string &interface,
			       const std::string &destination,
			       const std::string &method,
			       Themis::OsFlag_t flags)
{
	if (!conn) {
		printf("DBus connection is not established.\n");
		return false;
	}

	DBusError err;
	dbus_error_init(&err);
	DBusMessage *msg =
		dbus_message_new_method_call(destination.c_str(), obj.c_str(),
					     interface.c_str(), method.c_str());

	if (!msg) {
		printf("DBus message signal creation failed.\n");
		dbus_error_free(&err);
		return false;
	}

	const char *_msg = message.c_str();
	if (flags == Themis::OsFlag_t::PARSE) {
		DBusMessageIter iter;

		dbus_message_iter_init_append(msg, &iter);

		std::vector<std::string> storage;
		std::vector<const char *> cstrs;
		json __msg = json::parse(message);

		for (const auto &item : __msg["args"]) {
			if (!item.is_string()) {
				printf("Only string args are supported.\n");
				dbus_message_unref(msg);
				dbus_error_free(&err);
				return false;
			}
			storage.push_back(item.get<std::string>());
		}

		for (auto &s : storage) {
			const char *p = s.c_str();
			if (!dbus_message_iter_append_basic(
				    &iter, DBUS_TYPE_STRING, &p)) {
				printf("DBus message argument creation failed.\n");
				dbus_message_unref(msg);
				dbus_error_free(&err);
				return false;
			}
		}
	} else {
		if (!dbus_message_append_args(msg, DBUS_TYPE_STRING, &_msg,
					      DBUS_TYPE_INVALID)) {
			printf("DBus message argument creation failed.\n");
			dbus_message_unref(msg);
			dbus_error_free(&err);
			return false;
		}
	}

	if (!dbus_connection_send(conn, msg, nullptr)) {
		printf("DBus message send failed.\n");
		dbus_message_unref(msg);
		dbus_error_free(&err);
		return false;
	}

	dbus_connection_flush(conn);
	dbus_message_unref(msg);
	dbus_error_free(&err);
	return true;
}

bool Themis::dbus::receiveMessage(std::string &method, std::string &message,
				  Themis::OsFlag_t flags, u32 timeout)
{
	if (!conn) {
		printf("DBus connection is not established.\n");
		return false;
	}

	while (true) {
		usleep(50 * 1000);
		// TODO: This is the blocking part, if the correct flag is set, this part should be on seperate thread
		// instead of a thread.
		DBusError err;
		dbus_error_init(&err);
		if (!dbus_connection_read_write(conn, timeout)) {
			printf("DBus read_write failed.\n");
			dbus_error_free(&err);
			return false;
		}

		DBusMessage *msg = dbus_connection_pop_message(conn);
		if (!msg) {
			continue;
		}

		// For now we drop our support for signals,
		// and we don't handle errors and invalid messages
		int type = dbus_message_get_type(msg);
		if ((type == DBUS_MESSAGE_TYPE_INVALID) ||
		    (type == DBUS_MESSAGE_TYPE_ERROR) ||
		    (type == DBUS_MESSAGE_TYPE_SIGNAL)) {
			dbus_message_unref(msg);
			continue;
		}

		/////////////////////////////////////////////////////////////////////////
		const char *iface = dbus_message_get_interface(msg);
		const char *member = dbus_message_get_member(msg);
		const char *path = dbus_message_get_path(msg);

		// Debug print so you SEE what the server actually receives
		if (BUILD_DEBUG) {
			printf("SERVER GOT: type=method_call\n");
			printf("  path      = %s\n", path ? path : "(null)");
			printf("  interface = %s\n", iface ? iface : "(null)");
			printf("  member    = %s\n",
			       member ? member : "(null)");
		}

		// Should be a direct method call
		if (!iface || !member) {
			dbus_message_unref(msg);
			continue;
		}

		// Should call one of our member methods
		bool _flag = false;
		for (const std::pair<std::string, std::string> &curMethod :
		     methods) {
			if (curMethod.second == member) {
				method = curMethod.second;
				_flag = true;
				break;
			}
		}
		if (!_flag) {
			dbus_message_unref(msg);
			continue;
		}

		const char *buf = nullptr;
		if (!dbus_message_get_args(msg, &err, DBUS_TYPE_STRING, &buf,
					   DBUS_TYPE_INVALID)) {
			printf("[INTERNAL ERROR] Dbus message parsing arguments failed with: %s\n",
			       err.message ? err.message : "unknown error");
			dbus_message_unref(msg);
			dbus_error_free(&err);
			return false;
		}
		message = buf ? buf : "";
		/////////////////////////////////////////////////////////////////////////

		dbus_message_unref(msg);
		dbus_error_free(&err);

		// Handle reply
		if (_replyHandler) {
			// wait here, possibly drop messages
			_replyHandler();
		}
		return true;
	}
	return false; // Should be unreachable
}

void Themis::dbus::addRule(std::string newRule)
{
	auto extractField = [&](const std::string &rule, const std::string &key,
				std::string &out) {
		auto pos = rule.find(key);
		if (pos == std::string::npos)
			return;

		pos = rule.find('\'', pos);
		if (pos == std::string::npos)
			return;

		auto end = rule.find('\'', pos + 1);
		if (end == std::string::npos)
			return;

		out = rule.substr(pos + 1, end - pos - 1);
	};

	std::string type, interface, member;
	extractField(newRule, "type=", type);
	extractField(newRule, "interface=", interface);
	extractField(newRule, "member=", member);
	if (!interface.empty()) {
		interfaces.push_back(interface);
	}
	if (!type.empty() && !member.empty()) {
		methods.push_back({ type, member });
	}
	rules.push_back(newRule);
}

void Themis::dbus::applyRules()
{
	DBusError err;
	dbus_error_init(&err);
	for (const std::string &rule : rules) {
		dbus_bus_add_match(conn, rule.c_str(), &err);
		dbus_connection_flush(conn);
		if (dbus_error_is_set(&err)) {
			printf("Rule apply failed with: %s\n",
			       err.message ? err.message : "unknown error");
			dbus_error_free(&err);
			return;
		}
	}
}

void Themis::dbus::addInterface(std::string newInterface)
{
	interfaces.push_back(newInterface);
}

void Themis::dbus::removeInterface(const std::string &interfaceName)
{
	for (size_t it = 0; it != interfaces.size(); it++) {
		std::string itfc = interfaces[it];
		if (itfc == interfaceName) {
			interfaces.erase(interfaces.begin() + it);
			break;
		}
	}
}

void Themis::dbus::attachReplyHandler(void (*customHandler)())
{
	_replyHandler = customHandler;
}

std::string Themis::dbus::getName()
{
	return name;
}

void Themis::dbus::loadRules(const std::string &path)
{
	std::ifstream file(path);
	if (!file.is_open()) {
		printf("Rule file open failed: %s\n", path.c_str());
		return;
	}

	std::string line;

	while (std::getline(file, line)) {
		if (line.empty() || line[0] == '#')
			continue;

		std::stringstream ss(line);

		std::string type;
		std::string interface;
		std::string member;

		std::getline(ss, type, ',');
		std::getline(ss, interface, ',');
		std::getline(ss, member, ',');

		std::string rule = "type='" + type + "',interface='" +
				   interface + "',member='" + member + "'";

		Themis::dbus::instance().addRule(rule);
	}
}
