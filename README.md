# Oneleaf

一个陪伴你的日记 App。**当前：Android MVP**——一个 Buddy（小叶）、一页日记、一段记得你的回应。

## MVP 验证什么

> 当有人记得你说过的话、在意你的心情时，你会不会更愿意写下去？

MVP 只做三步闭环：**写下今天 + 选心情 → 小叶有温度地回应 → 下次打开它提起你前几天写过的事**。其余功能（天气/日历/语音/多 Buddy/市场/后端）一概暂缓。

## 运行（需先装好 Flutter + Android SDK，见 docs/方案A-下载安装清单.md）

```bash
# 首次：补齐 Android 平台原生文件 + 拉依赖 + 环境自检（只需一次）
bash scripts/bootstrap.sh

# 连上安卓机（开启 USB 调试），运行
flutter run

# 或打 release 包
flutter build apk --release
```

## 两种模式

**1. 演示模式（默认，无需任何配置）**
不配 API Key 时自动进入。小叶用本地规则生成回应，仍会接住你的心情、提起前几天写过的事——完整闭环可体验。App 右上角会显示「演示模式」标记。

**2. 真实 LLM 模式（推荐，回应更贴心）**
用 OpenAI 兼容接口，启动时用 `--dart-define` 注入（Key 不写进源码、不入库）：

```bash
flutter run \
  --dart-define=LLM_BASE_URL=https://api.deepseek.com/v1 \
  --dart-define=LLM_API_KEY=你的key \
  --dart-define=LLM_MODEL=deepseek-chat
```

- `LLM_BASE_URL`：兼容 OpenAI 的地址（OpenAI / DeepSeek / 通义 / Moonshot 等）
- `LLM_API_KEY`：API Key
- `LLM_MODEL`：模型名
- 建议选**明确承诺不用于训练**的服务商——日记很私密。
- 网络失败会自动降级回演示回应，闭环不会断。

## 代码结构

```
lib/
├── main.dart                    入口
├── config.dart                  运行配置（dart-define 注入，含演示模式判断）
├── theme.dart                   极简清新配色
├── models/diary.dart            日记模型 + 四档心情 + 日期工具
├── services/
│   ├── storage.dart             本地存储（shared_preferences），含「记忆回流」取最近日记
│   └── buddy.dart               Buddy 引擎：系统提示词 + LLM 调用 + 演示降级
└── screens/journal_screen.dart  唯一页面：日记 + 心情 + 回应 + 翻页
```

设计取舍：MVP 用 `setState` + `shared_preferences`，依赖极少（只有 http / shared_preferences）。后期迁移 Riverpod / drift 时只需替换 services 层，UI 无感。

## 相关文档

- `docs/方案A-下载安装清单.md` — 环境下载安装清单
- `docs/开发前置准备清单.md` — 账号与前置准备
- `docs/跨机协作规范.md` — Mac/Windows 协作
- `Oneleaf-工程文档.md` — 完整技术栈与实施路线
- `Oneleaf-产品创意说明.md` — 产品定义与陪伴创新
