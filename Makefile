SHELL := /bin/bash

GOOGLE_PROJECT_ID ?= planet-4-151612
ENVIRONMENT				?= development
BUILD_PATH 				?= env/$(ENVIRONMENT)
# GS_BUCKET 				:= p4-src-public
# GS_PATH 					?= production

BUILD_NAMESPACE ?= gcr.io


GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

# Build tag
# If not set, defaults to git tag pointing to current commit
BUILD_TAG ?= $(shell git tag -l --points-at HEAD)

# If the current commit does not have a tag, or the variable is empty
# Defaults to the current git branch name
ifeq ($(strip $(BUILD_TAG)),)
BUILD_TAG := $(GIT_BRANCH)
endif

# Compose command
COMPOSER_EXEC ?= composer --profile -vv

################################################################################

.PHONY: clean test configure build-dev bake src build pull

all: clean test configure build-dev bake build pull

test:
	  @echo "TAG: $(BUILD_TAG)"
	  @echo "TAG: $(GIT_BRANCH)"

clean:
	  rm -fr planet4-base
		rm -fr www

configure: ### Update git submodules
		git submodule update --init --remote
		# Checkout matching branch in planet4-base
		pushd planet4-base && \
		git checkout $(GIT_BRANCH) && \
		git reset --hard && \
		git pull && \
		cp ../env/development/p4-gpi-app-dev/composer.json composer-local.json && \
		$(COMPOSER_EXEC) config extra.merge-plugin.require "composer-local.json" && \
		$(COMPOSER_EXEC) update && \
		$(COMPOSER_EXEC) install --no-interaction && \
  	$(COMPOSER_EXEC) clear-cache && \
		popd

build-dev:
		gcloud config set project $(GOOGLE_PROJECT_ID)
		rsync -a --delete planet4-base/ env/development/p4-gpi-app-dev/source
		mkdir -p env/development/p4-gpi-app-dev/source/public
		pushd env/development && \
		gcloud container builds submit . \
			--config cloudbuild.yaml && \
		popd

bake: src
src:
		bin/bake.sh gcr.io/$(GOOGLE_PROJECT_ID)/p4-gpi-app-dev:develop www
		rsync -a --delete www/public/ env/production/p4-gpi-app/www
		rsync -a --delete www/public/ env/production/p4-gpi-openresty/www

build:
		gcloud config set project $(GOOGLE_PROJECT_ID)
		pushd env/production && \
		gcloud container builds submit . \
		  --substitutions=_BUILD_NAMESPACE=$(BUILD_NAMESPACE),_BUILD_TAG=$(BUILD_TAG),_GOOGLE_PROJECT_ID=$(GOOGLE_PROJECT_ID) \
		  --config cloudbuild.yaml && \
		popd

pull:
	  docker pull gcr.io/$(GOOGLE_PROJECT_ID)/p4-gpi-app-dev:${BUILD_TAG} &
	  docker pull gcr.io/$(GOOGLE_PROJECT_ID)/p4-gpi-openresty-dev:${BUILD_TAG} &
	  docker pull gcr.io/$(GOOGLE_PROJECT_ID)/p4-gpi-app:${BUILD_TAG} &
	  docker pull gcr.io/$(GOOGLE_PROJECT_ID)/p4-gpi-openresty:${BUILD_TAG} &
		wait
