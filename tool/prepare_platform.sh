#!/usr/bin/env bash
# android/ ও ios/ ফোল্ডার তৈরি করে BSR-এর জন্য প্রয়োজনীয় সেটিং বসায়।
set -euo pipefail
cd "$(dirname "$0")/.."
[ -d android ] || flutter create --platforms=android,ios --org com.bdservicerules --project-name bsr .
M=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.INTERNET' "$M" || sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <application#' "$M"
sed -i 's#android:label="bsr"#android:label="BSR"#' "$M"
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] && sed -i -E 's/minSdk(Version)?\s*=?\s*flutter\.minSdkVersion/minSdk = 23/' "$f" || true
done
