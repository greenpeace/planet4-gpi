SHELL := /bin/bash

MAINTAINER 				?= Raymond Walker <raymond.walker@greenpeace.org>

APP_VERSION				?= v0.6.0
BUILD_NAMESPACE 	?= gcr.io
GOOGLE_PROJECT_ID ?= planet-4-151612

GIT_SOURCE 				?= https://github.com/greenpeace/planet4-base

# The branch to checkout of GIT_SOURCE, eg:
# Use local branch name if not set
GIT_REF 					?= $(shell git rev-parse --abbrev-ref HEAD)

# Use current folder name as prefix for built containers,
# eg planet4-gpi-app planet4-gpi-openresty
CONTAINER_PREFIX  ?= $(shell basename $(shell pwd))

# Tag for built containers
# Use local tag if not set
BUILD_TAG 				?= $(shell git tag -l --points-at HEAD)

# If the current commit does not have a tag, or the variable is empty
ifeq ($(strip $(BUILD_TAG)),)
# Default to git tag on current commit
BUILD_TAG := $(GIT_REF)
endif

# GCS bucket to store built source
GS_BUCKET 				:= $(CONTAINER_PREFIX)-source
GS_PATH 					?= $(BUILD_TAG)

# If for any reason GS_PATH is empty, we don't want to overwrite other namespaces
ifeq ($(strip $(GS_PATH)),)
GS_PATH := testing
endif

################################################################################

.PHONY: clean test bake build build-app build-openresty pull push save

all: clean test bake build push save

test:
		@echo "Building $(CONTAINER_PREFIX) containers"
	  @echo "BUILD_TAG: $(BUILD_TAG)"
	  @echo "GIT_REF: $(GIT_REF)"

clean:
		rm -fr source
		docker-compose -p build down -v
		# docker rmi p4-build --force

bake:
		mkdir -p source/public
		APP_VERSION=$(APP_VERSION) \
		GIT_REF=$(GIT_REF) \
		MAINTAINER="$(MAINTAINER)" \
		GIT_SOURCE=$(GIT_SOURCE) \
		GIT_REF=$(GIT_REF) \
		GOOGLE_PROJECT_ID=$(GOOGLE_PROJECT_ID) \
		./bake.sh | tee source/bake.log

build: build-app build-openresty
build-app:
		mkdir -p app/source/public
		rsync -av --delete source/public/ app/source/public
		pushd app && \
		docker build -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:${BUILD_TAG} . && \
		popd

build-openresty:
		mkdir -p openresty/source/public
		rsync -av --delete source/public/ openresty/source/public
		pushd openresty && \
		docker build -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:${BUILD_TAG} . && \
		popd

push:
		gcloud auth configure-docker
		docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:${BUILD_TAG}
		docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:${BUILD_TAG}

save:
		gsutil -m rsync -d -r source gs://$(GS_BUCKET)/$(GS_PATH)

pull:
  	docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:${BUILD_TAG} &
	  docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:${BUILD_TAG} &
		wait
