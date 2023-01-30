CONTAINER_CLI?=docker
CONTAINERS?= \
	hello-world \
	goodnight-moon
DOCKER_PATH?=images
REGISTRY?=registry.dummy.io
TAG?=latest

define CONTAINER_BUILD_template =
.containermake/$(3)/$(1):
	mkdir -p .containermake/$(3)/$(1)

$(2)/$(1)/Dockerfile: .containermake/$(3)/$(1)

.containermake/$(3)/$(1)/$(4): $(2)/$(1)/Dockerfile
	$$(CONTAINER_CLI) build -t $(3)/$(1):$(4) -f $(2)/$(1)/Dockerfile $(2)/$(1)/
	touch .containermake/$(3)/$(1)/$(4)

container-$(1): .containermake/$(3)/$(1)/$(4)
	@echo "Built container $(1)"

push-$(1): container-$(1)
	$$(CONTAINER_CLI) push $(3)/$(1):$(4)

.PHONY: clean-$(1)
clean-$(1):
	rm -rf .containermake/$(3)/$(1)
	docker rmi $(3)/$(1):$(4) || true
endef

$(foreach container,$(CONTAINERS),$(eval $(call CONTAINER_BUILD_template,$(container),$(DOCKER_PATH),$(REGISTRY),$(TAG))))

container-clean: $(foreach container,$(CONTAINERS),clean-$(container))
	rm -rf .containermake

container-all: $(foreach container,$(CONTAINERS),container-$(container))
	@echo "Built containers: $(CONTAINERS)"
