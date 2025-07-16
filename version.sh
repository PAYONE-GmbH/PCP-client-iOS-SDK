#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: sh $0 <version>"
  exit 1
fi

VERSION="$1"

# Update version in PCPClient.podspec
sed -i '' "s/\(s.version[[:space:]]*=[[:space:]]*'\)[^']*\('.*\)/\1$VERSION\2/" PCPClient.podspec

# Update version in README.md (SPM and CocoaPods examples)
sed -i '' "s/\(from: \"\)[^\"]*\(\"\)/\1$VERSION\2/g" README.md

# Create git tag
git tag -a "$VERSION" -m "$VERSION"

echo "Version updated to $VERSION in PCPClient.podspec and README.md"