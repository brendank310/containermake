CONTAINER_CLI?=docker
CONTAINERS?= \
	hello-world \
	goodnight-moon
DESTDIR?=out
STAGEDIR?=stage
DOCKER_PATH?=images
REGISTRY_PATH?=blah
REGISTRY?=registry.dummy.io
TAG?=latest

# CONTAINER_METADATA_template is a template that mimics the following heredoc:
# ```
# cat > ${IMAGE}-image-metadata.json << EndOfFile
# {
#   "os": "linux",
#   "build_tag": "${TAG}",
#   "repository_name": "sericon/${IMAGE}",
#   "registry": "${REGISTRY}"
# }
# EndOfFile
# ```
define CONTAINER_METADATA_template
{\n  "os": "linux",\n  "build_tag": "$(4)",\n  "repository_name": "$(5)/$(1)",\n  "registry": "$$(REGISTRY)"\n}
endef

$(DESTDIR)/$(DOCKER_PATH):
	mkdir -p $(DESTDIR)/$(DOCKER_PATH)

define CONTAINER_BUILD_template =
.containermake/$(3)/$(5)/$(1):
	mkdir -p .containermake/$(3)/$(5)/$(1)

$(2)/$(1)/Dockerfile: .containermake/$(3)/$(5)/$(1)

.containermake/$(3)/$(5)/$(1)/$(4): $(2)/$(1)/Dockerfile $$($(1)_deps)
	mkdir -p $$(DESTDIR)/$$(STAGEDIR)/$(1)
	$$(CONTAINER_CLI) build -t $$(REGISTRY)/$(5)/$(1):$(4) -f $(2)/$(1)/Dockerfile $$(DESTDIR)/$$(STAGEDIR)/$(1)/
	touch .containermake/$(3)/$(5)/$(1)/$(4)

container-$(1): .containermake/$(3)/$(5)/$(1)/$(4) $$(DESTDIR)/$$(STAGEDIR)/$(1)
	@echo "Built container $(1)"

push-$(1): .containermake/$(3)/$(5)/$(1)/$(4)
	$$(CONTAINER_CLI) push $$(REGISTRY)/$(5)/$(1):$(4)

$$(DESTDIR)/$$(DOCKER_PATH)/$(1)-image.tar: $(DESTDIR)/$(DOCKER_PATH) .containermake/$(3)/$(5)/$(1)/$(4)
	$$(CONTAINER_CLI) save -o $$(DESTDIR)/$$(DOCKER_PATH)/$(1)-image.tar $$(REGISTRY)/$(5)/$(1):$(4) || true

$$(DESTDIR)/$$(DOCKER_PATH)/$(1)-image-metadata.json: $(DESTDIR)/$(DOCKER_PATH) .containermake/$(3)/$(5)/$(1)/$(4)
	@echo '$(CONTAINER_METADATA_template)' > $$(DESTDIR)/$$(DOCKER_PATH)/$(1)-image-metadata.json

metadata-save-$(1): $$(DESTDIR)/$$(DOCKER_PATH)/$(1)-image-metadata.json
	@echo "Saved $(1) metadata to $$(DESTDIR)"

save-$(1): $$(DESTDIR)/$$(DOCKER_PATH)/$(1)-image.tar
	@echo "Saved $(1) to $$(DESTDIR)."

.PHONY: clean-$(1)
clean-$(1): $$($(1)_cleanup)
	rm -rf .containermake/$(3)/$(1)
	rm $$(DESTDIR)/$(1)-image-metadata.json
	rm $$(DESTDIR)/$(1)-image.tar
	docker rmi $$(REGISTRY)/$(5)/$(1):$(4) || true
endef

$(foreach container,$(CONTAINERS),$(eval $(call CONTAINER_BUILD_template,$(container),$(DOCKER_PATH),$(REGISTRY),$(TAG),$(REGISTRY_PATH))))

container-clean: $(foreach container,$(CONTAINERS),clean-$(container))
	rm -rf .containermake

container-all: $(foreach container,$(CONTAINERS),container-$(container))
	@echo "Built containers: $(CONTAINERS)"

container-push-all: $(container-push-all_deps) $(foreach container,$(CONTAINERS),push-$(container))
	@echo "Pushed containers: $(CONTAINERS)"

container-save-all: $(foreach container,$(CONTAINERS),save-$(container))
	@echo "Saved containers: $(CONTAINERS)"

container-metadata-save-all: $(foreach container,$(CONTAINERS),metadata-save-$(container))
	@echo "Saved containers' metadata: $(CONTAINERS)"
