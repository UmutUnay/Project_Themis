/*
 * Author: UMUT UNAY
 * Date: 2025-12-21 15:56:37
 * LastEditTime: 2025-12-21 22:22:27
 * Description: 
 */

#ifndef SENDER_THREAD_C32C67F6_3289_496B_9CBF_1D2D26C269E1
#define SENDER_THREAD_C32C67F6_3289_496B_9CBF_1D2D26C269E1

#ifdef BUILD_LINUX
#include <pthread.h>
#endif // BUILD_LINUX
#include <queue>
#include "Flag.hh"
#include "dbus.hh"
#include "thread.hh"

namespace Themis
{
typedef struct {
	std::string message;
	std::string interface;
	std::string destination;
	std::string destinationObj;
	std::string method;
	Themis::OsFlag_t flags;
} msg_t;

class SenderThread : public Thread {
    public:
	static SenderThread &instance();
	SenderThread(const SenderThread &) = delete;
	SenderThread &operator=(const SenderThread &) = delete;

	void preparationPhase() override;
	void execute(u32 timeout = 0) override;

	void setBus(Themis::dbus *newBus);
	void addMessage(const std::string &message,
			const std::string &interface,
			const std::string &destination,
			const std::string &destObj, const std::string &method,
			Themis::OsFlag_t flags);

    private:
	SenderThread();
	~SenderThread() = default;

	Themis::dbus *bus = nullptr;
	std::string obj;
	std::queue<msg_t> messageQueue;
};
}

#endif // SENDER_THREAD_C32C67F6_3289_496B_9CBF_1D2D26C269E1