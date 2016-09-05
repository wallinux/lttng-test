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
REPO_lttng-modules = git://git.lttng.org/lttng-modules.git/

#EXTRA_REPOS	?= lttngtop lttng-modules
EXTRA_REPOS	?=
REPOS		= userspace-rcu lttng-ust lttng-tools babeltrace $(EXTRA_REPOS)

define run-create
	cd $(1); \
	git rev-parse --verify $(3); \
	if [ $$? != 0 ]; then \
		git checkout -b $(3) $(2); \
	fi
endef

help:
	$(Q)grep -e ": " -e ":$$"  Makefile | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort

repo.clone:
	$(Q)$(foreach repo, $(REPOS), git clone $(REPO_$(repo)); )

repo.fetch:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git fetch --prune; popd >/dev/null; )

repo.pull:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git pull; popd >/dev/null; )

repo.latest_tag:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo) >/dev/null; basename $$PWD; git describe --abbrev=0 --tags; popd >/dev/null; )

repo.bls:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git branch | grep \*; \
		git log -1 --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative; \
		popd >/dev/null; )


rcs.delete: latest.checkout
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git branch -D rcs; popd >/dev/null; )
	$(RM) .stamps/rcs.create

rcs.checkout: rcs.create
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git checkout rcs; popd >/dev/null; )
	$(RM) .stamps/*.checkout
	$(MKSTAMP)

rcs.create:
	$(Q)$(call run-create,userspace-rcu,v0.9.1,rcs)
	$(Q)$(call run-create,lttng-ust,v2.7.1,rcs)
	$(Q)$(call run-create,lttng-tools,v2.7.0,rcs)
	$(Q)$(call run-create,babeltrace,v1.3.1,rcs)
	$(MKSTAMP)

latest.checkout:
	$(Q)if [ -e .stamps/rcs.checkout ]; then \
		make distclean; \
	fi
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git checkout master; popd >/dev/null; )
	$(MAKE) repo.pull
	$(RM) .stamps/*.checkout
	$(MKSTAMP)

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
