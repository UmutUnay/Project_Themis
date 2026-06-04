/*
 * Author: UMUT UNAY
 * Date: 2025-11-11 16:06:01
 * LastEditTime: 2025-12-20 18:21:59
 * Description: 
 */

#ifndef DBUS_D048B553_C63C_45DB_837B_3B62BCA8A68B
#define DBUS_D048B553_C63C_45DB_837B_3B62BCA8A68B

#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <utility>
#include <unistd.h>
#include <dbus/dbus.h>
#include <nlohmann/json.hpp>
#include "Flag.hh"

namespace Themis
{
/*
 * @brief This is a Meyer's Singketon implementation of DBus by our development team.
 * We decided that we want a single object per process, hence that is why we want
 * it to be a Singleton object. The idea is each `dbus` object should be used in order:
 * 
 * For the customer app:
 * 
 * 1. Themis::dbus::instance().setName(newName); (Sets the name with the given name)
 * 
 * 2. Themis::dbus::instance().connect(); (This will connect to the given named dbus session)
 * 
 * NOTE: If there is not a server named like that please handle manually.
 *
 * For the producer(server) app:
 * 
 * 1. Themis::dbus::instance().init(newName); (Initializes dbus with the given name)
 * 
 * NOTE: This must be called before the customer process is even created to be sure that it starts
 */
class dbus {
    public:
	static dbus &instance();

	dbus(const dbus &) = delete;
	dbus &operator=(const dbus &) = delete;

	/*
     * @brief This will initializes the bus with the given name.
	 * @param name It is the name of the bus
	 * @return It will return `true` if successful, `false` if it encounters an error
     * @note Only for server application
     */
	bool init(std::string name);

	/*
     * @brief This will connect the bus with the setted name.
	 * @return It will return `true` if successful, `false` if it encounters an error
     * @note Only for client application
     */
	bool connect(void);

	/*
     * @brief If you want to send a message please create them in `JSON` then convert them to string
     * then call `Themis::dbus::sendMessage(newMessagge);`.
     * 
     * @note Please note that this function will block which thread it is on to send the message
	 * To overcome this, please use Themis::OsFlag_t::NONBLOCK flag when calling this function
	 * It will create a new thread to read the message.
	 * 
	 * It should be considered that, this sends message to the specified interface, and please use it
     */
	bool sendMessage(const std::string &message, const std::string &obj,
			 const std::string &interface,
			 const std::string &destination,
			 const std::string &method, Themis::OsFlag_t flags);

	/*
     * @brief If you want to receive a message please create them in `JSON` then convert them to string
     * then call `Themis::dbus::receiveMessage(messageBuffer);`. It will return the received message as parameter.
     * 
     * @note Please note that this function will block which thread it is on to receive the message
	 * To overcome this, please use Themis::OsFlag_t::NONBLOCK flag when calling this function
	 * It will create a new thread to read the message.
	 * 
	 * It should be noted that this function received only one message and is done after that. It is done because
	 * we want more freedom when handling bus. If one wants to open it for a specific message return, than one
	 * should recieve only one message. It can also be developed read messages continously when placed inside
	 * a loop and implemented a queue to serve the messages to upper application levels.
     */
	bool receiveMessage(std::string &method, std::string &message,
			    Themis::OsFlag_t flags, u32 timeout);

	/*
	 * @brief This just sets the bus name.
	 *
	 * @note This MUST be called before you use `connect`.
	 */
	void setName(std::string newName);

	/*
	 * @brief This is the way to add a rule to the created dbus.
	 *
	 * @note This MUST be called after using `init()`, otherwise, your server will not read any messages.
	 */
	void addRule(std::string newRule);

	/*
	 * @brief This is the way to apply all the rules to the created dbus.
	 *
	 * @note This MUST be called after using `init()` and `addRule`, otherwise, your server will not read any messages.
	 */
	void applyRules();
	void loadRules(const std::string &path);

	void addInterface(std::string newInterface);
	void removeInterface(const std::string &interfaceName);

	std::string getName();

	void attachReplyHandler(void (*customHandler)());

    private:
	dbus();
	dbus(std::string name);
	~dbus() = default;

	void (*_replyHandler)() = nullptr;

	DBusConnection *conn;
	std::vector<std::string> rules;
	std::string name;
	std::vector<std::string> interfaces;
	std::vector<std::pair<std::string, std::string> > methods;

	static constexpr const char *D_DBUS_OBJECT_PATH =
		"/org/themis/GenericBus";
	static constexpr const char *D_DBUS_METHOD = "GenericMessage";
};
}

#endif // DBUS_D048B553_C63C_45DB_837B_3B62BCA8A68B
