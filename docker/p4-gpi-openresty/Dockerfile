FROM gcr.io/planet-4-151612/p4-gpi-openresty-dev:develop

MAINTAINER ${IMAGE_MAINTAINER}

ENV \
    APP_ENV="production"

RUN rm -fr /app/www

COPY ./www /app/www
