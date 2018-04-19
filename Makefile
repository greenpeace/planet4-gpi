SHELL := /bin/bash

BUILD_NAMESPACE 	?= gcr.io
GOOGLE_PROJECT_ID ?= planet-4-151612
CONTAINER_PREFIX  ?= planet4-gpi

GIT_SOURCE 				?= https://github.com/greenpeace/planet4-base

# The branch to checkout of github.com/greenpeace/planet4-base
GIT_BRANCH 				?= $(shell git rev-parse --abbrev-ref HEAD)

# Tag for built containers
# If not set, defaults to git tag pointing to current commit
BUILD_TAG 				?= $(shell git tag -l --points-at HEAD)

GS_BUCKET 				:= $(CONTAINER_PREFIX)-source
GS_PATH 					?= $(GIT_BRANCH)

# If the current commit does not have a tag, or the variable is empty
ifeq ($(strip $(BUILD_TAG)),)
BUILD_TAG := $(GIT_BRANCH)
endif

################################################################################

.PHONY: clean test bake build bugit iild-app build-openresty save pull

all: clean test bake build save

test:
	  @echo "BUILD_TAG: $(BUILD_TAG)"
	  @echo "GIT_BRANCH: $(GIT_BRANCH)"

clean:
	  rm -fr planet4-base
		rm -fr source
		docker-compose down -v --remove-orphans
		docker rmi p4-build --force

bake:
		GIT_SOURCE=$(GIT_SOURCE) GIT_REF=$(GIT_BRANCH) ./bake.sh

build: build-app build-openresty
build-app:
		pushd app && \
		docker build -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:${BUILD_TAG} . && \
		popd

build-openresty:
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
