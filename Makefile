SHELL=/bin/bash

UID = $(shell id -u)
TOP = $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
Q=@
endif

RM	= $(Q)rm -f
MAKE	= $(Q)make
MKDIR	= $(Q)mkdir -p
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

STAMPDIR = $(TOP)/.stamps
vpath % $(STAMPDIR)
MKSTAMP = $(Q)mkdir -p $(STAMPDIR) ; touch $(STAMPDIR)/$@

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
CONF_OPTION_lttng-tools 	?= $(CONF_PREFIX) --with-lttng-ust --enable-manpages --enable-embedded-help
CONF_OPTION_babeltrace 		?= $(CONF_PREFIX)

BUILDDIR	= $(TOP)/build

define create-builddir
	$(foreach repo,$(REPOS), mkdir -p $(BUILDDIR)/$(1)/$(repo); \
				  ln -sfn $(1)/$(repo) $(BUILDDIR)/$(repo); )
endef

define run-create
	cd $(1); \
	git rev-parse --verify $(3) >/dev/null; \
	if [ $$? != 0 ]; then \
		git checkout -b $(3) $(2); \
	else \
		git checkout $(3); \
	fi; \
	./bootstrap
endef

define rcs-patch
	echo -e "\nPatching $(1)"; \
	cd $(1); \
	git reset --hard $(2) >/dev/null; \
	for file in $$(grep -v "^#" $(TOP)/patches/$(1)/patches | grep . ); do \
		echo -e "\n --- $$file ---"; \
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

LIBURCU_VER=v0.9.6
LTTNGUST_VER=v2.10.4
LTTNGTOOLS_VER=v2.10.7
BABELTRACE_VER=v1.5.6

rcs.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,$(LIBURCU_VER),rcs )
	$(Q)$(call run-create,lttng-ust,$(LTTNGUST_VER),rcs )
	$(Q)$(call run-create,lttng-tools,$(LTTNGTOOLS_VER),rcs )
	$(Q)$(call run-create,babeltrace,$(BABELTRACE_VER),rcs )
	$(Q)$(call create-builddir,rcs)

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
	$(Q)$(call create-builddir,stable-2.7)

stable-2.8.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.8,stable-2.8 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.8,stable-2.8 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,stable-2.8)

stable-2.9.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.9,stable-2.9 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.9,stable-2.9 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,stable-2.9)

stable-2.10.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.10,stable-2.10 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.10,stable-2.10 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,stable-2.10)

stable-2.11.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.11,stable-2.11 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.11,stable-2.11 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,stable-2.11)

master.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/master,master )
	$(Q)$(call run-create,lttng-ust,origin/master,master )
	$(Q)$(call run-create,lttng-tools,origin/master,master )
	$(Q)$(call run-create,babeltrace,origin/master,master )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,master)

configure.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(Q)cd $(BUILDDIR)/$*; $(TOP)/$*/$(target) $(CONF_OPTION_$*)

all.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(MAKE) configure.$*
	$(MAKE) -C $(BUILDDIR)/$* $(target)

install.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(MAKE) all.$*
	$(SUDOMAKE) -C $(BUILDDIR)/$* $(target)

uninstall.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(SUDOMAKE) -C $(BUILDDIR)/$* $(target)

distclean.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e $(BUILDDIR)/$*/Makefile ]; then \
		make uninstall.$*; \
		make -C $(BUILDDIR)/$* $(target); \
		rm -rf $(BUILDDIR)/$*/*; \
	else \
		echo $(target) not configured; \
	fi

clean.% TAGS.% CTAGS.% distclean-tags.%:
	$(TRACE)
	$(eval target=$(subst .$*,,$@))
	$(Q)if [ -e $(BUILDDIR)/$*/Makefile ]; then \
		make -C $(BUILDDIR)/$* $(target); \
	else \
		echo $(target) not configured; \
	fi

DISTCLEAN.%:
	$(TRACE)
	$(RM) -r $*
	$(RM) -r $(BUILDDIR)

all configure install distclean uninstall clean TAGS CTAGS DISTCLEAN distclean-tags:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo); )

ALL: install
