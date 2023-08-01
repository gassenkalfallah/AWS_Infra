#!/bin/bash

type=$1

# Get current version
VERSION=$(cat VERSION.txt)

# Parse current version into parts
MAJOR=$(echo $VERSION | cut -d. -f1)
MINOR=$(echo $VERSION | cut -d. -f2)
PATCH=$(echo $VERSION | cut -d. -f3)

# Increment version based on arguments
if [ "$type" == "major" ]; then
    MAJOR=$((MAJOR+1))
    MINOR=0
    PATCH=0
elif [ "$type" == "minor" ]; then
    MINOR=$((MINOR+1))
    PATCH=0
elif [ "$type" == "patch" ]; then
    PATCH=$((PATCH+1))
elif [ "$type" == "restart" ]; then
    MAJOR=0
    MINOR=0
    PATCH=0
else
    MAJOR=$((MAJOR))
    MINOR=$((MINOR))
    PATCH=$((PATCH))
fi

# Update version file sqcl;sdvsmdgvdgvsddg
echo "$MAJOR.$MINOR.$PATCH" > VERSION.txt
# Print new version sdvsdfsdfsvsf
echo "New version: $(cat VERSION.txt)"


