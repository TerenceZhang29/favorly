#!/bin/sh
# Makes the 1024×1024 app icons from the logos in docs/brand: logo.png for light mode and
# logo-dark.jpg for dark mode (both opaque, no alpha).
# Run from the repo root: sh scripts/make-app-icon.sh
set -eu
icons=App/Resources/Assets.xcassets/AppIcon.appiconset
sips -s format png -z 1024 1024 docs/brand/logo.png --out "$icons/AppIcon.png" >/dev/null
sips -s format png -z 1024 1024 docs/brand/logo-dark.jpg --out "$icons/AppIcon-Dark.png" >/dev/null
