
default: all

BSP		?= native

TOP		:= $(shell pwd)


# Define V=1 to echo everything
V	?= 0
ifneq ($(V),1)
	Q=@
endif

ECHO	:= $(Q)echo
RM	:= $(Q)rm -f
SDK_ENV := $(Q)export CC=gcc

CFLAGS	= -g -rdynamic

#########################################################
.PHONY: all build help

all: tracetest tracetest2
	$(Q)uname -a
	$(Q)$(CC) --version

$(OUTDIR):
	$(Q)mkdir -p $@

tracetest-tp.h: tracetest-tp.tp Makefile $(OUTDIR)
	$(Q)lttng-gen-tp $< -o $@ 

tracetest-tp.c: tracetest-tp.tp tracetest-tp.h Makefile $(OUTDIR)
	$(Q)lttng-gen-tp $< -o $@

tracetest-tp.o: tracetest-tp.c Makefile $(OUTDIR)
	$(SDK_ENV); $$CC -c -I. -llttng-ust -o $@ $<

tracetest: tracetest.c tracetest-tp.o Makefile
	$(SDK_ENV); $$CC $(CFLAGS) tracetest-tp.o -llttng-ust -ldl -o $@ $<

tracetest2: tracetest2.c tracetest-tp.o Makefile
	$(SDK_ENV); $$CC $(CFLAGS) tracetest-tp.o -llttng-ust -ldl -o $@ $< -pthread

run:
	./test.run ./tracetest

run.debug:
	DEBUG=1 ./test.run ./tracetest

clean:
	$(RM) tracetest
	$(RM) tracetest-tp.[cho]

distclean: clean
	$(RM) *~ \#*#
	$(RM) -r snapshot
