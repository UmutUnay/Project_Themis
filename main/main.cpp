/*
 * Author: UMUT UNAY
 * Date: 2025-10-16 19:37:00
 * LastEditTime: 2025-12-21 21:32:59
 * Description: 
 */

#include "init.hh"

int main()
{
	if (!initSelf()) {
		printf("Themis could not get set, please ensure that you have a connection before re-trying.\n");
		return -1;
	}
	if (!setUpWeb()) {
		printf("Web could not get set, please ensure that you have a connection before re-trying.\n");
		return -1;
	}
	initDbus();
	initComm();
	registerHttpAPI();
	restorePlugins();
	startWebUi();

	// Do NOT let main thread go
	while (1) {
		sleep(UINT32_MAX);
	}

	return 0; // Should be non-reachable
}
