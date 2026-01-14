#!/bin/bash
# 📈 Su Scheduler Version Bumper
# Author: Rex Ackermann

# 1. Get current version from module.prop
CURRENT_VERSION=$(grep "version=" module.prop | cut -d= -f2 | sed 's/^v//')
VERSION_CODE=$(grep "versionCode=" module.prop | cut -d= -f2)

# 2. Split version into segments
IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"

# 3. Increment patch
NEW_PATCH=$((patch + 1))
NEW_VERSION="${major}.${minor}.${NEW_PATCH}"
NEW_VERSION_CODE=$((VERSION_CODE + 1))

echo "🚀 Bumping: v$CURRENT_VERSION -> v$NEW_VERSION"

# 4. Update files
# module.prop
sed -i "s/version=v$CURRENT_VERSION/version=v$NEW_VERSION/" module.prop
sed -i "s/versionCode=$VERSION_CODE/versionCode=$NEW_VERSION_CODE/" module.prop

# build.sh
sed -i "s/VERSION=\"v$CURRENT_VERSION\"/VERSION=\"v$NEW_VERSION\"/" build.sh
sed -i "s/# Version: $CURRENT_VERSION/# Version: $NEW_VERSION/" build.sh

# README.md (Badge)
sed -i "s/Version-$CURRENT_VERSION-blue/Version-$NEW_VERSION-blue/" README.md

# system/bin/su-scheduler
sed -i "s/VERSION=\"$CURRENT_VERSION\"/VERSION=\"$NEW_VERSION\"/" system/bin/su-scheduler

# system/bin/su-schedulerd
sed -i "s/VERSION=\"$CURRENT_VERSION\"/VERSION=\"$NEW_VERSION\"/" system/bin/su-schedulerd

echo "✅ All files updated to v$NEW_VERSION"
