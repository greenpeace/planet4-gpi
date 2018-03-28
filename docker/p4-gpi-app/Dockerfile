FROM gcr.io/planet-4-151612/p4-gpi-app-dev:develop

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

ENV APP_ENV="production" \
    WP_BAKE="false" \
    WP_SET_OPTIONS_ON_BOOT="false" \
    WP_SITE_HOME="k8s.p4.greenpeace.org/international" \
    WP_SITE_URL="k8s.p4.greenpeace.org/international" \
    WP_STATELESS_MEDIA_KEY_FILE_PATH="" \
    WP_TITLE="Greenpeace International"

RUN rm -fr /app/www \
 && rm /app/etc/my_init.d/00_bake.sh \
 && rm /app/etc/my_init.d/20_install_wordpress.sh

COPY ./www/ /app/www

RUN ln -s /app/www /app/source/public
