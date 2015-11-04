# Define V=1 to echo everything
V	?= 0
ifneq ($(V),1)
	Q=@
	MFLAGS += -s
endif

CFLAGS = -Wall
LTTNG_LIBS = -llttng-ust -lurcu -lurcu-common -lurcu-cds -lurcu-bp -llttng-ust-tracepoint -llttng-ctl -llttng-ust-fork

all:  libtracetest.so tracetest
	$(Q)echo using $(CC)


tracedef.h tracedef.c: tracedef.tp Makefile
	$(Q)lttng-gen-tp $< -o $@

tracedef.o: tracedef.c tracedef.h Makefile
	$(Q)$(CC) -c -I. -o $@ $< -llttng-ust

tracetest: tracetest.c tracedef.o
	$(Q)$(CC) $(CFLAGS) tracedef.o -o $@ $< -L. -ldl -ltracetest $(LTTNG_LIBS) -pthread

libtracetest.so: libtracetest.c
	$(Q)$(CC) -c -Wall -Werror -fpic $<
	$(Q)$(CC) -shared -o $@ libtracetest.o

clean:
	$(Q)rm -f tracetest *.o *.so tracetest-tp.[och] tracedef.[och]
	$(Q)rm -f *~ \#*

splint:
# Failing in linux header files
	$(Q)splint tracetest.c +posixlib  -I/usr/local/include
