/*
 * Author: UMUT UNAY
 * Date: 2025-12-11 19:40:57
 * LastEditTime: 2025-12-20 18:30:31
 * Description: 
 */

#include "listenerThread.hh"

Themis::ListenerThread::ListenerThread()
{
	// Nothing for now
}

Themis::ListenerThread &Themis::ListenerThread::instance()
{
	static ListenerThread obj;
	return obj;
}

void Themis::ListenerThread::setBus(Themis::dbus *newBus)
{
	bus = newBus;
}

bool genericMessageTestFunction(std::string message)
{
	if (message.empty()) { // Not necesssery since checked before
		return false;
	}
	printf("[GenericMessage] %s\n", message.c_str());
	return true;
}

void Themis::ListenerThread::addFunction(std::string name,
					 bool (*func)(std::string))
{
	functionTable.push_back(std::make_pair(name, func));
}

void Themis::ListenerThread::preparationPhase()
{
	if (bus == nullptr) {
		printf("Please set the bus before calling enable!\n");
	}
	addFunction("GenericMessage", genericMessageTestFunction);
	printf("Waiting on a message on bus := %s.\n", bus->getName().c_str());
}

void Themis::ListenerThread::execute(u32 timeout)
{
	std::string method, message;
	Themis::OsFlag_t flags = Themis::OsFlag_t::NOFLAG;
	if (bus->receiveMessage(method, message, flags, timeout) == false) {
		// Silent pass
		return;
	}

	if (method.empty() || message.empty()) {
		// Silent pass
		return;
	}

	// Make a trie for easier search later or rb-tree
	for (u8 i = 0; i < functionTable.size(); i++) {
		if (functionTable[i].first == method) {
			if (functionTable[i].second(message) == false) {
				printf("Function return is false");
				return;
			}
			break;
		}
	}
}

