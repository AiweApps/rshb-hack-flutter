#!/bin/bash
# Script to generate Firebase configuration files for different environments/flavors

if [[ $# -eq 0 ]]; then
  echo "Error: No environment specified. Use 'dev' or 'prod'."
  exit 1
fi

project=""
devBundleId="com.aiweapps.winescan.dev"
prodBundleId="com.aiweapps.winescan"

case $1 in
  dev)
    flutterfire config \
      --project=$project \
      --out=lib/firebase/firebase_options_dev.dart \
      --ios-bundle-id=$devBundleId \
      --ios-out=ios/flavors/dev/GoogleService-Info.plist \
      --android-package-name=$devBundleId \
      --android-out=android/app/src/dev/google-services.json
    ;;
  prod)
    flutterfire config \
      --project=$project \
      --out=lib/firebase/firebase_options_prod.dart \
      --ios-bundle-id=$prodBundleId \
      --ios-out=ios/flavors/prod/GoogleService-Info.plist \
      --android-package-name=$prodBundleId \
      --android-out=android/app/src/prod/google-services.json
    ;;
  *)
    echo "Error: Invalid environment specified. Use 'dev' or 'prod'."
    exit 1
    ;;
esac