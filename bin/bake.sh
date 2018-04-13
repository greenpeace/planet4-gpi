#!/usr/bin/env bash
set -eu

function usage() {
  echo "Usage: $(basename "$0") SOURCE_IMAGE [OUTPUT_DIR]

Performs initial composer install in container and exports the
generated files for use elsewhere.

"
}

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
    [[ ! -z "$output_dir" ]] && rm -fr "$output_dir"
  }
  trap finish EXIT

  output_dir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

else
  mkdir -p "$2"
  output_dir="$2"
fi

echo "Image:  $1"
echo "Output: $output_dir"
echo ""

# Exit true because bake intentionally aborts container build early
docker run -e "WP_BAKE=true" "${image}" || true

echo ""

container="$(docker ps -alq)"
docker cp "$container:/app/source/public/" "$output_dir"

docker rm "$container"

echo "Files available at: $output_dir/public"

# gsutil cp $output_dir gs://${GS_BUCKET}/planet4-gpi
ls "$output_dir/public"
