#!/bin/bash

MISSING_PACKAGE_JSONS=()
NEED_UPDATE_PACKAGE_JSONS=()
NEW_JS_FILES=()

find_package_json() {
  if [[ -f "$1/package.json" ]]; then
    if [[ -z $( grep "@penskemediacorp/wordpress-scripts" $1/package.json ) ]]; then
      NEED_UPDATE_PACKAGE_JSONS+=("$1/package.json")
    fi
  elif [[ ${1} == "." || $1 == $2 ]]; then
    MISSING_PACKAGE_JSONS+=("$1/package.json")
  else
    find_package_json $(dirname $1) $2
  fi
}

GIT_REPO=$(git remote get-url origin)
DEFAULT_BRANCH=$(
  git ls-remote --symref ${GIT_REPO} HEAD 2>stderr \
    | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}'
  )

HAS_ERROR=""

if [[ -f .pmc-scripts ]]; then
  source .pmc-scripts
fi

# Enforce new files must be in typescript
for file in $(
  if [[ -z ${JS_IGNORE_PATTERNS} ]]; then
    git --no-pager diff --diff-filter=A "origin/${DEFAULT_BRANCH}" --name-only \
      -- '*.js' '*.ts' ':!/vendor/' ':!/.cache/' ':!/node_modules/' \
      | grep -E '\.js$'
  else
    git --no-pager diff --diff-filter=A "origin/${DEFAULT_BRANCH}" --name-only \
      -- '*.js' '*.ts' ':!/vendor/' ':!/.cache/' ':!/node_modules/' \
      | grep -E '\.js$' \
      | grep -v -E "${JS_IGNORE_PATTERNS}"
  fi
); do
  NEW_JS_FILES+=(${file})
done

# Enforce new file add to project should use @penskemediacorp/wordpress-scripts for build
NEW_FILES=$(
    if [[ -z ${PMC_SCRIPTS_IGNORE_PATTERNS} ]]; then
      git --no-pager diff --diff-filter=A "origin/${DEFAULT_BRANCH}" --name-only \
        -- '*.js' '*.ts' ':!/vendor/' ':!/.cache/' ':!/node_modules/'
    else
      git --no-pager diff --diff-filter=A "origin/${DEFAULT_BRANCH}" --name-only \
        -- '*.js' '*.ts' ':!/vendor/' ':!/.cache/' ':!/node_modules/' \
        | grep -v -E "${PMC_SCRIPTS_IGNORE_PATTERNS}"
    fi
  )

if [[ -n $NEW_FILES ]]; then
  for path in $(echo ${NEW_FILES[@]} | xargs printf '%s\n' | xargs dirname | sort -u); do
    if [[ ! -f ${path}/package.json || -z $( grep "@penskemediacorp/wordpress-scripts" ${path}/package.json ) ]]; then
      if [[ "${GIT_REPO}" =~ "penske-media-corp/pmc-plugins" ]]; then
        find_package_json "${path}" $(echo "${path}" | cut -d/ -f1)
      else
        find_package_json "${path}"
      fi
    fi
  done
fi

if [[ -n ${NEW_JS_FILES[@]} ]]; then
  HAS_ERROR=true
  echo -e "\nTypescripts are required for the following js file(s): "
  printf ' - %s\n' ${NEW_JS_FILES[@]} | sort -u
fi
if [[ -n ${NEED_UPDATE_PACKAGE_JSONS[@]} ]]; then
  HAS_ERROR=true
  echo -e "\n@penskemediacorp/wordpress-scripts build script is required for following package.json:"
  printf ' - %s\n' ${NEED_UPDATE_PACKAGE_JSONS[@]} | sort -u
fi
if [[ -n ${MISSING_PACKAGE_JSONS[@]} ]]; then
  HAS_ERROR=true
  echo -e "\nThe following package.json is missing:"
  printf ' - %s\n' ${MISSING_PACKAGE_JSONS[@]} | sort -u
fi

if [[ -n ${HAS_ERROR} ]]; then
  echo -e "\nErrors detected.\n"
  exit 1
fi
