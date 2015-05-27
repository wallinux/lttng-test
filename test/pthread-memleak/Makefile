# Define V=1 to echo everything
V	?= 0
ifneq ($(V),1)
	Q=@
	MFLAGS += -s
endif

all:
	$(Q)make -s -C ../src all
	$(Q)ln -sfn ../src/tracetest .

clean:
	$(Q)rm -f tracetest
	$(Q)rm -f *~ \#*


