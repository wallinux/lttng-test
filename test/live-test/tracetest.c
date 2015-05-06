#include <stdio.h>
#include <pthread.h>
#include <sys/syscall.h>

#include "tracetest-tp.h"

#define NUM_THREADS 100
int maxloop = 1000;

int gettid()  {
	return (int) syscall (SYS_gettid);
}

void * thread_function(void * na)
{
	int i;
	static int tid;

	tid = gettid();

	printf("Running thread: %i (%i)\n", tid, maxloop);

	for (i = 0; i < maxloop; i++) {
		tracepoint(tracetest, first_tp, i, "test");
	}
}

int main(int argc, char* argv[])
{
	pthread_t threads[NUM_THREADS];
	int rc;
	long t;
	int *res;
	int maxthreads = 2;

	// printf("usage: %s <no_of_loops> <no_of_threads>\n", argv[0]);
	if (argc >= 2) {
		maxloop = atoi(argv[1]);
	}

	if (argc >= 3) {
		maxthreads = atoi(argv[2]);
		if (maxthreads > NUM_THREADS) maxthreads = NUM_THREADS;
	}

	for (t = 0; t < maxthreads; t++) {
		rc = pthread_create(&threads[t], NULL, thread_function, (void *) t);
		if (rc) {
			printf("ERROR; return code from pthread_create() is %d\n", rc);
			exit(-1);
		}
	}
	for (t = 0; t < maxthreads; t++) {
		rc = pthread_join(threads[t], (void*) &res);
		if (rc) {
			printf("ERROR; return code from pthread_join() is %d\n", rc);
			exit(-1);
		}
	}
	return 0;
}
