# 方案 A · 下载安装清单（Android 开发链 · 自己装）

> 机器：Apple M5（arm64）/ 磁盘可用 387Gi（充足）/ VS Code 已装 / **Homebrew 未装**
> 原则：**不装完整 Android Studio**。只装"JDK + Android SDK + Flutter"三个内核。
> 全部走**手动下载官方 zip/dmg**，不需要 Homebrew。按下面顺序 1→5 装即可。

---

## 0. 先知道总量（心里有数）

| 项 | 下载体积 | 安装后占用 | 说明 |
|----|---------|-----------|------|
| JDK 17 | ~200 MB | ~300 MB | Gradle 编译必需 |
| Android SDK 命令行工具 | ~150 MB | ~300 MB | 用来装 SDK 组件 |
| Android SDK 组件 | — | ~1–1.5 GB | adb / platform / build-tools |
| Flutter SDK | ~2.1 GB（实测 3.50.0 = 2,145,325,654 字节） | ~3–4 GB | 含 Dart、引擎、工具链 |
| VS Code 插件 | 小 | ~100 MB | Dart / Flutter 两个插件 |
| **合计** | **~3.5 GB 下载** | **~6 GB 占用** | 387Gi 空间完全够 |

> 相比之下装完整 Android Studio 会再多约 1GB 安装包 + 数 GB 缓存和模拟器镜像——方案 A 省的就是这部分。

---

## 1. JDK 17（必需）

**下载什么**：Eclipse Temurin JDK 17，macOS **aarch64** 版本（M5 芯片）

- 去哪下：https://adoptium.net/temurin/releases/?version=17&os=mac&arch=aarch64
- 选 `.pkg` 安装包（图形安装最简单），下载约 200MB
- 双击安装，一路下一步即可

**验证**：装完开终端跑
```bash
/usr/libexec/java_home -v 17
java -version
```
应显示 `openjdk version "17.x"`。

> ⚠️ 必须是 **aarch64** 版本，别下成 x64（x64 靠 Rosetta 也能跑，但慢且可能有兼容问题）。

---

## 2. Android SDK 命令行工具（必需）

**下载什么**：Android SDK Command Line Tools（macOS 版 zip）

- 去哪下：https://developer.android.com/studio#command-tools
- 拉到页面最底部 **"Command line tools only"** → 选 **macOS** 的 zip（约 150MB）

**安装（有个经典坑，注意目录结构）**：
```bash
mkdir -p ~/Library/Android/sdk/cmdline-tools
# 把下载的 zip 解压，解压出来是个 cmdline-tools 文件夹
# 把它改名为 latest，移到上面目录里，最终路径必须是：
#   ~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager
mv ~/Downloads/cmdline-tools ~/Library/Android/sdk/cmdline-tools/latest
```
> 关键：`sdkmanager` 必须在 `cmdline-tools/latest/bin/` 下，否则会报 "Could not determine SDK root"。

---

## 3. 用 sdkmanager 装 SDK 组件（必需）

不单独下载，用上一步的 `sdkmanager` 命令行装：

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH

# 先接受许可（一路 y）
sdkmanager --licenses

# 装三个核心组件
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
```

- `platform-tools` 里含 **adb**（连真机调试用）
- `platforms;android-36` / `build-tools;36.0.0` 是编译目标（版本号按 Flutter 提示调整，装最新即可）

**验证**：
```bash
adb --version
```

---

## 4. Flutter SDK（必需）

**下载什么**：Flutter 稳定版，macOS **arm64** 芯片版本

- 官方安装页：https://docs.flutter.dev/get-started/install/macos/mobile-arm
- **当前最新稳定版：3.50.0**（Dart 3.14.0，2026-10 发布）。已实测国内镜像 arm64 包可下载（约 2.1GB）：
```bash
curl -O https://storage.flutter-io.cn/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.50.0-stable.zip
```
- ⚠️ 别用旧版本号（如 3.35.5 是 2025-09 的老版本，虽然链接仍有效）；**新项目直接用最新 stable**。官方源把域名换成 `storage.googleapis.com`，路径相同。
- 版本核对：https://docs.flutter.dev/release/archive 或国内 https://docs.flutter.cn/install/archive

**安装**：
```bash
# 解压到一个固定位置，比如主目录
unzip ~/Downloads/flutter_macos_arm64_*.zip -d ~
export PATH="$HOME/flutter/bin:$PATH"
```

**验证**：
```bash
flutter --version
flutter doctor
```

> `flutter doctor` 会检查 Android 工具链——只要 Android 相关项全打 ✅，开发链就成了。
> 首次 `flutter run` 会自动下载 Gradle 等依赖（约几百 MB），耐心等一次即可。

**关于 FVM（可选，建议后期加）**：FVM 用来锁定 Flutter 版本、保证 Mac/Windows 两机一致。你现在单机单版本可以先不装，减负。等真正两机开发时再装（届时 `dart pub global activate fvm`，用它管理已下载的 Flutter）。跨机版本一致性按《跨机协作规范.md》处理。

---

## 5. VS Code 插件（必需，VS Code 你已装）

在 VS Code 扩展市场（左侧方块图标）搜装这两个：

- [ ] **Dart**（发布者 Dart-Code.dart-code）
- [ ] **Flutter**（发布者 Dart-Code.flutter）

装完按 `Cmd+Shift+P` → 输入 `Flutter: Run Flutter Doctor`，确认无报错。

> 小提示：如果终端里想用 `code .` 打开项目，在 VS Code 里 `Cmd+Shift+P` → "Shell Command: Install 'code' command in PATH"。不装也不影响开发。

---

## 6. 环境变量（写进 `~/.zshrc`，一次到位）

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```
改完 `source ~/.zshrc` 生效。这几行 **Mac/Windows 概念一致**（Windows 在"系统属性→环境变量"里设，路径换成你的安装位置）。

---

## 7. 最终验证（全绿 = 开发链就绪）

```bash
java -version                 # openjdk 17.x
adb --version                 # adb 版本信息
flutter doctor                # Flutter / Android toolchain / 已连接设备 全 ✅
adb devices                   # 插上你的安卓机，能看到设备序列号（含 unauthorized→弹窗点允许）
flutter devices               # 能看到你的安卓机
```

把安卓机用数据线连上、开启「开发者选项 + USB 调试」，首次连接手机弹窗点「允许」，`adb devices` 显示 `device` 就通了。

---

## 可选（不在 Android 开发链内，按需再装）

- [ ] **Docker Desktop** — 后端 PostgreSQL/pgvector 用，不是写 App 的必需项；等做后端时再装（https://www.docker.com/products/docker-desktop/ ，选 Apple Silicon 版）
- [ ] **FVM** — 见第 4 节，两机开发时再加

---

## 常见坑速查

| 现象 | 原因 | 解决 |
|------|------|------|
| sdkmanager 报 "Could not determine SDK root" | 解压目录结构不对 | 确保路径是 `cmdline-tools/latest/bin/sdkmanager` |
| `flutter doctor` 说 Android license 未接受 | license 没点 | 跑 `sdkmanager --licenses` 一路 y |
| adb devices 显示 `unauthorized` | 手机没点允许 | 手机弹窗点「允许 USB 调试」 |
| Java 版本不对 / 找不到 | 装成 x64 或没配 JAVA_HOME | 确认 aarch64 版，`export JAVA_HOME=$(/usr/libexec/java_home -v 17)` |
| Gradle 首次卡很久 | 首次下载依赖 | 正常，挂 Amazon/清华镜像可加速（需要时再配） |
