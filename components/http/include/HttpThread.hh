/*
 * Author: UMUT UNAY
 * Date: 2025-12-23 22:54:40
 * LastEditTime: 2025-12-23 23:10:07
 * Description: 
 */

#ifndef HTTPTHREAD_HEFUBA8_2391D_ASDI3_AWQDDDN8CH0823
#define HTTPTHREAD_HEFUBA8_2391D_ASDI3_AWQDDDN8CH0823

#include <string>
#include <thread.hh>
#include <httplib.h>

namespace Themis
{
enum class httpMethod_t {
	GET = 0,
	POST = 1,
	PUT = 2,
	DELETE = 3,
	HEAD = 4,
	CONNECT = 5,
	OPTIONS = 6,
	TRACE = 7,
	PATCH = 8,
	NONE = 255,
	MAX = 8
};

class HttpThread : public Thread {
    public:
	static HttpThread &instance();
	HttpThread(const HttpThread &) = delete;
	HttpThread &operator=(const HttpThread &) = delete;

	void preparationPhase() override;
	void execute(u32 timeout = 0) override;

	void registerUri(httpMethod_t method, std::string uri,
			 void (*func)(const httplib::Request &req,
				      httplib::Response &res));
	void setIpv4(std::string ip, int prt);

    private:
	HttpThread();
	~HttpThread() = default;

	httplib::Server server;
	std::string ipv4;
	int port;
};
}

#endif // HTTPTHREAD_HEFUBA8_2391D_ASDI3_AWQDDDN8CH0823
