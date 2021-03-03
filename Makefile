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
PATCH	= $(Q)$(TOP)/patch-lttng

STAMPDIR = $(TOP)/.stamps
vpath % $(STAMPDIR)
MKSTAMP = $(Q)mkdir -p $(STAMPDIR) ; touch $(STAMPDIR)/$@

REPO_userspace-rcu = git://git.liburcu.org/userspace-rcu.git
REPO_lttng-ust     = git://git.lttng.org/lttng-ust.git
REPO_lttng-tools   = git://git.lttng.org/lttng-tools.git
REPO_babeltrace    = https://git.efficios.com/babeltrace.git
REPO_lttngtop	   = git://git.lttng.org/lttngtop.git
REPO_lttng-modules = git://git.lttng.org/lttng-modules.git/

#EXTRA_REPOS	?= lttng-modules
REPOS		+= userspace-rcu
REPOS		+= lttng-ust
REPOS		+= lttng-tools
REPOS		+= babeltrace
REPOS		+= $(EXTRA_REPOS)

CONF_PREFIX			?= --prefix=/usr
CONF_OPTION_userspace-rcu 	?= $(CONF_PREFIX)
CONF_OPTION_lttng-ust 		?= $(CONF_PREFIX) --disable-man-pages
CONF_OPTION_lttng-tools 	?= $(CONF_PREFIX) --with-lttng-ust --enable-man-pages --enable-embedded-help
CONF_OPTION_babeltrace 		?= $(CONF_PREFIX)

BUILDDIR	= $(TOP)/build

TARGET=$(eval target=$(subst .$*,,$@))

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

help:
	$(TRACE)
	$(GREEN)
	$(Q)grep -e ": " -e ":$$"  Makefile | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort
	$(NORMAL)

$(REPOS):
	$(Q)git clone $(REPO_$@)

repo.fetch:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS),make $(repo); git -C $(repo) fetch --prune; )

repo.pull:
	$(TRACE)
	$(Q)$(foreach repo,$(REPOS),make $(repo); git -C $(repo) pull; )

repo.bls:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		echo -e "\n--- $(repo) ---"; \
		git -C $(repo) branch | grep \*; \
		git -C $(repo) log -1 --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative; \
		git -C $(repo) describe --abbrev=0 --tags; \
	)

RCS_LIBURCU_VER=v0.9.7
RCS_LTTNGUST_VER=v2.10.7
RCS_LTTNGTOOLS_VER=v2.10.11
RCS_BABELTRACE_VER=v1.5.8
rcs.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,$(RCS_LIBURCU_VER),rcs)
	$(Q)$(call run-create,lttng-ust,$(RCS_LTTNGUST_VER),rcs)
	$(Q)$(call run-create,lttng-tools,$(RCS_LTTNGTOOLS_VER),rcs)
	$(Q)$(call run-create,babeltrace,$(RCS_BABELTRACE_VER),rcs)
	$(Q)$(call create-builddir,rcs)

rcs.patch: rcs.checkout
	$(TRACE)
	$(PATCH) userspace-rcu $(RCS_LIBURCU_VER) rcs
	$(PATCH) lttng-ust $(RCS_LTTNGUST_VER) rcs
	$(PATCH) lttng-tools $(RCS_LTTNGTOOLS_VER) rcs 
	$(PATCH) babeltrace $(RCS_BABELTRACE_VER) rcs 
	$(MAKE) repo.bls

RCS12_LIBURCU_VER=v0.12.1
RCS12_LTTNGUST_VER=v2.12.0
RCS12_LTTNGTOOLS_VER=v2.12.2
RCS12_BABELTRACE_VER=v2.0.3
rcs12.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,$(RCS12_LIBURCU_VER),rcs12)
	$(Q)$(call run-create,lttng-ust,$(RCS12_LTTNGUST_VER),rcs12)
	$(Q)$(call run-create,lttng-tools,$(RCS12_LTTNGTOOLS_VER),rcs12)
	$(Q)$(call run-create,babeltrace,$(RCS12_BABELTRACE_VER),rcs12)
	$(Q)$(call create-builddir,rcs12)

rcs12.patch: rcs12.checkout
	$(TRACE)
	$(PATCH) userspace-rcu $(RCS12_LIBURCU_VER) rcs12
	$(PATCH) lttng-ust $(RCS12_LTTNGUST_VER) rcs12
	$(PATCH) lttng-tools $(RCS12_LTTNGTOOLS_VER) rcs12
	$(PATCH) babeltrace $(RCS12_BABELTRACE_VER) rcs12
	$(MAKE) repo.bls

rcsmaster.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/master,rcsmaster)
	$(Q)$(call run-create,lttng-ust,origin/master,rcsmaster)
	$(Q)$(call run-create,lttng-tools,origin/master,rcsmaster)
	$(Q)$(call run-create,babeltrace,origin/master,rcsmaster)
	$(Q)$(call create-builddir,rcsmaster)

rcsmaster.patch: rcsmaster.checkout
	$(TRACE)
	$(PATCH) userspace-rcu master rcsmaster
	$(PATCH) lttng-ust master rcsmaster
	$(PATCH) lttng-tools master rcsmaster
	$(PATCH) babeltrace master rcsmaster
	$(MAKE) repo.bls

rcsmaster.clean rcs12.clean rcs.clean:
	$(TRACE)
	$(eval prefix=$(subst .clean,,$@))
	$(Q)$(foreach repo, $(REPOS), \
		git -C $(repo) checkout master; \
		git -C $(repo) branch -D $(prefix); )

stable-2.10.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.9,stable-0.9 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.10,stable-2.10 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.10,stable-2.10 )
	$(Q)$(call run-create,babeltrace,origin/stable-1.5,stable-1.5 )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,stable-2.10)

stable-2.10.patch: stable-2.10.checkout

stable-2.11.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.11,stable-0.11 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.11,stable-2.11 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.11,stable-2.11 )
	$(Q)$(call run-create,babeltrace,origin/stable-2.0,stable-2.0 )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,stable-2.11)

stable-2.11.patch: stable-2.11.checkout

stable-2.12.checkout:
	$(TRACE)
	$(Q)$(call run-create,userspace-rcu,origin/stable-0.12,stable-0.12 )
	$(Q)$(call run-create,lttng-ust,origin/stable-2.12,stable-2.12 )
	$(Q)$(call run-create,lttng-tools,origin/stable-2.12,stable-2.12 )
	$(Q)$(call run-create,babeltrace,origin/stable-2.0,stable-2.0 )
	$(MAKE) repo.pull repo.bls
	$(Q)$(call create-builddir,stable-2.12)

stable-2.12.patch: stable-2.12.checkout

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
	$(TARGET)
	$(CD) $(BUILDDIR)/$*; $(TOP)/$*/$(target) $(CONF_OPTION_$*)

all.%:
	$(TRACE)
	$(TARGET)
	$(MAKE) configure.$*
	$(MAKE) -C $(BUILDDIR)/$* $(target)

update: repo.pull
	$(TRACE)

install.%:
	$(TRACE)
	$(TARGET)
	$(MAKE) all.$*
	$(SUDOMAKE) -C $(BUILDDIR)/$* $(target)

fast_regression.lttng-tools root_regression.lttng-tools:
	$(TRACE)
	$(eval target=$(subst .lttng-tools,,$@))
	$(CD) $(BUILDDIR)/lttng-tools/tests/; ./run.sh $(target) |& tee $(target).out

userspace_regression.lttng-tools:
	$(TRACE)
	$(eval target=$(subst .lttng-tools,,$@))
	$(CD) $(BUILDDIR)/lttng-tools/tests/; ./run.sh $(TOP)/$(target) |& tee $(target).out

test.lttng-tools: userspace_regression.lttng-tools

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

DISTCLEAN.%:
	$(TRACE)
	$(RM) -r $*
	$(RM) -r $(BUILDDIR)

all configure install distclean uninstall clean TAGS CTAGS DISTCLEAN distclean-tags:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo); )

ALL: install
