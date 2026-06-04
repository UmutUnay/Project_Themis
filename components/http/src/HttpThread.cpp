/*
 * Author: UMUT UNAY
 * Date: 2025-12-23 23:01:27
 * LastEditTime: 2025-12-23 23:09:32
 * Description: 
 */

#include "HttpThread.hh"

Themis::HttpThread &Themis::HttpThread::instance()
{
	static Themis::HttpThread obj;
	return obj;
}

Themis::HttpThread::HttpThread()
	: server{}
	, ipv4{ "127.0.0.1" }
	, port{ 8080 }
{
	// Nothing
}

void Themis::HttpThread::preparationPhase()
{
	printf("Binded on http://%s:%d\n", ipv4.c_str(), port);
	server.listen(ipv4.c_str(), port);
}

void Themis::HttpThread::execute(u32 timeout)
{
	// Code never reaches this part
	sleep(UINT32_MAX); // Test
}

void Themis::HttpThread::setIpv4(std::string ip, int prt)
{
	ipv4 = std::move(ip);
	port = prt;
}

void Themis::HttpThread::registerUri(Themis::httpMethod_t method,
				     std::string uri,
				     void (*func)(const httplib::Request &req,
						  httplib::Response &res))
{
	switch (method) {
	case Themis::httpMethod_t::GET:
		server.Get(uri.c_str(), func);
		break;
	case Themis::httpMethod_t::POST:
		server.Post(uri.c_str(), func);
		break;
	case Themis::httpMethod_t::PUT:
		server.Put(uri.c_str(), func);
		break;
	case Themis::httpMethod_t::DELETE:
		server.Delete(uri.c_str(), func);
		break;
	case Themis::httpMethod_t::OPTIONS:
		server.Options(uri.c_str(), func);
		break;
	case Themis::httpMethod_t::PATCH:
		server.Patch(uri.c_str(), func);
		break;
	}
}
