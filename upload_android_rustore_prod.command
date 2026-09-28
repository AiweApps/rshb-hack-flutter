#!/bin/bash
PROJECT_FOLDER=$(dirname "$0")
cd "${PROJECT_FOLDER}" && pwd
cd "android/fastlane" && pwd
bundle install && bundle exec fastlane rustore_prod --env prod
