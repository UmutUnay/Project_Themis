/*
 * Author: UMUT UNAY
 * Date: 2025-12-02 22:10:23
 * LastEditTime: 2025-12-20 18:18:16
 * Description: 
 */

#include "thread.hh"

Themis::Thread::Thread()
{
	// Nothing for now
}

Themis::Thread::~Thread()
{
#ifdef BUILD_LINUX
	pthread_exit(nullptr);
#endif //BUILD_LINUX
}

// Simple loop
void Themis::Thread::enable()
{
#ifdef BUILD_LINUX
	int rc = pthread_create(&id, nullptr, &Thread::threadEntry, this);
	if (rc != 0) {
		// Gracefully dies.
	}
#endif //BUILD_LINUX
}

void *Themis::Thread::threadEntry(void *arg)
{
	static_cast<Thread *>(arg)->threadMain();
	return nullptr;
}

void Themis::Thread::threadMain()
{
	preparationPhase();
	while (1) {
		execute();
	}
}
