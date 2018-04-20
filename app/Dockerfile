FROM p4-build:latest

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

ENV APP_ENV="production" \
    WP_TITLE="Greenpeace International"

COPY . /app/

RUN chown -R app:app /app/source
