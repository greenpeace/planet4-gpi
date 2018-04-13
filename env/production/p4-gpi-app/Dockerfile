FROM gcr.io/planet-4-151612/wordpress:develop

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

ENV APP_ENV="production" \
    WP_STATELESS_MEDIA_KEY_FILE_PATH="" \
    WP_TITLE="Greenpeace International"

COPY . /app/

RUN rm /app/etc/my_init.d/00_bake.sh \
 && rm /app/etc/my_init.d/20_install_wordpress.sh
