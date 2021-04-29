# Default settings
HOSTNAME	?= $(shell hostname)
USER		?= $(shell whoami)
UID		?= $(shell id -u)

# Don't inherit path from environment
export PATH	:= /bin:/usr/bin
export SHELL	:= /bin/bash
export TERM	:= xterm

# Optional configuration
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk
-include userconfig-$(HOSTNAME)-$(USER).mk

TOP	:= $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
 export Q=@
 export SILENT=--no-print-directory
 DEVNULL ?= > /dev/null
 quiet = -q
 TRACE =
else
 TRACE	= @(tput setaf 1; echo ------ $@; tput sgr0)
endif

export V

IF	= $(Q)if
CD	= $(Q)cd
CP	= $(Q)cp
DOCKER	= $(Q)docker
ECHO	= $(Q)echo
MAKE	= $(Q)make $(SILENT)
MKDIR	= $(Q)mkdir -p
RM	= $(Q)rm -f

ifneq ($(UID),0)
 SUDOMAKE = $(Q)sudo make $(SILENT)
 SUDO	  = $(Q)sudo
else
 SUDOMAKE = $(MAKE)
 SUDO     =
endif


####################################################################
# help

.PHONY: *.help

GREEN	= $(Q)tput setaf 2
RED	= $(Q)tput setaf 1
NORMAL	= $(Q)tput sgr0

define run-note
	$(GREEN)
	$(ECHO) $(1)
	$(NORMAL)
endef

define run-help
	$(GREEN)
	$(ECHO) -e "\n----- $@ -----"
	$(Q)grep ":" $(1) | grep -v -e grep | grep -v "\#\#" | grep -e "\#" | sed 's/:/#/' | cut -d'#' -f1,3 | sort | column -s'#' -t
	$(NORMAL)
endef

####################################################################
# stamps
STAMPSDIR = $(TOP)/.stamps
vpath % $(STAMPSDIR)
MKSTAMP = $(Q)mkdir -p $(STAMPSDIR) ; touch $(STAMPSDIR)/$@
%.force:
	$(call rmstamp,$*)
	$(MAKE) $*

define rmstamp
	$(RM) $(STAMPSDIR)/$(1)
endef
