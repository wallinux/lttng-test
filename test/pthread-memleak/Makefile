# Define V=1 to echo everything
V	?= 0
ifneq ($(V),1)
	Q=@
	MFLAGS += -s
endif

all: tracetest

tracetest-tp.h: tracetest-tp.tp Makefile
	$(Q)lttng-gen-tp $< -o $@

tracetest-tp.c: tracetest-tp.tp tracetest-tp.h Makefile
	$(Q)lttng-gen-tp $< -o $@

tracetest-tp.o: tracetest-tp.c Makefile
	$(Q)$(CC) -c -I. -o $@ $< -llttng-ust

tracetest: tracetest.c tracetest-tp.o 
	$(Q)$(CC) tracetest-tp.o -o $@ $< -llttng-ust -ldl -pthread

clean:
	$(Q)rm -f tracetest tracetest-tp.[och]
	$(Q)rm -f *~ \#*


