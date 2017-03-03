SHELL=/bin/bash

# Define V=1 to echo everything
ifneq ($(V),1)
Q=@
endif

RM	= $(Q)rm -f
MAKE	= $(Q)make
ECHO 	= $(Q)echo
RED 	= $(Q)tput setaf 1
GREEN 	= $(Q)tput setaf 2
NORMAL 	= $(Q)tput sgr0
TRACE 	= $(Q)tput setaf 1; echo ------ $@; tput sgr0

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
	git rev-parse --verify $(3) >/dev/null; \
	if [ $$? != 0 ]; then \
		git checkout -b $(3) $(2); \
	else \
		git checkout $(3); \
	fi
endef

help:
	$(TRACE)
	$(GREEN)
	$(Q)grep -e ": " -e ":$$"  Makefile | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort
	$(NORMAL)

repo.clone:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), git clone $(REPO_$(repo)); )

repo.fetch:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		pushd $(repo)>/dev/null; \
		git fetch --prune; \
		popd >/dev/null; \
	)

repo.pull:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		pushd $(repo) >/dev/null; \
		git pull; \
		popd >/dev/null; \
	)

repo.latest_tag:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		pushd $(repo) >/dev/null; \
		basename $$PWD; \
		git describe --abbrev=0 --tags; \
		popd >/dev/null; \
	)

repo.bls:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		pushd $(repo) >/dev/null; \
		echo -e "\n--- $(repo) ---"; \
		git branch | grep \*; \
		git log -1 --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative; \
		git describe --abbrev=0 --tags; \
		popd >/dev/null; \
	)


rcs.delete: master.checkout
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git branch -D rcs; popd >/dev/null; )

rcs.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,v0.9.3,rcs )
	$(Q)$(call run-create,lttng-ust,v2.8.2,rcs )
	$(Q)$(call run-create,lttng-tools,v2.8.6,rcs )
	$(Q)$(call run-create,babeltrace,v1.5.1,rcs )

stable-2.7.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.7,stable-2.7 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.7,stable-2.7 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls

stable-2.8.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.8,stable-2.8 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.8,stable-2.8 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls

stable-2.9.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.9,stable-2.9 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.9,stable-2.9 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls

master.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/master,master )
	$(Q)$(call run-create,lttng-ust,origin/master,master )
	$(Q)$(call run-create,lttng-tools,origin/master,master )
	$(Q)$(call run-create,babeltrace,origin/master,master )
	$(MAKE) repo.pull repo.bls

bootstrap.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(Q)cd $*; ./$(target)

configure.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(MAKE) bootstrap.$*
	$(Q)cd $*; ./$(target)
	$(MKSTAMP)

all.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(MAKE) configure.$*
	$(MAKE) -C $* $(target)

install.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(MAKE) all.$*
	$(MAKE) -C $* $(target)

uninstall.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e .stamps/install.$* ]; then \
		rm .stamps/install.$*; \
		make -C $* $(target); \
	else \
		echo $(target) not installed; \
	fi

distclean.%:
	$(TRACE)
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
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e .stamps/configure.$* ]; then \
		make -C $* $(target); \
	else \
		echo $(target) not configured; \
	fi

ALL.userspace-rcu: install.userspace-rcu
	$(TRACE)

ALL.lttng-ust: ALL.userspace-rcu
	$(TRACE)
	$(MAKE) install.lttng-ust

ALL.lttng-tools: ALL.lttng-ust
	$(TRACE)
	$(MAKE) install.lttng-tools

ALL.babeltrace: ALL.userspace-rcu
	$(TRACE)
	$(MAKE) install.babeltrace

ALL all bootstrap configure install distclean uninstall clean TAGS CTAGS distclean-tags:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo); )

DISTCLEAN:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), rm -rf $(repo); )

rcs: rcs.checkout
	$(TRACE)
	$(MAKE) ALL

master: master.checkout
	$(TRACE)
	$(MAKE) ALL
