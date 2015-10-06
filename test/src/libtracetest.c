#include <stdio.h>
#include <unistd.h>
#include <syscall.h>

#include <lttng/tracef.h>
#include <lttng/tracepoint.h>

#define TRACEF(fmt, args...) tracef(fmt,##args)
//#define TRACEF(fmt, args...) do {} while (0)
#define PRINTF(fmt, args...) printf(fmt,##args)

#define DEBUG
#ifdef DEBUG
#  define PRINT(fmt, args...) { PRINTF(fmt,args); TRACEF(fmt,args); }
#else
#  define PRINT(fmt, args...) do {} while (0)
#endif

int gettid()  {
	return (int) syscall (SYS_gettid);
}

void tracetest_lib1(int events)
{
	int tid;

	tid = gettid();

	PRINT("%s: Start thread: %i (%i)\n", __func__, tid, events);
	PRINT("%s: End thread: %i (%i)\n", __func__, tid, events);
}

void tracetest_lib2(int events)
{
	int tid;

	tid = gettid();
	PRINT("%s: Start thread: %i (%i)\n", __func__, tid, events);
	PRINT("%s: End thread: %i (%i)\n", __func__, tid, events);
}

void tracetest_lib3(int events)
{
	int tid;

	tid = gettid();
	PRINT("%s: Start thread: %i (%i)\n", __func__, tid, events);
	PRINT("%s: End thread: %i (%i)\n", __func__, tid, events);
}
