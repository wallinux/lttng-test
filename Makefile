SHELL=/bin/bash

UID = $(shell id -u)
TOP = $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
Q=@
endif

CD	= $(Q)cd
RM	= $(Q)rm -f
MAKE	= $(Q)make
MKDIR	= $(Q)mkdir -p
ECHO	= $(Q)echo
RED	= $(Q)tput setaf 1
GREEN	= $(Q)tput setaf 2
NORMAL	= $(Q)tput sgr0
TRACE	= $(Q)tput setaf 1; echo ------ $@; tput sgr0

ifneq ($(UID),0)
SUDOMAKE= $(Q)sudo make
else
SUDOMAKE= $(MAKE)
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

CONF_PREFIX			?= --prefix=/usr
CONF_OPTION_userspace-rcu	?= $(CONF_PREFIX)
CONF_OPTION_lttng-ust		?= $(CONF_PREFIX) --disable-man-pages
CONF_OPTION_lttng-tools		?= $(CONF_PREFIX) --with-lttng-ust --enable-man-pages --enable-embedded-help
CONF_OPTION_babeltrace		?= $(CONF_PREFIX)

BUILDDIR	= $(TOP)/build

TARGET=$(eval target=$(subst .$*,,$@))

####################################################################################

help::
	$(GREEN)
	$(Q)grep -e ": " -e ":$$"  Makefile | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort
	$(NORMAL)

$(REPOS):
	$(Q)git clone $(REPO_$@)

update repo.pull:
	$(TRACE)
	$(Q)$(foreach repo,$(REPOS),make $(repo); git -C $(repo) pull; )

configure.%:
	$(TRACE)
	$(TARGET)
	$(ECHO) builddir=$(KALLEDIR) 
	$(CD) $(BUILDDIR)/$*; $(TOP)/$*/$(target) $(CONF_OPTION_$*)

rcs10.%: export KALLEDI=$(BUILDDIR)/rcs10
rcs10.%:
	$(TRACE)
	$(MAKE) $*

all.%:
	$(TRACE)
	$(TARGET)
	$(MAKE) configure.$*
	$(MAKE) -C $(BUILDDIR)/$* $(target)

install.%:
	$(TRACE)
	$(TARGET)
	$(MAKE) all.$*
	$(SUDOMAKE) -C $(BUILDDIR)/$* $(target)

uninstall.%:
	$(TRACE)
	$(TARGET)
	$(SUDOMAKE) -C $(BUILDDIR)/$* $(target)

distclean.%:
	$(TRACE)
	$(TARGET)
	$(Q)if [ -e $(BUILDDIR)/$*/Makefile ]; then \
		make uninstall.$*; \
		make -C $(BUILDDIR)/$* $(target); \
		rm -rf $(BUILDDIR)/$*/*; \
	else \
		echo $(target) not configured; \
	fi

clean.% TAGS.% CTAGS.% distclean-tags.%:
	$(TRACE)
	$(TARGET)
	$(Q)if [ -e $(BUILDDIR)/$*/Makefile ]; then \
		make -C $(BUILDDIR)/$* $(target); \
	else \
		echo $(target) not configured; \
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

DISTCLEAN.%:
	$(TRACE)
	$(RM) -r $*
	$(RM) -r $(BUILDDIR)

all configure install distclean uninstall clean TAGS CTAGS DISTCLEAN distclean-tags:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo); )

ALL: install

include rcs.mk
