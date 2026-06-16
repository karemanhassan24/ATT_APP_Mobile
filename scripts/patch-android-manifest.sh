#!/usr/bin/env bash
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"

if [ ! -f "$MANIFEST" ]; then
  echo "AndroidManifest.xml not found at $MANIFEST"
  exit 1
fi

permissions=(
  "INTERNET"
  "ACCESS_FINE_LOCATION"
  "ACCESS_COARSE_LOCATION"
  "ACCESS_NETWORK_STATE"
)

for perm in "${permissions[@]}"; do
  if grep -q "android.permission.${perm}" "$MANIFEST"; then
    echo "Permission ${perm} already present"
  else
    sed -i "/<application/i\\    <uses-permission android:name=\"android.permission.${perm}\" />" "$MANIFEST"
    echo "Added permission ${perm}"
  fi
done

if ! grep -q 'android:usesCleartextTraffic' "$MANIFEST"; then
  sed -i 's/<application /<application android:usesCleartextTraffic="true" /' "$MANIFEST"
  echo "Enabled usesCleartextTraffic"
fi

echo "AndroidManifest.xml patched successfully"
