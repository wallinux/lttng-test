############################################################################
branch	 ?= rcsmaster

rcs10_userspace-rcu=v0.9.7
rcs10_lttng-ust=v2.10.7
rcs10_lttng-tools=v2.10.11
rcs10_babeltrace=v1.5.8
branches += rcs10

rcs12_userspace-rcu=v0.12.2
rcs12_lttng-ust=v2.12.2
rcs12_lttng-tools=v2.12.5
rcs12_babeltrace=v2.0.4
branches += rcs12

rcs13_userspace-rcu=v0.13.0
rcs13_lttng-ust=v2.13.0
rcs13_lttng-tools=v2.13.0
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

stable-2.13_userspace-rcu=origin/stable-0.13
stable-2.13_lttng-ust=origin/stable-2.13
stable-2.13_lttng-tools=origin/stable-2.13
stable-2.13_babeltrace=origin/stable-2.0
branches += stable-2.13

############################################################################
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

rcs10 rcs12 rcs13 rcsmaster stable-2.10 stable-2.12 stable-2.13: # build and install branch
	$(TRACE)
	$(MAKE) update
	$(MAKE) $@.patch_worktree
	$(MAKE) $@.install

env: # create env file
	$(TRACE)
	$(Q)$(foreach branch, $(branches), make env.$(branch); )

ALL: # build and install all branches
	$(TRACE)
	$(Q)$(foreach branch, $(branches), make $(branch); )

.PHONY: ALL env

branches.help:
	$(call run-help, branches.mk)
	$(call run-note, "- branch   = $(branch)")
	$(call run-note, "- branches = $(branches)")

help:: branches.help


