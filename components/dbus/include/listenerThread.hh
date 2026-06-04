/*
 * Author: UMUT UNAY
 * Date: 2025-12-11 19:38:33
 * LastEditTime: 2025-12-21 23:08:19
 * Description: 
 */

#ifndef LISTENER_THREAD_AC6A368A_E7D1_4D03_99E7_AA7FC34C2B82
#define LISTENER_THREAD_AC6A368A_E7D1_4D03_99E7_AA7FC34C2B82

#ifdef BUILD_LINUX
#include <pthread.h>
#endif // BUILD_LINUX

#include "Flag.hh"
#include "dbus.hh"
#include "thread.hh"

namespace Themis
{
class ListenerThread : public Thread {
    public:
	static ListenerThread &instance();
	ListenerThread(const ListenerThread &) = delete;
	ListenerThread &operator=(const ListenerThread &) = delete;

	void preparationPhase() override;
	void execute(u32 timeout = 0) override;

	void setBus(Themis::dbus *newBus);
	void addFunction(std::string name, bool (*func)(std::string));

    private:
	ListenerThread();
	~ListenerThread() = default;

	Themis::dbus *bus = nullptr;
	//<template T> messageQueue; // Not Now
	std::vector<std::pair<std::string, bool (*)(std::string)> >
		functionTable{};
};
}

#endif // LISTENER_THREAD_AC6A368A_E7D1_4D03_99E7_AA7FC34C2B82
