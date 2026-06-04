/*
 * Author: UMUT UNAY
 * Date: 2025-12-21 15:56:44
 * LastEditTime: 2025-12-21 23:08:25
 * Description: 
 */

#include "senderThread.hh"

Themis::SenderThread::SenderThread()
{
	// Nothing for now
}

Themis::SenderThread &Themis::SenderThread::instance()
{
	static SenderThread obj;
	return obj;
}

void Themis::SenderThread::setBus(Themis::dbus *newBus)
{
	bus = newBus;
}

void Themis::SenderThread::addMessage(const std::string &msg,
				      const std::string &itf,
				      const std::string &dst,
				      const std::string &destObj,
				      const std::string &mtd,
				      Themis::OsFlag_t flg)
{
	msg_t e{
		.message = msg,
		.interface = itf,
		.destination = dst,
		.destinationObj = destObj,
		.method = mtd,
		.flags = flg,
	};
	if (destObj == "default") {
		e.destinationObj = obj;
	}
	messageQueue.push(e);
}

void Themis::SenderThread::preparationPhase()
{
	if (bus == nullptr) {
		printf("Please set the bus before calling enable!\n");
	}
	std::string _tmp = bus->getName();
	for (int i = 0; i < _tmp.size(); i++) {
		if (_tmp[i] == '.') {
			_tmp[i] = '/';
		}
	}
	_tmp.insert(_tmp.begin(), '/');
	obj = std::move(_tmp);
	printf("Waiting to send a message on bus := %s.\n", obj.c_str());
}

void Themis::SenderThread::execute(u32 timeout)
{
	std::string method, message;
	Themis::OsFlag_t flags = Themis::OsFlag_t::NOFLAG;
	if (!messageQueue.empty()) {
		msg_t e = messageQueue.front();
		messageQueue.pop();
		if (bus->sendMessage(e.message, e.destinationObj, e.interface,
				     e.destination, e.method,
				     e.flags) == false) {
			return;
		}
	}
	usleep(50 * 1000);
}
