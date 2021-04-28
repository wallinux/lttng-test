
define run-worktree-add
	echo -e "\n---- adding worktree/$(3) $(2)"; \
	git -C $(1) worktree add -b $(3) worktree/$(3) $(2); \
	if [ $$? -eq 0 ]; then \
	    mkdir -p $(BUILDDIR)/$(3)/$(1); \
	    cd $(1)/worktree/$(3); \
	    ./bootstrap; \
	fi
endef

define run-worktree-remove
	echo -e "\n---- removing worktree/$(2)"; \
	git -C $(1) worktree remove worktree/$(2) 2>/dev/null; \
	git -C $(1) branch -q -D $(2) 2>/dev/null; \
	rm -rf $(BUILDDIR)/$(2)/$(1)
endef

define run-checkout
	cd $(1); \
	git rev-parse --verify $(3) >/dev/null; \
	if [ $$? != 0 ]; then \
	    git checkout -b $(3) $(2); \
	    ./bootstrap; \
	else \
	    git checkout $(3); \
	fi; \
	mkdir -p $(BUILDDIR)/$(3)/$(1)

endef

branches += master

rcs10_liburcu=v0.9.7
rcs10_lttngust=v2.10.7
rcs10_lttngtools=v2.10.11
rcs10_babeltrace=v1.5.8
branches += rcs10

rcs12_liburcu=v0.12.2
rcs12_lttngust=v2.12.1
rcs12_lttngtools=v2.12.3
rcs12_babeltrace=v2.0.4
branches += rcs12

rcs13_liburcu=v0.12.2
rcs13_lttngust=v2.13.0-rc1
rcs13_lttngtools=v2.13.0-rc1
rcs13_babeltrace=v2.0.4
branches += rcs13

stable-2.10_liburcu=origin/stable-0.9
stable-2.10_lttngust=origin/stable-2.10
stable-2.10_lttngtools=origin/stable-2.10
stable-2.10_babeltrace=origin/stable-1.5
branches += stable-2.10

stable-2.12_liburcu=origin/stable-0.12
stable-2.12_lttngust=origin/stable-2.12
stable-2.12_lttngtools=origin/stable-2.12
stable-2.12_babeltrace=origin/stable-2.0
branches += stable-2.12

stable-2.13_liburcu=origin/stable-0.12
stable-2.13_lttngust=origin/stable-2.13
stable-2.13_lttngtools=origin/stable-2.13
stable-2.13_babeltrace=origin/stable-2.0
branches += stable-2.13

rcs10.%: export branch=rcs10
rcs10.%:
	$(TRACE)
	$(MAKE) $*

rcs12.%: export branch=rcs12
rcs12.%:
	$(TRACE)
	$(MAKE) $*

rcs13.%: export branch=rcs13
rcs13.%:
	$(TRACE)
	$(MAKE) $*

stable-2.10.add stable-2.12.add stable-2.13.add rcs10.add rcs12.add rcs13.add:
	$(TRACE)
	$(Q)$(call run-worktree-add,userspace-rcu,$($(branch)_liburcu),$(branch))
	$(Q)$(call run-worktree-add,lttng-ust,$($(branch)_lttngust),$(branch))
	$(Q)$(call run-worktree-add,lttng-tools,$($(branch)_lttngtools),$(branch))
	$(Q)$(call run-worktree-add,babeltrace,$($(branch)_babeltrace),$(branch))

stable-2.10.patch stable-2.12.patch stable-2.13.patch rcs10.patch rcs12.patch rcs13.patch:
	$(TRACE)
	$(MAKE) $(branch).add
	$(PATCH) userspace-rcu $($(branch)_liburcu) $(branch)
	$(PATCH) lttng-ust $($(branch)_lttngust) $(branch)
	$(PATCH) lttng-tools $($(branch)_lttngtools) $(branch)
	$(PATCH) babeltrace $($(branch)_babeltrace) $(branch)
	$(MAKE) V=0 $(branch).bls

stable-2.10.remove stable-2.12.remove stable-2.13.remove rcs10.remove rcs12.remove rcs13.remove:
	$(TRACE)
	$(Q)$(call run-worktree-remove,userspace-rcu,$(branch))
	$(Q)$(call run-worktree-remove,lttng-ust,$(branch))
	$(Q)$(call run-worktree-remove,lttng-tools,$(branch))
	$(Q)$(call run-worktree-remove,babeltrace,$(branch))

stable-2.10.bls stable-2.12.bls stable-2.13.bls rcs10.bls rcs12.bls rcs13.bls:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		echo -e "\n--- $(repo) ---"; \
		git -C $(repo) branch | grep $(branch); \
		git -C $(repo) log $(branch) -1 --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative; \
		git -C $(repo) describe --abbrev=0 --tags $(branch); \
	)


#########################################################
# FIXME - mv master to the same as the other branches

master.patch master.add:
	$(TRACE)
	$(Q)$(call run-checkout,userspace-rcu,origin/master,master)
	$(Q)$(call run-checkout,lttng-ust,origin/master,master)
	$(Q)$(call run-checkout,lttng-tools,origin/master,master)
	$(Q)$(call run-checkout,babeltrace,origin/master,master)
	$(MAKE) repo.pull master.bls

master.bls:
	$(TRACE)
	$(Q)$(foreach repo, $(REPOS), \
		echo -e "\n--- $(repo) ---"; \
		git -C $(repo) branch | grep \*; \
		git -C $(repo) log -1 --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative; \
		git -C $(repo) describe --abbrev=0 --tags; \
	)

master.remove:
	$(TRACE)
	$(RM) -r $(BUILDDIR)/master/*
#########################################################

help::
	$(GREEN)
	$(Q)grep -e ": " -e ":$$"  rcs.mk | grep -v grep | cut -d ':' -f 1 | tr ' ' '\n' | sort
	$(NORMAL)

add patch bls remove:
	$(TRACE)
	$(Q)$(foreach branch, $(branches), make $(branch).$@; )
