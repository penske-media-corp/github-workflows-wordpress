#!/bin/bash
set -e

HAS_ERROR=""
NEED_UPDATE_PACKAGE_JSONS=()
NEW_JS_FILES=()

find_package_json() {
  if [[ -f "$1/package.json" ]]; then
    if [[ -n $( grep "@wordpress/scripts" $1/package.json ) || -n $( grep "@penskemediacorp/wordpress-scripts" $1/package.json ) ]]; then
      echo "$1/package.json"
    fi
  elif [[ ${1} != "." && $1 != $2 ]]; then
    find_package_json $(dirname $1) $2
  fi
}

GIT_REPO=$(git remote get-url origin)
if [[ -z ${DEFAULT_BRANCH} ]]; then
  DEFAULT_BRANCH=$(
    git ls-remote --symref ${GIT_REPO} HEAD 2>stderr \
      | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}'
    )
fi

git fetch origin ${DEFAULT_BRANCH}

if [[ -f .pmc-scripts ]]; then
  source .pmc-scripts
fi

for file in $(
  if [[ -z ${JS_IGNORE_PATTERNS} ]]; then
    git --no-pager diff --diff-filter=A "origin/${DEFAULT_BRANCH}" --name-only \
      -- '*.js' '*.ts' '*.jsx' '*.tsx' ':!/vendor/' ':!/.cache/' ':!/node_modules/' \
      | grep -E '\.jsx?$'
  else
    git --no-pager diff --diff-filter=A "origin/${DEFAULT_BRANCH}" --name-only \
      -- '*.js' '*.ts' ':!/vendor/' ':!/.cache/' ':!/node_modules/' \
      | grep -E '\.jsx?$' \
      | grep -v -E "${JS_IGNORE_PATTERNS}"
  fi
); do
  path=$(dirname $file)
  if [[ "${GIT_REPO}" =~ "penske-media-corp/pmc-plugins" ]]; then
    package_json=$( find_package_json "${path}" $(echo "${path}" | cut -d/ -f1) )
  else
    package_json=$( find_package_json "${path}" )
  fi

  if [[ -n $package_json ]]; then
    NEW_JS_FILES+=(${file})
    if [[ -z $( grep "@penskemediacorp/wordpress-scripts" $package_json ) || -z $( grep "pmc-scripts" $package_json ) ]]; then
      NEED_UPDATE_PACKAGE_JSONS+=($package_json)
    fi
  fi
done

if [[ -n ${NEW_JS_FILES[@]} ]]; then
  HAS_ERROR=true
  echo -e "\nTypescripts are required for the following js file(s): "
  printf ' - %s\n' ${NEW_JS_FILES[@]} | sort -u
fi
if [[ -n ${NEED_UPDATE_PACKAGE_JSONS[@]} ]]; then
  HAS_ERROR=true
  echo -e "\nBuild script need to use @penskemediacorp/wordpress-scripts package:"
  printf ' - %s\n' ${NEED_UPDATE_PACKAGE_JSONS[@]} | sort -u
fi

if [[ -n ${HAS_ERROR} ]]; then
  echo -e "\nErrors detected.\n"
  exit 1
fi
