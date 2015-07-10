# Define V=1 to echo everything
V	?= 0
ifneq ($(V),1)
	Q=@
	MFLAGS += -s
endif

export LD_LIBRARY_PATH=/usr/local/lib

all:
	$(Q)make -s -C ../src all
	$(Q)ln -sfn ../src/tracetest .

run:
	LOOP=10000 NO_OF_THREADS=30 ./test-snapshot

clean:
	$(Q)rm -f tracetest
	$(Q)rm -f *~ \#*
	$(Q)rm -f *.log
	$(Q)rm -rf traces
