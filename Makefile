SHELL=/bin/bash

# Define V=1 to echo everything
ifneq ($(V),1)
Q=@
endif

RM	= $(Q)rm -f
MAKE	= $(Q)make

vpath % .stamps
MKSTAMP = $(Q)mkdir -p .stamps ; touch .stamps/$@

REPO_userspace-rcu = git://git.liburcu.org/userspace-rcu.git
REPO_lttng-ust     = git://git.lttng.org/lttng-ust.git
REPO_lttng-tools   = git://git.lttng.org/lttng-tools.git
REPO_babeltrace    = http://git.linuxfoundation.org/diamon/babeltrace.git
REPO_lttngtop	   = git://git.lttng.org/lttngtop.git

REPOS	= userspace-rcu lttng-ust lttng-tools babeltrace
#REPOS	+= lttngtop

define run-git-create
	cd $(1); \
	git rev-parse --verify rcs; \
	if [ $$? != 0 ]; then \
		git checkout -b rcs $(2); \
	fi
endef

help:
	$(Q)grep -e ": " -e ":$$"  Makefile | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort

repo.clone:
	$(Q)$(foreach repo, $(REPOS), git clone $(REPO_$(repo)); )

repo.fetch:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git fetch --prune; popd; )

repo.pull:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git pull; popd; )

rcs.create:
	$(Q)$(call run-git-create,userspace-rcu,v0.7.14)
	$(Q)$(call run-git-create,lttng-ust,v2.5.5)
	$(Q)$(call run-git-create,lttng-tools,v2.5.4)
	$(Q)$(call run-git-create,babeltrace,v1.2.4)
	$(MKSTAMP)

rcs.delete: latest.checkout
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git branch -D rcs; popd; )
	$(RM) .stamps/rcs.create

rcs.checkout: rcs.create
	$(Q)if [ -e .stamps/latest.checkout ]; then \
		make distclean; \
	fi
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git checkout rcs; popd; )
	$(MKSTAMP)
	$(RM) .stamps/latest.checkout

latest.checkout:
	$(Q)if [ -e .stamps/rcs.checkout ]; then \
		make distclean; \
	fi
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git checkout master; popd; )
	$(MAKE) repo.pull
	$(MKSTAMP)
	$(RM) .stamps/rcs.checkout

bootstrap.%:
	$(eval target=$(subst .$*,,$@))
	$(Q)cd $*; ./$(target)
	$(MKSTAMP)

configure.%:
	$(eval target=$(subst .$*,,$@))
	$(MAKE) bootstrap.$*
	$(Q)cd $*; ./$(target)
	$(MKSTAMP)

all.%:
	$(eval target=$(subst .$*,,$@))
	$(MAKE) configure.$*
	$(MAKE) -C $* $(target)

install.%:
	$(eval target=$(subst .$*,,$@))
	$(MAKE) all.$*
	$(MAKE) -C $* $(target)
	$(MKSTAMP)

uninstall.%:
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e .stamps/install.$* ]; then \
		rm .stamps/install.$*; \
		make -C $* $(target); \
	else \
		echo $(target) not installed; \
	fi

distclean.%:
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e .stamps/configure.$* ]; then \
		make uninstall.$*; \
		make -C $* $(target); \
		rm .stamps/bootstrap.$*; \
		rm .stamps/configure.$*; \
	else \
		echo $(target) not configured; \
	fi

clean.% TAGS.% CTAGS.% distclean-tags.%:
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e .stamps/configure.$* ]; then \
		make -C $* $(target); \
	else \
		echo $(target) not configured; \
	fi

ALL.userspace-rcu: install.userspace-rcu

ALL.lttng-ust: ALL.userspace-rcu
	$(MAKE) install.lttng-ust

ALL.lttng-tools: ALL.lttng-ust
	$(MAKE) install.lttng-tools

ALL.babeltrace: ALL.userspace-rcu
	$(MAKE) install.babeltrace

ALL all bootstrap configure install distclean uninstall clean TAGS CTAGS distclean-tags:
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo); )

DISTCLEAN:
	$(Q)$(foreach repo, $(REPOS), rm -rf $(repo); )

rcs: rcs.checkout
	$(MAKE) ALL

latest: latest.checkout
	$(MAKE) ALL
