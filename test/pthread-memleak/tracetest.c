#include <stdio.h>
#include <pthread.h>
#include <sys/syscall.h>
#include <lttng/tracef.h>

#include "tracetest-tp.h"


#define PSCMD "ps -eo rss,vsize,pmem,pcpu,cmd | grep ./tracetest | grep -v grep"

#define NUM_THREADS 100
int maxloop = 10;

int gettid()  {
  return (int) syscall (SYS_gettid);
}

void * thread_function(void * na)
{
  int i;
  static int tid;

  tid = gettid();

  printf("Start thread: %i (%i)\n", tid, maxloop);
  tracef("Start thread: %i (%i)\n", tid, maxloop);

  for (i = 0; i < maxloop; i++) {
    tracepoint(tracetest, first_tp, i, "test");
    usleep(1000);
  }

  printf("End thread: %i (%i)\n", tid, maxloop);
}

int main(int argc, char* argv[])
{
  pthread_t threads[NUM_THREADS];
  int rc;
  long t;
  int *res;
  int maxthreads = 8;
  int i;

  if (argc >= 2) {
    maxloop = atoi(argv[1]);
  }

  if (argc >= 3) {
    maxthreads = atoi(argv[2]);
    if (maxthreads > NUM_THREADS) maxthreads = NUM_THREADS;
  }


  for (i=0; i<maxloop; i++) {	
    system(PSCMD);

    /* Create threads */
    for (t = 0; t < maxthreads; t++) {
      rc = pthread_create(&threads[t], NULL, thread_function, (void *) t);
      if (rc) {
	printf("ERROR; return code from pthread_create() is %d\n", rc);
	exit(-1);
      }
    }

    usleep(1000000);
    system(PSCMD);

    /* Join threads */
    for (t = 0; t < maxthreads; t++) {
      rc = pthread_join(threads[t], (void*) &res);
      if (rc) {
	printf("ERROR; return code from pthread_join() is %d\n", rc);
	exit(-1);
      }
    }
  }

  system(PSCMD);

  printf("%s finshed\n", argv[0]);
  return 0;
}
