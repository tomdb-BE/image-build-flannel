SEVERITIES = HIGH,CRITICAL

ifeq ($(ARCH),)
ARCH=$(shell go env GOARCH)
endif

BUILD_META=-multiarch-build$(shell date +%Y%m%d)
ORG ?= rancher
PKG ?= github.com/flannel-io/flannel
SRC ?= github.com/flannel-io/flannel
TAG ?= v0.14.0$(BUILD_META)
UBI_IMAGE ?= centos:7
GOLANG_VERSION ?= v1.16.6b7-multiarch
K3S_ROOT_VERSION ?= v0.9.1

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG needs to end with build metadata: $(BUILD_META))
endif

.PHONY: image-build
image-build:
	docker build \
		--pull \
		--build-arg ARCH=$(ARCH) \
		--build-arg PKG=$(PKG) \
		--build-arg SRC=$(SRC) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
                --build-arg GO_IMAGE=$(ORG)/hardened-build-base:$(GOLANG_VERSION) \
                --build-arg UBI_IMAGE=$(UBI_IMAGE) \
                --build-arg K3S_ROOT_VERSION=$(K3S_ROOT_VERSION) \
		--tag $(ORG)/hardened-flannel:$(TAG) \
		--tag $(ORG)/hardened-flannel:$(TAG)-$(ARCH) \
	.

.PHONY: image-push
image-push:
	docker push $(ORG)/hardened-flannel:$(TAG)-$(ARCH)

.PHONY: image-manifest
image-manifest:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-flannel:$(TAG) \
		$(ORG)/hardened-flannel:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-flannel:$(TAG)

.PHONY: image-scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-flannel:$(TAG)
