#!/usr/bin/env bash
set -eu

function usage() {
  echo "Usage: $(basename "$0")

Performs initial composer install in container and exports the
generated files for use elsewhere.

"
}

# ----------------------------------------------------------------------------

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within

source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
current_path="$( cd -P "$( dirname "$source" )" && pwd )"

# ----------------------------------------------------------------------------

output_dir="source"
mkdir -p "$output_dir"

container=$(basename "$(realpath "${current_path}/")")
app_container=${container//[^[:alnum:]_]/}_app_1
php_container=${container//[^[:alnum:]_]/}_php-fpm_1

echo "Image:  $container"
echo "Output: $output_dir"
echo ""

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
  '${GIT_BRANCH}' \
  '${GIT_SOURCE}' \
  '${SOURCE_PATH}' \
)

envvars_string="$(printf "%s:" "${envvars[@]}")"
envvars_string="${envvars_string%:}"

build_dir="${current_path}/build"
envsubst "${envvars_string}" < "${build_dir}/Dockerfile.in" > "${build_dir}/Dockerfile"

# ----------------------------------------------------------------------------

# copy source repository to build dir
# rsync -av --delete planet4-base/ build/source

docker-compose down -v

# ----------------------------------------------------------------------------

# Build the container and start
echo "Building containers..."
docker-compose build
echo ""

echo "Starting containers..."
docker-compose up -d
echo ""

# 10 * 120 = 20 minutes
interval=5
loop=240

# Number of consecutive successes to qualify as 'up'
success=0
threshold=3

# This will take a while
echo "Sleeping 15 seconds..."
sleep 15

until [[ $success -ge $threshold ]]
do
  # Curl to container and expect status code 200
  set +ex
  echo "Checking $container response"
  docker run --network "container:$app_container" --rm appropriate/curl -s -k "http://localhost:80" | grep "greenpeace"

  if [[ $? -eq 0 ]]
  then
    success=$((success+1))
    echo "Success: $success"
  else
    success=0
    echo "Fail"
  fi
  set -e

  loop=$((loop-1))
  if [[ $loop -lt 1 ]]
  then
    >&2 echo "[ERROR] Timeout waiting for docker-compose to start"
    >&2 docker-compose logs
    exit 1
  fi

  sleep $interval

done

docker-compose logs php-fpm
echo ""

echo "Copying built source directory..."
docker cp "$app_container:/app/source/public/" "$output_dir"
echo ""

echo "Bringing down containers..."
# docker-compose down -v &
echo ""

echo "Files available at: $output_dir/public"

# FIXME store these files in a bucket!
# gsutil cp $output_dir gs://${GS_BUCKET}/planet4-gpi

ls "$output_dir/public"

rm "$output_dir/public/index.html"

mkdir -p app/source/public
mkdir -p openresty/source/public

rsync -a --delete "$output_dir/public/" app/source/public
rsync -a --delete "$output_dir/public/" openresty/source/public

echo "Waiting for docker-compose down to finish..."
wait
echo ""
