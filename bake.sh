#!/usr/bin/env bash
set -eu

function usage() {
  echo "Usage: $(basename "$0")

Performs initial composer install in container and exports the
generated files for use elsewhere.

"
}

# ----------------------------------------------------------------------------

output_dir="source"
mkdir -p "$output_dir"

export APP_GID=${APP_GID:-1000}
export APP_GROUP=${APP_GROUP:-app}
export APP_UID=${APP_UID:-1000}
export APP_USER=${APP_USER:-app}

export SOURCE_PATH=/app/source

# Specify which Dockerfile|README.md variables we want to change
# shellcheck disable=SC2016
envvars=(
  '${APP_GID}' \
  '${APP_GROUP}' \
  '${APP_UID}' \
  '${APP_USER}' \
  '${APP_VERSION}' \
  '${GIT_REF}' \
  '${GIT_SOURCE}' \
  '${GOOGLE_PROJECT_ID}' \
  '${MAINTAINER}' \
  '${SOURCE_PATH}' \
)
envvars_string="$(printf "%s:" "${envvars[@]}")"

for i in build app openresty
do
  build_dir=$i
  envsubst "${envvars_string%:}" < "${build_dir}/Dockerfile.in" > "${build_dir}/Dockerfile"
done

# ----------------------------------------------------------------------------

docker-compose -p build down -v --remove-orphans

# ----------------------------------------------------------------------------

# Build the container and start
echo "Building containers..."
docker-compose -p build build
echo ""

echo "Starting containers..."
docker-compose -p build up -d
echo ""

# 2 seconds * 150 == 5+ minutes
interval=2
loop=150

# Number of consecutive successes to qualify as 'up'
threshold=3
success=0

until [[ $success -ge $threshold ]]
do
  # Curl to container and expect status code 200
  set +e
  docker run --network "container:build_app_1" --rm appropriate/curl -s -k "http://localhost:80" | grep -q "greenpeace"

  if [[ $? -eq 0 ]]
  then
    success=$((success+1))
    echo "Success: $success/$threshold"
  else
    success=0
  fi
  set -e

  loop=$((loop-1))
  if [[ $loop -lt 1 ]]
  then
    >&2 echo "[ERROR] Timeout waiting for docker-compose to start"
    >&2 docker-compose logs
    exit 1
  fi

  [[ $success -ge $threshold ]] || sleep $interval

done

docker-compose logs php-fpm
echo ""

echo "Copying built source directory..."
docker cp "build_app_1:/app/source/public/" "$output_dir"
echo ""

echo "Bringing down containers..."
docker-compose down -v &
echo ""

# FIXME volume: nocopy not working in the docker-compse.yml file
rm -f "$output_dir/public/index.html"

wait

echo "Done"
echo "Output: $output_dir/public"
