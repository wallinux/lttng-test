V	?= 0
ifneq ($(V),1)
	Q=@
	MFLAGS += -s
endif

ECHO	:= $(Q)echo
RM	:= $(Q)rm -f
export CC=gcc

APPS	+= tracetest2

CFLAGS += -g -rdynamic $(CFLAGS_$(BSP)) -Wall

#########################################################
.PHONY: all

all: $(APPS)

tracetest-tp.h: tracetest-tp.tp Makefile
	lttng-gen-tp $< -o $@

tracetest-tp.c: tracetest-tp.tp tracetest-tp.h Makefile
	lttng-gen-tp $< -o $@

tracetest-tp.o: tracetest-tp.c Makefile
	$(CC) -c -I. -o $@ $< -llttng-ust

tracetest2: tracetest2.c tracetest-tp.o Makefile
	$(CC) $(CFLAGS) tracetest-tp.o -o $@ $< -pthread -llttng-ust -ldl

tracetest.clean:
	$(RM) tracetest-tp.[cho]

clean:
	$(RM) $(APPS)

distclean: tracetest.clean clean
	$(RM) *~ \#*#

test:
	./test-live
