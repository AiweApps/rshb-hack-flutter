#!/bin/bash

# fastlane reads keychain output as US-ASCII without a locale and fails on the first non-ASCII byte.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

PROJECT_FOLDER=$(dirname "$0")
cd "${PROJECT_FOLDER}" && pwd
cd "ios/fastlane" && pwd
bundle install && bundle exec fastlane testflight_prod --env prod
