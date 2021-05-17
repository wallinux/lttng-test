
include common.mk

default: help

include docker.mk

REPO_userspace-rcu = git://git.liburcu.org/userspace-rcu.git
REPO_lttng-ust     = git://git.lttng.org/lttng-ust.git
REPO_lttng-tools   = git://git.lttng.org/lttng-tools.git
REPO_babeltrace    = https://git.efficios.com/babeltrace.git
REPO_lttng-modules = git://git.lttng.org/lttng-modules.git/

REPOS		+= userspace-rcu
REPOS		+= babeltrace
REPOS		+= lttng-ust
REPOS		+= lttng-tools
#REPOS		+= lttng-modules

CONF_PREFIX	?= --prefix=$(INSTALLDIR)/$(branch)/usr
FLAGS		+= CPPFLAGS=-I$(INSTALLDIR)/$(branch)/usr/include
FLAGS		+= LDFLAGS=-L$(INSTALLDIR)/$(branch)/usr/lib
FLAGS		+= PKG_CONFIG_PATH=$(INSTALLDIR)/$(branch)/usr/lib/pkgconfig

CONF_OPTION_userspace-rcu	?= $(CONF_PREFIX)
CONF_OPTION_lttng-ust		?= $(CONF_PREFIX) --disable-man-pages $(FLAGS)
CONF_OPTION_lttng-tools		?= $(CONF_PREFIX) --with-lttng-ust --enable-man-pages --enable-embedded-help $(FLAGS)
CONF_OPTION_babeltrace		?= $(CONF_PREFIX)

OUTDIR		= $(TOP)/out
SRCDIR		= $(OUTDIR)/src
BUILDDIR	= $(OUTDIR)/build/$(HOSTNAME)
INSTALLDIR	= $(OUTDIR)/install/$(HOSTNAME)

PATCH		= $(Q)$(TOP)/patch-lttng
TARGET		= $(eval target=$(subst .$*,,$@))

####################################################################################

define run-worktree-add
	echo -e "\n---- adding $(SRCDIR)/$(1)/worktree/$(3) $(2)"; \
	git -C $(SRCDIR)/$(1) worktree add -b $(3) worktree/$(3) $(2) 2>/dev/null; \
	if [ $$? -eq 0 ]; then \
	    mkdir -p $(BUILDDIR)/$(3)/$(1); \
	    (cd $(SRCDIR)/$(1)/worktree/$(3); ./bootstrap;) \
	fi
endef

define run-worktree-remove
	echo -e "\n---- removing worktree/$(2)"; \
	git -C $(SRCDIR)/$(1) worktree remove --force worktree/$(2) 2> /dev/null; \
	git -C $(SRCDIR)/$(1) branch -q -D $(2) 2> /dev/null; \
	rm -rf $(BUILDDIR)/$(2)/$(1)
endef

####################################################################################

$(SRCDIR):
	$(TRACE)
	$(MKDIR) $@

$(foreach repo,$(REPOS),$(SRCDIR)/$(repo) ): $(SRCDIR)
	$(TRACE)
	$(eval repo=$(notdir $@))
	$(IF) [ -d $@ ]; then \
		git -C $@ pull; \
	else \
		cd $<; \
		git clone -q $(REPO_$(repo)); \
	fi	

$(REPOS): # clone repos
	$(TRACE)
	$(MAKE) -B $(SRCDIR)/$@

update.%: # update repos
	$(TRACE)
	$(MAKE) $*

add_worktree.%:
	$(TRACE)
	$(Q)$(call run-worktree-add,$*,$($(branch)_$*),$(branch))

patch_worktree.%:
	$(TRACE)
	$(MAKE) add_worktree.$*
	$(PATCH) $* $($(branch)_$*) $(branch);

remove_worktree.%:
	$(TRACE)
	$(Q)$(call run-worktree-remove,$(*),$(branch))

bls.%:
	$(TRACE)
	$(eval srcdir=$(SRCDIR)/$*)
	$(ECHO) -e "\n--- $(branch) $* ---"; \
	if [ -d $(srcdir)/worktree/$(branch) ]; then \
		git -C $(srcdir) log $(branch) -1 --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative; \
		git -C $(srcdir) describe --abbrev=0 --tags $(branch); \
	fi

configure.%:
	$(TRACE)
	$(TARGET)
	$(MKDIR) $(BUILDDIR)/$(branch)/$*
	$(CD) $(BUILDDIR)/$(branch)/$*; $(SRCDIR)/$*/worktree/$(branch)/$(target) $(CONF_OPTION_$*)

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
	$(MAKE) env.$(branch)

check.%:
	$(TRACE)
	$(TARGET)
	$(MAKE) -C $(BUILDDIR)/$(branch)/$* $(target)

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

env.%:
	$(TRACE)
	$(ECHO) LD_LIBRARY_PATH=$(INSTALLDIR)/$*/usr/lib > $(OUTDIR)/$*.env
	$(ECHO) PATH=$(INSTALLDIR)/$*/usr/bin:$$PATH >> $(OUTDIR)/$*.env

#################################################################
# global

Makefile.help:
	$(call run-help, Makefile)
	$(call run-note, "- REPOS   = $(REPOS)")

help:: Makefile.help

DISTCLEAN:
	$(TRACE)
	$(SUDO) rm -f -r $(INSTALLDIR)
	$(RM) -r $(OUTDIR)

all configure unconfigure install distclean uninstall clean TAGS CTAGS distclean-tags update add_worktree remove_worktree patch_worktree bls check:
	$(TRACE)
	$(Q)$(foreach repo,$(REPOS),make $@.$(repo);)

.PHONY: help DISTCLEAN all configure unconfigure install distclean \
        uninstall clean TAGS CTAGS distclean-tags update \
	add_worktree remove_worktree patch_worktree bls check \
	$(REPOS)

include branches.mk
