DNS					?= 8.8.8.8
DOCKER_ID_USER		?= wallinux

DOCKER_DISTRO		?= ubuntu-20.04
DOCKER_IMAGE		?= lttng:latest
DOCKER_CONTAINER	?= lttng
DOCKER_HOSTNAME     ?= lttng.eprime.com

define run-docker-exec
	$(DOCKER) exec -u root $(1) $(DOCKER_CONTAINER) $(2)
endef

define run-docker-exec-user
	$(DOCKER) exec -u $(USER) $(1) $(DOCKER_CONTAINER) $(2)
endef

.PHONY: docker.*

################################################################
docker.all: docker.make
	$(TRACE)

docker.build: # Build docker image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig docker/
	$(DOCKER) build --pull  -f docker/Dockerfile.$(DOCKER_DISTRO) -t "lttng" docker
	$(MKSTAMP)

docker.prepare:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $(DOCKER_CONTAINER) $(DEVNULL)
	$(call run-docker-exec, , sh -c "echo $(host_timezone) > /etc/timezone" )
	$(call run-docker-exec, , ln -sfn /usr/share/zoneinfo/$(host_timezone) /etc/localtime )
	$(call run-docker-exec, , dpkg-reconfigure -f noninteractive tzdata 2> /dev/null)
	$(MAKE) docker.stop

docker.create: docker.build
	$(TRACE)
	$(DOCKER) create -P --name=$(DOCKER_CONTAINER) \
		-h $(DOCKER_HOSTNAME) \
		--dns=$(DNS) \
		--privileged \
		-v $(TOP):/root/$(shell basename $(TOP)) \
		-i $(DOCKER_IMAGE) $(DEVNULL)
	$(MAKE) docker.prepare
	$(MKSTAMP)

docker.start: docker.create # Start docker container
	$(TRACE)
	$(DOCKER) start $(DOCKER_CONTAINER) $(DEVNULL)
	$(ECHO) "$(DOCKER_CONTAINER) container started"

docker.stop: # Stop docker container
	$(TRACE)
	-$(DOCKER) stop -t 2 $(DOCKER_CONTAINER) $(DEVNULL)

docker.rm: docker.stop # Remove docker container
	$(TRACE)
	-$(DOCKER) rm $(DOCKER_CONTAINER) $(DEVNULL)
	$(call rmstamp,docker.create)

docker.rmi: # Remove docker image
	$(TRACE)
	-$(DOCKER) rmi $(DOCKER_IMAGE) $(DEVNULL)
	$(call rmstamp,docker.build)

docker.useradd: | docker.start
	$(TRACE)
	$(call run-docker-exec, , sh -c "useradd --shell /bin/bash -d /home/$(USER) -m $(USER) -g tracing" )
	$(MKSTAMP)

docker.usershell: docker.start | docker.useradd
	$(TRACE)
	$(call run-docker-exec-user, -it, "/bin/bash")

docker.shell: docker.start # Start a shell in docker container
	$(TRACE)
	$(call run-docker-exec, -it, "/bin/bash")

docker.make: docker.preparemake
	$(TRACE)
	$(call run-docker-exec, -it, sh -c "make -C docker-test install")

docker.clean: # delete docker container and image
	$(TRACE)
	-$(MAKE) docker.rm
	-$(MAKE) docker.rmi

docker.distclean: docker.clean
	$(TRACE)

docker.help:
	$(TRACE)
	$(call run-help, docker.mk)
	$(call run-note, "- DOCKER_DISTRO = $(DOCKER_DISTRO)")

################################################################

help:: docker.help
