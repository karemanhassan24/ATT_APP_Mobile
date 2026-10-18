#!/usr/bin/env bash
# Patch Android status bar / system insets (Codemagic / macOS).
set -eu

ROOT="${1:-android}"
VALUES="$ROOT/app/src/main/res/values"
COLORS="$VALUES/colors.xml"
STYLES="$VALUES/styles.xml"

python3 - "$COLORS" "$STYLES" "$ROOT" <<'PY'
import glob
import os
import re
import sys

colors_path, styles_path, root = sys.argv[1], sys.argv[2], sys.argv[3]

if os.path.exists(colors_path):
    with open(colors_path, encoding="utf-8") as f:
        colors = f.read()
else:
    os.makedirs(os.path.dirname(colors_path), exist_ok=True)
    colors = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n'
if 'name="statusBarColor"' not in colors:
    colors = colors.replace("</resources>", '    <color name="statusBarColor">#FFFFFF</color>\n</resources>', 1)
    with open(colors_path, "w", encoding="utf-8") as f:
        f.write(colors)
    print("Added statusBarColor to colors.xml")
else:
    print("colors.xml already has statusBarColor")

with open(styles_path, encoding="utf-8") as f:
    styles = f.read()

items = [
    ("android:windowFullscreen", '<item name="android:windowFullscreen">false</item>'),
    ("android:statusBarColor", '<item name="android:statusBarColor">@color/statusBarColor</item>'),
    ("android:navigationBarColor", '<item name="android:navigationBarColor">@color/statusBarColor</item>'),
    ("android:windowLightStatusBar", '<item name="android:windowLightStatusBar">true</item>'),
    ("android:fitsSystemWindows", '<item name="android:fitsSystemWindows">true</item>'),
    ("android:windowOptOutEdgeToEdgeEnforcement", '<item name="android:windowOptOutEdgeToEdgeEnforcement">true</item>'),
]

match = re.search(r'(<style\s+name="AppTheme\.NoActionBar"[^>]*>)(.*?)(</style>)', styles, re.DOTALL)
if not match:
    raise SystemExit("AppTheme.NoActionBar style not found in styles.xml")

head, body, tail = match.group(1), match.group(2), match.group(3)
for attr, item in items:
    if attr not in body:
        body = body.rstrip() + "\n        " + item + "\n    "
styles = styles[: match.start()] + head + body + tail + styles[match.end():]
with open(styles_path, "w", encoding="utf-8") as f:
    f.write(styles)
print("styles.xml patched for status bar spacing")

mains = glob.glob(os.path.join(root, "app/src/main/java/**/MainActivity.java"), recursive=True)
if not mains:
    print("MainActivity.java not found - skipping runtime inset patch")
    raise SystemExit(0)

main_path = mains[0]
with open(main_path, encoding="utf-8") as f:
    source = f.read()
if "setDecorFitsSystemWindows" in source:
    print("MainActivity.java already applies system window insets")
    raise SystemExit(0)

package_match = re.match(r"\s*package\s+([\w.]+);", source)
if not package_match:
    raise SystemExit("Could not read package name from " + main_path)

template = """package __PACKAGE__;

import android.graphics.Color;
import android.os.Bundle;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WindowCompat.setDecorFitsSystemWindows(getWindow(), true);
        getWindow().setStatusBarColor(Color.WHITE);
        WindowInsetsControllerCompat controller =
            WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        if (controller != null) {
            controller.setAppearanceLightStatusBars(true);
        }
    }
}
"""
with open(main_path, "w", encoding="utf-8") as f:
    f.write(template.replace("__PACKAGE__", package_match.group(1)))
print("Patched " + main_path)
PY
