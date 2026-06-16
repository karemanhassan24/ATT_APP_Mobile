#!/usr/bin/env bash
set -euo pipefail

MANIFEST="${1:-android/app/src/main/AndroidManifest.xml}"

if [ ! -f "$MANIFEST" ]; then
  echo "AndroidManifest.xml not found at $MANIFEST"
  exit 1
fi

python3 - "$MANIFEST" <<'PY'
import sys

path = sys.argv[1]
perms = [
    "INTERNET",
    "ACCESS_FINE_LOCATION",
    "ACCESS_COARSE_LOCATION",
    "ACCESS_NETWORK_STATE",
    "POST_NOTIFICATIONS",
    "VIBRATE",
]

with open(path, encoding="utf-8") as f:
    content = f.read()

for perm in perms:
    token = f'android.permission.{perm}'
    if token in content:
        print(f"Already has: {perm}")
        continue
    line = f'    <uses-permission android:name="{token}" />\n'
    if "<application" in content:
        content = content.replace("<application", line + "<application", 1)
        print(f"Added permission: {perm}")
    else:
        print("No <application tag found", file=sys.stderr)
        sys.exit(1)

if 'android.hardware.location.gps' not in content and "<application" in content:
    feature = '    <uses-feature android:name="android.hardware.location.gps" android:required="false" />\n'
    content = content.replace("<application", feature + "<application", 1)
    print("Added GPS hardware feature")

if 'android:usesCleartextTraffic' not in content:
    content = content.replace("<application ", '<application android:usesCleartextTraffic="true" ', 1)
    print("Enabled usesCleartextTraffic")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

for required in ("ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION"):
    if f'android.permission.{required}' not in content:
        print(f"FAILED: missing {required}", file=sys.stderr)
        sys.exit(1)

print("AndroidManifest.xml patched and verified successfully")
PY
