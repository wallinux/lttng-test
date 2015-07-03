# Define V=1 to echo everything
V	?= 0
ifneq ($(V),1)
	Q=@
	MFLAGS += -s
endif

CFLAGS = -Wall

all: tracetest
	$(Q)echo using $(CC)


tracedef.h tracedef.c: tracedef.tp Makefile
	$(Q)lttng-gen-tp $< -o $@

tracedef.o: tracedef.c tracedef.h Makefile
	$(Q)$(CC) -c -I. -o $@ $< -llttng-ust

tracetest: tracetest.c tracedef.o
	$(Q)$(CC) $(CFLAGS) tracedef.o -o $@ $< -llttng-ust -ldl -pthread

clean:
	$(Q)rm -f tracetest tracetest-tp.[och] tracedef.[och]
	$(Q)rm -f *~ \#*

splint:
# Failing in linux header files
	$(Q)splint tracetest.c +posixlib  -I/usr/local/include
