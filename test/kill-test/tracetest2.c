#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/syscall.h>

#include "tracetest-tp.h"

#define NUM_THREADS 100
int maxloop = 1000;

int gettid()  {
	return (int) syscall(SYS_gettid);
}

void * thread_function(void * na)
{
	int i;

	printf("Running thread: %i (%i)\n", gettid(), maxloop);

	for (i = 0; i < maxloop; i++) {
		tracepoint(prime, rcs1, i, "test");
		if (i%2 == 0) tracepoint(prime, rcs2, i, "test");
		if (i%10 == 0) tracepoint(prime, rcs3, i, "test");
	}

	return (void*) NULL;
}

int main(int argc, char* argv[])
{
	pthread_t threads[NUM_THREADS];
	int rc, t;
	int *res;
	int maxthreads = 2;

	tracepoint(prime, rcs1, 1, "MAIN");
	printf("usage: %s <no_of_loops> <no_of_threads>\n", argv[0]);
	if (argc >= 2) {
		maxloop = atoi(argv[1]);
	}

	if (argc >= 3) {
		maxthreads = atoi(argv[2]);
		if (maxthreads > NUM_THREADS) maxthreads = NUM_THREADS;
	}

	printf("Main thread: %i (%i,%i)\n", gettid(), maxloop, maxthreads);
	if (maxthreads == 0)
		thread_function(NULL);
	else if (maxthreads < 0 ) {
		if (fork() == 0) {
			thread_function(NULL);
		}
		else if (maxthreads == -2 ) {
			thread_function(NULL);
		}
	}
	else {

		for (t = 0; t < maxthreads; t++) {
			rc = pthread_create(&threads[t], NULL, thread_function, (void *) NULL);
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
			/* printf("join: %i\n", t); */
		}
	}
	return 0;
}
