
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

define run-checkout
	cd $(SRCDIR)/$(1); \
	git rev-parse --verify $(3) >/dev/null; \
	if [ $$? != 0 ]; then \
	    git checkout -b $(3) $(2); \
	    ./bootstrap; \
	else \
	    git checkout $(3); \
	fi; \
	mkdir -p $(BUILDDIR)/$(3)/$(1)

endef

PATCH	= $(TOP)/patch-lttng

############################################################################
branches += master

rcs10_userspace-rcu=v0.9.7
rcs10_lttng-ust=v2.10.7
rcs10_lttng-tools=v2.10.11
rcs10_babeltrace=v1.5.8
branches += rcs10

rcs12_userspace-rcu=v0.12.2
rcs12_lttng-ust=v2.12.1
rcs12_lttng-tools=v2.12.3
rcs12_babeltrace=v2.0.4
branches += rcs12

rcs13_userspace-rcu=v0.12.2
rcs13_lttng-ust=v2.13.0-rc1
rcs13_lttng-tools=v2.13.0-rc1
rcs13_babeltrace=v2.0.4
branches += rcs13

rcsmaster_userspace-rcu=origin/master
rcsmaster_lttng-ust=origin/master
rcsmaster_lttng-tools=origin/master
rcsmaster_babeltrace=origin/master
branches += rcsmaster

stable-2.10_userspace-rcu=origin/stable-0.9
stable-2.10_lttng-ust=origin/stable-2.10
stable-2.10_lttng-tools=origin/stable-2.10
stable-2.10_babeltrace=origin/stable-1.5
branches += stable-2.10

stable-2.12_userspace-rcu=origin/stable-0.12
stable-2.12_lttng-ust=origin/stable-2.12
stable-2.12_lttng-tools=origin/stable-2.12
stable-2.12_babeltrace=origin/stable-2.0
branches += stable-2.12

stable-2.13_userspace-rcu=origin/stable-0.12
stable-2.13_lttng-ust=origin/stable-2.13
stable-2.13_lttng-tools=origin/stable-2.13
stable-2.13_babeltrace=origin/stable-2.0
branches += stable-2.13

rcs10.%: export branch=rcs10
rcs12.%: export branch=rcs12
rcs13.%: export branch=rcs13
rcsmaster.%: export branch=rcsmaster
stable-2.10.%: export branch=stable-2.10
stable-2.12.%: export branch=stable-2.12
stable-2.13.%: export branch=stable-2.13

stable-2.10.% stable-2.12.% stable-2.13.% rcs10.% rcs12.% rcs13.% rcsmaster.%:
	$(TRACE)
	$(MAKE) $*

add_worktree.%:
	$(TRACE)
	$(Q)$(call run-worktree-add,$*,$($(branch)_$*),$(branch))

patch_worktree.%:
	$(TRACE)
	$(MAKE) add_worktree.$*
	$(Q)$(PATCH) $* $($(branch)_$*) $(branch);

remove_worktree.%:
	$(TRACE)
	$(Q)$(call run-worktree-remove,$(*),$(branch))

# to be removed
stable-2.10.add stable-2.12.add stable-2.13.add rcs10.add rcs12.add rcs13.add rcsmaster.add:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS),\
		$(call run-worktree-add,$(repo),$($(branch)_$(repo)),$(branch)); )

stable-2.10.patch stable-2.12.patch stable-2.13.patch rcs10.patch rcs12.patch rcs13.patch rcsmaster.patch:
	$(TRACE)
	$(MAKE) $(branch).add
	$(Q)$(foreach repo, $(REPOS),\
		$(PATCH) $(repo) $($(branch)_$(repo)) $(branch); )
	$(MAKE) V=0 $(branch).bls

stable-2.10.remove stable-2.12.remove stable-2.13.remove rcs10.remove rcs12.remove rcs13.remove rcsmaster.remove:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS),\
		$(call run-worktree-remove,$(repo),$(branch)); )

stable-2.10.bls stable-2.12.bls stable-2.13.bls rcs10.bls rcs12.bls rcs13.bls rcsmaster.bls:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		echo -e "\n--- $(repo) ---"; \
		if [ -d $(SRCDIR)/$(repo)/worktree/$(branch) ]; then \
			git -C $(SRCDIR)/$(repo) branch | grep $(branch); \
			git -C $(SRCDIR)/$(repo) log $(branch) -1 --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative; \
			git -C $(SRCDIR)/$(repo) describe --abbrev=0 --tags $(branch); \
		fi; \
	)
################################################

help::
	$(GREEN)
	$(Q)grep -e ": " -e ":$$"  rcs.mk | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort
	$(NORMAL)

add patch bls remove:
	$(TRACE)
	$(Q)$(foreach branch, $(branches), make $(branch).$@; )
