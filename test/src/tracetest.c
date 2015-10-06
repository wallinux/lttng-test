#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <syscall.h>

#include <lttng/tracef.h>
#include "tracedef.h"
#include "libtracetest.h"

#define PSCMD "ps -eo rss,vsize,pmem,pcpu,cmd | grep -e ./tracetest | grep -v grep"
#define PRINT_PS if (print_ps) system(PSCMD);

#define MAX_THREADS 100
unsigned int loops = 10;
unsigned int events = 100;
int print_ps = 0;

//#define TRACEF(fmt, args...) tracef(fmt,##args)
#define TRACEF(fmt, args...) do {} while (0)
//#define PRINTF(fmt, args...) printf(fmt,##args)
#define PRINTF(fmt, args...) do {} while (0)

#define DEBUG
#ifdef DEBUG
#  define PRINT(fmt, args...) { PRINTF(fmt,args); TRACEF(fmt,args); }
#else
#  define PRINT(fmt, args...) do {} while (0)
#endif

static void * thread_function(void * na)
{
	int i;

	PRINT("Start thread: %i (%i)\n", gettid, events);

	for (i = 0; i < events; i++) {
		tracepoint(wr, wr1, i, "test1");
		tracepoint(wr, wr2, i, "test2");
		tracepoint(wr, wr3, i, "test3");
		usleep(1000);
	}
	tracetest_lib1(events);
	tracetest_lib2(events);
	tracetest_lib3(events);

	PRINT("End thread: %i (%i)\n", gettid, events);

	return NULL;
}

int main(int argc, char* argv[])
{
	pthread_t thread[MAX_THREADS];
	int rc;
	long t;
	int *res;
	int threads = 8;
	int i;

	/* arg[1] = no of loops creating/joining threads
	   arg[2] = no of threads created
	   arg[3] = no of events created/per thread
	*/

	if (argc >= 2) {
		loops = atoi(argv[1]);
	}

	if (argc >= 3) {
		threads = atoi(argv[2]);
		if (threads > MAX_THREADS) threads = MAX_THREADS;
	}

	if (argc >= 4) {
		events = atoi(argv[3]);
	}


	if (getenv("PRINT_PS") != NULL) {
		print_ps = 1;
	}

	for (i = 0; i < loops; i++) {
		PRINTF("%i:\n", i);
		PRINT_PS;

		/* Create threads */
		for (t = 0; t < threads; t++) {
			rc = pthread_create(&thread[t], NULL, thread_function, (void *) t);
			if (rc) {
				printf("ERROR; return code from pthread_create() is %d\n", rc);
				exit(-1);
			}
		}

		//sleep(1);

		/* Join threads */
		for (t = 0; t < threads; t++) {
			rc = pthread_join(thread[t], (void*) &res);
			if (rc) {
				printf("ERROR; return code from pthread_join() is %d\n", rc);
				exit(-1);
			}
		}
	}

	PRINT("%s finshed\n", argv[0]);
	PRINT_PS;
	return 0;
}
