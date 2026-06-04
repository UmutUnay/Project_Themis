/*
 * Author: UMUT UNAY
 * Date: 2025-12-02 21:02:13
 * LastEditTime: 2025-12-20 18:08:12
 * Description: 
 */

#ifndef THREAD_FBBBCC0D_7784_4E51_9F2E_23E136A3C1A8
#define THREAD_FBBBCC0D_7784_4E51_9F2E_23E136A3C1A8

#include "Definitions.hh"

#ifdef BUILD_LINUX
#include <pthread.h>
#include <vector>
#endif //BUILD_LINUX

/*
 * @brief This class uses pthread library to create, delete, and modify threads.
 * For now, it will only support Linux kernel, however if needed it can be extend.
 * @note These threads can not be copied or moved since it will be very annoying to deal with.
 */
namespace Themis
{
class Thread {
    public:
	Thread();
	~Thread();
	Thread(const Thread &) = delete;
	Thread &operator=(const Thread &) = delete;

	/*
	 * Do NOT override this!
	 */
	void enable();

	// Override them
	virtual void preparationPhase() = 0;
	virtual void execute(u32 timeout = 0) = 0;
	// bugd::ThreadFlags_t listeningFlags

    private:
#ifdef BUILD_LINUX
	static void *threadEntry(void *arg);
	void threadMain();

	pthread_t id;
#endif
};
}

#endif // THREAD_FBBBCC0D_7784_4E51_9F2E_23E136A3C1A8
