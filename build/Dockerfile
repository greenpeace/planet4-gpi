FROM gcr.io/planet-4-151612/wordpress:v0.6.0

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

WORKDIR /app

RUN rm -fr "/app/source" && \
  git clone "https://github.com/greenpeace/planet4-base" "/app/source" && \
  cd "/app/source" && \
  git checkout "develop"

COPY . /app/

WORKDIR /app/source

RUN \
  groupadd -r -g "1000" "app" && \
  useradd -r -s /usr/sbin/nologin -u 1000 -g app app && \
  composer config extra.merge-plugin.require "composer-local.json" && \
  composer update && \
  composer install --no-interaction
