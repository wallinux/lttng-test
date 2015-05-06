
SHELL=/bin/bash

# Define V=1 to echo everything
ifneq ($(V),1)
Q=@
endif

MAKE	= $(Q)make

vpath % .stamps
MKSTAMP = $(Q)mkdir -p .stamps ; touch .stamps/$@
RMSTAMP = $(Q)mkdir -p .stamps ; rm .stamps/$(1)

REPOS	= userspace-rcu lttng-ust lttng-tools babeltrace

define run-git-create
        cd $(1); \
	git rev-parse --verify rcs; \
	if [ $$? != 0 ]; then \
		git checkout -b rcs $(2); \
	fi
endef

help:
	$(Q)grep -e ": " -e ":$$"  Makefile | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort

repo.fetch:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git fetch --prune; popd; )

repo.pull:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git pull; popd; )

rcs.create:
	$(Q)$(call run-git-create,babeltrace,v1.2.4)
	$(Q)$(call run-git-create,userspace-rcu,v0.7.13)
	$(Q)$(call run-git-create,lttng-tools,v2.5.4)
	$(Q)$(call run-git-create,lttng-ust,v2.5.3)

rcs.delete: latest.checkout
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git branch -D rcs; popd; )

rcs.checkout:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git checkout rcs; popd; )

latest.checkout:
	$(Q)$(foreach repo, $(REPOS), pushd $(repo); git checkout master; popd; )
	$(MAKE) repo.pull

bootstrap.%:
	$(eval target=$(subst .$*,,$@))
	$(Q)cd $*; ./$(target)
	$(MKSTAMP)

configure.%: bootstrap.%
	$(eval target=$(subst .$*,,$@))
	$(Q)cd $*; ./$(target)
	$(MKSTAMP)

bootstrap configure:
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo) ; )

all.% install.% uninstall.% clean.% distclean.% TAGS.% CTAGS.% distclean-tags.%:
	$(eval target=$(subst .$*,,$@))
	$(MAKE) -C $* $(target)

all install uninstall clean TAGS CTAGS distclean-tags:
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo) ; )

distclean:
	$(Q)$(foreach repo, $(REPOS), make $@.$(repo) ; )
	$(RM) -r .stamps

ALL:
	$(Q)$(foreach repo, $(REPOS), make bootstrap.$(repo) ; )
	$(Q)$(foreach repo, $(REPOS), make configure.$(repo) ;)
	$(Q)$(foreach repo, $(REPOS), make all.$(repo) ; )
	$(Q)$(foreach repo, $(REPOS), make install.$(repo) ; )

ALL.uninstall:
	$(Q)$(foreach repo, $(REPOS), make $*.$(repo) )

rcs: rcs.create
	$(MAKE) rcs.checkout
	$(MAKE) ALL
	$(MAKE) TAGS

latest: latest.checkout
	$(MAKE) ALL
	$(MAKE) TAGS
