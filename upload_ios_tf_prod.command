#!/bin/bash
PROJECT_FOLDER=$(dirname "$0")
cd "${PROJECT_FOLDER}" && pwd
cd "ios/fastlane" && pwd
bundle install && bundle exec fastlane testflight_prod --env prod
