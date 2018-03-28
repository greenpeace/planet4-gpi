#!/usr/bin/env bash
set -eu

function usage() {
  echo "Usage: $(basename "$0") SOURCE_IMAGE [OUTPUT_DIR]

Performs initial composer install in container and exports the resultant site

"
}

source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  # if $source was a relative symlink, we need to resolve it relative to the
  # path where the symlink file was located
  [[ $source != /* ]] && source="$dir/$source"
done
BUILD_DIR="$( cd -P "$( dirname "$source" )/.." && pwd )"

# . "${BUILD_DIR}/bin/env.sh"

OPTIONS=':c:e:lprv'
while getopts $OPTIONS option
do
    case $option in
        *  )    >&2 echo "Unknown parameter"
                usage
                exit 1;;
    esac
done
shift $((OPTIND - 1))

if [[ -z "${1:-}" ]]
then
  echo "Error: image name not specified"
  usage
  exit 1
fi

image=$1

if [[ -z "${2:-}" ]]
then

  # Clean up on exit
  function finish() {
    rm -fr "$TMPDIR"
  }

  trap finish EXIT
  TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

  output_dir="$TMPDIR"
else
  mkdir -p "$2"
  output_dir="$2"
fi

echo "Image:  $1"
echo "Output: $output_dir"
echo ""

# SOURCE_BRANCH_SANITIZED=${SOURCE_BRANCH//[^[:alnum:]_]/-}

docker run -e "WP_BAKE=true" "${image}" || true

echo ""
# docker commit docker "$(docker ps -alq)" gcr.io/planet-4-151612/p4-gpi-app:latest
# docker tag gcr.io/planet-4-151612/p4-gpi-app:latest "gcr.io/planet-4-151612/p4-gpi-app:${APP_VERSION}"

container="$(docker ps -alq)"
docker cp "$container:/app/source/public/" "$output_dir"

docker rm "$container"

echo "Files available at: $output_dir/public"

# gsutil cp $output_dir gs://${GS_BUCKET}/planet4-gpi
ls "$output_dir/public"
