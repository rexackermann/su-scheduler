#!/bin/bash
# 📈 Su Scheduler Version Bumper (Hardened)
# Author: Rex Ackermann

# 1. Get current version from module.prop
CURRENT_VERSION=$(grep "version=" module.prop | cut -d= -f2 | sed 's/^v//')
CURRENT_VERSION_CODE=$(grep "versionCode=" module.prop | cut -d= -f2)

# 2. Split version into segments
IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"

# 3. Increment patch
NEW_PATCH=$((patch + 1))
NEW_VERSION="${major}.${minor}.${NEW_PATCH}"
NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))

echo "🚀 Bumping: v$CURRENT_VERSION -> v$NEW_VERSION"

# 4. Update files using ROBUST regex (Targets keys, not current values)

# module.prop
sed -i "s/^version=.*/version=v$NEW_VERSION/" module.prop
sed -i "s/^versionCode=.*/versionCode=$NEW_VERSION_CODE/" module.prop

# build.sh
sed -i "s/VERSION=\"v.*\"/VERSION=\"v$NEW_VERSION\"/" build.sh
sed -i "s/# Version: .*/# Version: $NEW_VERSION/" build.sh

# README.md
sed -i "s/Version-[0-9.]*-blue/Version-$NEW_VERSION-blue/" README.md

# system/bin/su-scheduler & su-schedulerd
sed -i "s/VERSION=\".*\"/VERSION=\"$NEW_VERSION\"/" system/bin/su-scheduler
sed -i "s/VERSION=\".*\"/VERSION=\"$NEW_VERSION\"/" system/bin/su-schedulerd

# 5. Update update.json using Python for safe JSON handling
python3 -c "
import json, sys
try:
    with open('update.json', 'r') as f:
        data = json.load(f)
    
    data['version'] = 'v$NEW_VERSION'
    data['versionCode'] = $NEW_VERSION_CODE
    data['downloadURL'] = f'https://github.com/rexackermann/su-scheduler/releases/download/v$NEW_VERSION/su-scheduler-v$NEW_VERSION.zip'
    
    if len(sys.argv) > 1 and sys.argv[1]:
        data['changelog'] = sys.argv[1]
        
    with open('update.json', 'w') as f:
        json.dump(data, f, indent=2)
    print('✅ update.json synchronized')
except Exception as e:
    print(f'❌ Error updating update.json: {e}')
    sys.exit(1)
" "$1"

echo "✅ All files synchronized to v$NEW_VERSION"
