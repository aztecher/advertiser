# Version information
include Makefile.version

SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := ${PROJECT_DIR}/build

# ENVTEST_K8S_VERSION refers to the version of kubebuilder assets to be downloaded by envtest binary.
ENVTEST_K8S_VERSION = 1.27.1

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

TARGET_OS ?= $(shell go env GOOS)
TARGET_ARCH ?= $(shell go env GOARCH)

# Options for go build command
GO_BUILD_OPTS ?= CGO_ENABLED=0 GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH)
# Linker flags for go build command
GO_LDFLAGS = $(VERSION_LDFLAGS)

PKGS = $(or $(PKG),$(shell cd $(PROJECT_DIR) && go list ./... | grep -v "^advertiser/vendor/" | grep -v ".*/mocks"))

.PHONY: all
all: build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: clean
clean: ## Remove downloaded tools and compiled binaries
	@rm -rf $(LOCALBIN)
	@rm -rf $(BUILD_DIR)

##@ Development

.PHONY: lint
lint: golangci-lint ## Lint code.
	$(GOLANGCILINT) run --timeout 10m

COVeRAGE_MODE = atomic
COVER_PROFILE = $(PROJECT_DIR)/cover.out
LCOV_PATH =  $(PROJECT_DIR)/lcov.info

.PHONY: unit-test
unit-test: ## Run tests.
	go test -covermode=$(COVERAGE_MODE) -coverprofile=$(COVER_PROFILE) $(PKGS)

.PHONY: test
test: lint unit-test integration-test

.PHONY: integration-test
integration-test: lint cnitool
	@pushd e2e && ./integration.sh && popd

.PHONY: cov-report
cov-report: gcov2lcov test  ## Build test coverage report in lcov format
	$(GCOV2LCOV) -infile $(COVER_PROFILE) -outfile $(LCOV_PATH)

##@ Build

.PHONY: build-cni
build-cni: ## build CNI
	$(GO_BUILD_OPTS) go build -ldflags $(GO_LDFLAGS) -o $(BUILD_DIR)/advertiser ./cmd/advertiser/main.go

.PHONY: build
build: build-cni ## Build project binaries


.PHONY: generate-mocks
generate-mocks: mockery ## generate mock objects
	PATH=$(LOCALBIN):$(PATH) go generate ./...

## Location to install dependencies to
LOCALBIN ?= $(PROJECT_DIR)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

##@ Tools

## Tool Binaries
GOLANGCILINT ?= $(LOCALBIN)/golangci-lint
GCOV2LCOV ?= $(LOCALBIN)/gcov2lcov
MOCKERY ?= $(LOCALBIN)/mockery
CNITOOL ?= $(LOCALBIN)/cnitool

## Tool Versions
GOLANGCILINT_VERSION ?= v1.52.2
GCOV2LCOV_VERSION ?= v1.0.5
MOCKERY_VERSION ?= v2.27.1
CNITOOL_VERSION ?= v1.1.2

.PHONY: golangci-lint
golangci-lint: $(GOLANGCILINT) ## Download golangci-lint locally if necessary.
$(GOLANGCILINT): | $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCILINT_VERSION)

.PHONY: gcov2lcov
gcov2lcov: $(GCOV2LCOV) ## Download gcov2lcov locally if necessary.
$(GCOV2LCOV): | $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install github.com/jandelgado/gcov2lcov@$(GCOV2LCOV_VERSION)

.PHONY: mockery
mockery: $(MOCKERY) ## Download mockery locally if necessary.
$(MOCKERY): | $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install github.com/vektra/mockery/v2@$(MOCKERY_VERSION)

.PHONY: cnitool
cnitool: | $(CNITOOL) ## Download cnitool locally if necessary.
$(CNITOOL): | $(CNITOOL)
	GOBIN=$(LOCALBIN) go install github.com/containernetworking/cni/cnitool@$(CNITOOL_VERSION)