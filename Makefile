SHELL := /bin/bash

GOOGLE_PROJECT_ID ?= planet4-gpi
MERGE_PATH 				?= app/planet4-gpi/production/composer.json
# GS_BUCKET 				:= p4-src-public
# GS_PATH 					?= production

BUILD_NAMESPACE ?= gcr.io

# Tag to append to container.
# If not set, defaults to git tag pointing to current commit
BUILD_TAG ?= $(shell git tag -l --points-at HEAD)
# If the current commit does not have a tag, or the variable is empty
# Defaults to the current git branch name
ifeq ($(strip $(BUILD_TAG)),)
BUILD_TAG := $(shell git rev-parse --abbrev-ref HEAD)
endif

# Compose command
COMPOSER_EXEC ?= composer --profile -vv

################################################################################

.PHONY: test dep src build pull

all: clean test dep src build pull

test:
	  @echo "TAG: $(BUILD_TAG)"

clean:
	  rm -fr planet4-base

update:
	  git submodule update --remote

dep: ### Update git submodules
		git submodule init
		git submodule update
		pushd planet4-base && \
		$(COMPOSER_EXEC) config extra.merge-plugin.require "$(MERGE_PATH)" && \
		$(COMPOSER_EXEC) update && \
		popd

src:
		pushd planet4-base && \
		$(COMPOSER_EXEC) run-script reset:public && \
		$(COMPOSER_EXEC) run-script download:wordpress && \
		$(COMPOSER_EXEC) run-script copy:health-check && \
		$(COMPOSER_EXEC) run-script reset:themes && \
		$(COMPOSER_EXEC) run-script reset:plugins && \
		$(COMPOSER_EXEC) run-script copy:themes && \
		$(COMPOSER_EXEC) run-script copy:assets && \
		$(COMPOSER_EXEC) run-script copy:plugins && \
		$(COMPOSER_EXEC) run-script core:style && \
		popd

build:
		gcloud config set project $(GOOGLE_PROJECT_ID)
		gcloud container builds submit . \
		  --substitutions=_BUILD_NAMESPACE=$(BUILD_NAMESPACE),_BUILD_TAG=$(BUILD_TAG),_GOOGLE_PROJECT_ID=$(GOOGLE_PROJECT_ID) \
		  --config cloudbuild.yaml

pull:
	  docker pull gcr.io/$(GOOGLE_PROJECT_ID)/p4-gpi-app:${BUILD_TAG}
	  docker pull gcr.io/$(GOOGLE_PROJECT_ID)/p4-gpi-openresty:${BUILD_TAG}
