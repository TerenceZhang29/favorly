#!/bin/sh
# Makes the 1024×1024 app icon from the logo in docs/brand/logo.png (opaque, no alpha).
# Run from the repo root: sh scripts/make-app-icon.sh
set -eu
sips -s format png -z 1024 1024 docs/brand/logo.png \
  --out App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png >/dev/null
