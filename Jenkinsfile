def pick(List<String> values, String fallback = '') {
  for (String value : values) {
    if (value != null && value.trim()) {
      return value.trim()
    }
  }
  return fallback
}

node {
  stage('Normalize CI Context') {
    env.CI_EVENT_NAME = pick([
      env.CI_EVENT_NAME,
      env.GITHUB_EVENT_NAME,
      env.CI_PIPELINE_SOURCE
    ], 'manual')

    env.CI_REF = pick([
      env.CI_REF,
      env.GITHUB_REF,
      env.CI_COMMIT_REF_NAME,
      env.BRANCH_NAME
    ], '')

    env.CI_SHA = pick([
      env.CI_SHA,
      env.GITHUB_SHA,
      env.CI_COMMIT_SHA
    ], '')

    env.CI_PR_NUMBER = pick([
      env.CI_PR_NUMBER,
      env.CHANGE_ID,
      env.MR_IID
    ], '')

    env.CI_RECIPE = pick([
      env.CI_RECIPE,
      env.RECIPE
    ], 'recipe.yml')

    env.CI_SOURCE_WORKSPACE = pick([
      env.CI_SOURCE_WORKSPACE,
      env.SOURCE_WORKSPACE,
      env.GITHUB_WORKSPACE,
      env.CI_PROJECT_DIR
    ], env.WORKSPACE ?: '')

    env.CI_REGISTRY = pick([
      env.CI_REGISTRY,
      env.REGISTRY_URL
    ], 'ghcr.io')

    env.CI_REGISTRY_TOKEN = pick([
      env.CI_REGISTRY_TOKEN,
      env.REGISTRY_TOKEN,
      env.GITHUB_TOKEN
    ], '')

    env.CI_REGISTRY_USER = pick([
      env.CI_REGISTRY_USER,
      env.REGISTRY_USER,
      env.GITHUB_ACTOR
    ], 'github-actions[bot]')

    env.CI_SIGNING_SECRET = pick([
      env.CI_SIGNING_SECRET,
      env.SIGNING_SECRET
    ], '')

    env.CI_IS_PR = (env.CI_EVENT_NAME == 'pull_request' || env.CI_EVENT_NAME == 'merge_request_event').toString()

    echo "event=${env.CI_EVENT_NAME}, ref=${env.CI_REF}, is_pr=${env.CI_IS_PR}, recipe=${env.CI_RECIPE}"
  }

  stage('Prepare Workspace') {
    sh '''#!/usr/bin/env bash
set -euo pipefail
if [ -n "${CI_SOURCE_WORKSPACE:-}" ] && [ -d "${CI_SOURCE_WORKSPACE}" ] && [ "${CI_SOURCE_WORKSPACE}" != "${WORKSPACE}" ]; then
  cp -a "${CI_SOURCE_WORKSPACE}"/. "$WORKSPACE"/
fi
'''
  }

  stage('Install BlueBuild CLI') {
    sh '''#!/usr/bin/env bash
set -euo pipefail
if ! command -v bluebuild >/dev/null 2>&1; then
  bash <(curl -fsSL https://raw.githubusercontent.com/blue-build/cli/main/install.sh)
fi
bluebuild --version
'''
  }

  stage('Registry Login') {
    if (!env.CI_IS_PR?.toBoolean()) {
      sh '''#!/usr/bin/env bash
set -euo pipefail
if [ -z "${CI_REGISTRY_TOKEN:-}" ]; then
  echo "CI_REGISTRY_TOKEN is required for non-PR builds."
  exit 1
fi
if command -v docker >/dev/null 2>&1; then
  echo "$CI_REGISTRY_TOKEN" | docker login "${CI_REGISTRY}" -u "${CI_REGISTRY_USER}" --password-stdin
elif command -v podman >/dev/null 2>&1; then
  echo "$CI_REGISTRY_TOKEN" | podman login "${CI_REGISTRY}" -u "${CI_REGISTRY_USER}" --password-stdin
else
  echo "No docker/podman runtime available for registry login."
  exit 1
fi
'''
    } else {
      echo 'PR/MR build detected, skipping registry login.'
    }
  }

  stage('Build Image') {
    sh '''#!/usr/bin/env bash
set -euo pipefail
RECIPE_PATH="$CI_RECIPE"
if [ ! -f "$RECIPE_PATH" ] && [ -f "recipes/$CI_RECIPE" ]; then
  RECIPE_PATH="recipes/$CI_RECIPE"
fi
if [ ! -f "$RECIPE_PATH" ]; then
  echo "Recipe not found: $CI_RECIPE"
  exit 1
fi

if [ "$CI_IS_PR" = "true" ]; then
  bluebuild build "$RECIPE_PATH"
else
  if [ -n "${CI_SIGNING_SECRET:-}" ]; then
    export COSIGN_PRIVATE_KEY="$CI_SIGNING_SECRET"
  fi
  bluebuild build --push "$RECIPE_PATH"
fi
'''
  }
}
