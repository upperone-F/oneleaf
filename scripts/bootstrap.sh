#!/usr/bin/env bash
# 在已装好 Flutter + Android SDK 的机器上执行一次，补齐 Android 平台原生文件。
# 说明：仓库里已经有 lib/ 和 pubspec.yaml，flutter create 不会覆盖它们，只生成缺失的 android/ 等目录。
set -e

cd "$(dirname "$0")/.."

echo "==> 1/3 生成 Android 平台骨架（只补缺失文件，不动 lib/）"
flutter create . --platforms=android --project-name oneleaf --org com.oneleaf

echo "==> 2/3 拉取依赖"
flutter pub get

echo "==> 3/3 检查环境"
flutter doctor -v

echo ""
echo "完成。接下来用数据线连上安卓机，运行："
echo "  flutter run"
echo "或打包 APK："
echo "  flutter build apk --release"
