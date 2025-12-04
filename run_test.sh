#!/bin/sh

rm -rf Coverage.xcresult

xcodebuild -scheme 'PCPClient-Package' -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipPackagePluginValidation -derivedDataPath Build/ -enableCodeCoverage YES clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -resultBundlePath Coverage.xcresult test
