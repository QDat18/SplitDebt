#!/bin/bash
# Cài đặt một lần trên máy Mac trước khi chạy SplitDebt trên iOS.
# Chạy từ thư mục frontend:  bash ios/setup_ios.sh
set -e

cd "$(dirname "$0")/.."

echo "==> Bật Swift Package Manager (ML Kit trên iOS dùng SwiftPM)"
flutter config --enable-swift-package-manager

echo "==> flutter pub get"
flutter pub get

echo "==> Tải model ML Kit (LatinOCRResources.bundle)"
MLKIT_VERSION="9.0.3"
DEST="ios/Runner/mlkit"
mkdir -p "$DEST"
if [ ! -d "$DEST/LatinOCRResources.bundle" ]; then
  TMP="$(mktemp -d)"
  curl -fL -o "$TMP/LatinOCRResources.bundle.zip" \
    "https://github.com/d-date/google-mlkit-swiftpm/releases/download/${MLKIT_VERSION}/LatinOCRResources.bundle.zip"
  unzip -q -o "$TMP/LatinOCRResources.bundle.zip" -d "$DEST"
  rm -rf "$TMP"
fi
ls "$DEST"

echo "==> pod install"
cd ios
pod install --repo-update
cd ..

if [ ! -f .env ]; then
  echo "!! Chưa có frontend/.env. Chép .env từ máy Windows sang (không có trong git)."
fi

echo "Xong. Mở Xcode chọn Team ký app (một lần):  open ios/Runner.xcworkspace"
echo "Chạy app:  flutter run"
