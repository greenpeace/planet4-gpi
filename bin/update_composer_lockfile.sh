#!/usr/bin/env bash
set -e


if [[ -z "${GITHUB_OAUTH_TOKEN}" ]] && [[ -z "${CI:-}" ]]
then
  echo "GITHUB_OAUTH_TOKEN not found in environment."
  printf "%s " "Please enter token now:"
  read GITHUB_OAUTH_TOKEN
fi

if [[ -z "${GITHUB_OAUTH_TOKEN}" ]]
then
  >&2 echo "ERROR: \$GITHUB_OAUTH_TOKEN is not set"
  >&2 echo "       Please ensure a valid github token is available"
  exit 1
fi

if [[ $1 = 'dev' ]]
then
  COMPOSER="composer-dev.json"
fi

if [[ "${COMPOSER}" ]]
then
  echo "Using COMPOSER=${COMPOSER}"
fi

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  # if $source was a relative symlink, we need to resolve it relative to the
  # path where the symlink file was located
  [[ $source != /* ]] && source="$dir/$source"
done
build_dir="$( cd -P "$( dirname "$source" )/.." && pwd )"

pushd "$build_dir"

composer --profile -vv update

popd
