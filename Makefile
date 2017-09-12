SHELL=/bin/bash

UID = $(shell id -u)
TOP = $(shell pwd)

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
ifneq ($(UID),0)
SUDOMAKE= $(Q)sudo make
else
SUDOMAKE= $(MAKE)
endif

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

CONF_PREFIX			?= --prefix=/usr
CONF_OPTION_userspace-rcu 	?= $(CONF_PREFIX)
CONF_OPTION_lttng-ust 		?= $(CONF_PREFIX) --disable-man-pages
CONF_OPTION_lttng-tools 	?= $(CONF_PREFIX) --disable-man-pages
CONF_OPTION_babeltrace 		?= $(CONF_PREFIX)

define run-create
	cd $(1); \
	git rev-parse --verify $(3) >/dev/null; \
	if [ $$? != 0 ]; then \
		git checkout -b $(3) $(2); \
	else \
		git checkout $(3); \
	fi
endef

define rcs-patch
	echo -e "\nPatching $(1)"; \
	cd $(1); \
	git reset --hard $(2) >/dev/null; \
	for file in $$(cat $(TOP)/patches/$(1)/patches); do \
		git am -3 $(TOP)/patches/$(1)/$$file; \
	done; \
	git tag -f v_rcs >/dev/null;
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

LIBURCU_VER=v0.9.4
LTTNGUST_VER=v2.8.4
LTTNGTOOLS_VER=v2.8.8
BABELTRACE_VER=v1.5.3

rcs.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,$(LIBURCU_VER),rcs )
	$(Q)$(call run-create,lttng-ust,$(LTTNGUST_VER),rcs )
	$(Q)$(call run-create,lttng-tools,$(LTTNGTOOLS_VER),rcs )
	$(Q)$(call run-create,babeltrace,$(BABELTRACE_VER),rcs )

rcs.patch: rcs.checkout
	$(TRACE)
	$(Q)$(call rcs-patch,userspace-rcu,$(LIBURCU_VER),rcs )
	$(Q)$(call rcs-patch,lttng-ust,$(LTTNGUST_VER),rcs )
	$(Q)$(call rcs-patch,lttng-tools,$(LTTNGTOOLS_VER),rcs )
	$(Q)$(call rcs-patch,babeltrace,$(BABELTRACE_VER),rcs )

rcs.clean:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		cd $(repo); \
		git checkout master; \
		git branch -D rcs; \
		cd ..; \
	)
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

stable-2.10.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.10,stable-0.10 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.10,stable-2.10 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.10,stable-2.10 )
	$(Q)$(call run-create,babeltrace,origin/stable-2.0,stable-2.0 )
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
	$(Q)cd $*; ./$(target) $(CONF_OPTION_$*)
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
	$(SUDOMAKE) -C $* $(target)

uninstall.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(SUDOMAKE) -C $* $(target)

distclean.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e .stamps/configure.$* ]; then \
		make uninstall.$*; \
		make -C $* $(target); \
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

DISTCLEAN.%:
	$(TRACE)
	$(RM) -r $*

all bootstrap configure install distclean uninstall clean TAGS CTAGS DISTCLEAN distclean-tags:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo); )

ALL: install
