SHELL=/bin/bash

UID = $(shell id -u)
TOP = $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
export Q=@
export SILENT=-s
endif

CD	= $(Q)cd
RM	= $(Q)rm -f
MAKE	= $(Q)make $(SILENT)
MKDIR	= $(Q)mkdir -p
ECHO	= $(Q)echo
RED	= $(Q)tput setaf 1
GREEN	= $(Q)tput setaf 2
NORMAL	= $(Q)tput sgr0
TRACE	= $(Q)tput setaf 1; echo ------ $@; tput sgr0

ifneq ($(UID),0)
 SUDOMAKE = $(Q)sudo make $(SILENT)
 SUDO	  = $(Q)sudo
else
 SUDOMAKE = $(MAKE)
 SUDO     =
endif

PATCH	= $(Q)$(TOP)/patch-lttng

STAMPDIR = $(TOP)/.stamps
vpath % $(STAMPDIR)
MKSTAMP = $(Q)mkdir -p $(STAMPDIR) ; touch $(STAMPDIR)/$@

REPO_userspace-rcu = git://git.liburcu.org/userspace-rcu.git
REPO_lttng-ust     = git://git.lttng.org/lttng-ust.git
REPO_lttng-tools   = git://git.lttng.org/lttng-tools.git
REPO_babeltrace    = https://git.efficios.com/babeltrace.git
REPO_lttng-modules = git://git.lttng.org/lttng-modules.git/

#EXTRA_REPOS	?= lttng-modules
REPOS		+= userspace-rcu
REPOS		+= lttng-ust
REPOS		+= lttng-tools
REPOS		+= babeltrace
REPOS		+= $(EXTRA_REPOS)

CONF_PREFIX			?= --prefix=$(INSTALLDIR)/$(branch)/usr
CONF_OPTION_userspace-rcu	?= $(CONF_PREFIX)
CONF_OPTION_lttng-ust		?= $(CONF_PREFIX) --disable-man-pages
CONF_OPTION_lttng-tools		?= $(CONF_PREFIX) --with-lttng-ust --enable-man-pages --enable-embedded-help
CONF_OPTION_babeltrace		?= $(CONF_PREFIX)

OUTDIR		= $(TOP)/out
SRCDIR		= $(OUTDIR)/src
BUILDDIR	= $(OUTDIR)/build
INSTALLDIR	= $(OUTDIR)/install

branch		?= none

TARGET=$(eval target=$(subst .$*,,$@))

####################################################################################

help::
	$(GREEN)
	$(Q)grep -e ": " -e ":$$"  Makefile | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort
	$(NORMAL)

$(SRCDIR):
	$(TRACE)
	$(MKDIR) $@

$(REPOS): $(SRCDIR)
	$(Q)cd $<; git clone $(REPO_$@)

update repo.pull:
	$(TRACE)
	$(Q)$(foreach repo,$(REPOS),make $(repo); git -C $(SRCDIR)/$(repo) pull; )

configure.%:
	$(TRACE)
	$(TARGET)
	$(MKDIR) $(BUILDDIR)/$(branch)/$*
	$(CD) $(BUILDDIR)/$(branch)/$*; $(TOP)/$*/worktree/$(branch)/$(target) $(CONF_OPTION_$*)

unconfigure.%:
	$(TRACE)
	$(TARGET)
	$(RM) -r $(BUILDDIR)/$(branch)/$*

all.%:
	$(TRACE)
	$(TARGET)
	$(Q)if [ ! -e $(BUILDDIR)/$(branch)/$*/config.status ]; then make configure.$*; fi
	$(MAKE) -C $(BUILDDIR)/$(branch)/$* $(target)

install.%:
	$(TRACE)
	$(TARGET)
	$(MAKE) all.$*
	$(SUDOMAKE) -C $(BUILDDIR)/$(branch)/$* $(target)
	$(MAKE) env.$*

uninstall.%:
	$(TRACE)
	$(TARGET)
	$(SUDOMAKE) -C $(BUILDDIR)/$(branch)/$* $(target)

distclean.%:
	$(TRACE)
	$(TARGET)
	$(SUDO) rm -rf $(INSTALLDIR)/$(branch)/*
	$(RM) -r $(BUILDDIR)/$(branch)/*/*

clean.% TAGS.% CTAGS.% distclean-tags.%:
	$(TRACE)
	$(TARGET)
	$(Q)if [ -e $(BUILDDIR)/$(branch)/$*/Makefile ]; then \
		make -C $(BUILDDIR)/$(branch)/$* $(target); \
	fi

fast_regression.lttng-tools root_regression.lttng-tools:
	$(TRACE)
	$(eval target=$(subst .lttng-tools,,$@))
	$(CD) $(BUILDDIR)/lttng-tools/tests/; ./run.sh $(target) |& tee $(target).out

userspace_regression.lttng-tools:
	$(TRACE)
	$(eval target=$(subst .lttng-tools,,$@))
	$(CD) $(BUILDDIR)/lttng-tools/tests/; ./run.sh $(TOP)/$(target) |& tee $(target).out

test.lttng-tools: userspace_regression.lttng-tools

DISTCLEAN:
	$(TRACE)
	$(SUDO) rm -rf $(INSTALLDIR)
	$(RM) -r $(BUILDDIR)
	$(RM) -r $(SRCDIR)

env:
	$(TRACE)
	$(ECHO) LD_LIBRARY_PATH=$(INSTALLDIR)/$(branch)/usr/lib > $(OUTDIR)/$(branch).env
	$(ECHO) PATH=$(INSTALLDIR)/$(branch)/usr/bin:$$PATH >> $(OUTDIR)/$(branch).env

all configure unconfigure install distclean uninstall clean TAGS CTAGS distclean-tags:
	$(TRACE)
	$(ECHO) "BRANCH=$(branch)"
	$(Q)$(foreach repo,$(REPOS),make $@.$(repo);)

ALL: install

.PHONY: install configure all clean distclean

include rcs.mk
