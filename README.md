# Oneleaf

一个陪伴你的日记 App。**当前：Android 全功能演示版**——11 个页面全部实现，功能以示例数据驱动，均可点击交互。

## 现在有什么（v0.2.0）

底部导航 5 个入口 + 6 个二级页面，**全部带示例数据、可交互**：

| # | 页面 | 位置 | 可以试的交互 |
|---|------|------|------------|
| 1 | 今日日记 | 底部「日记」 | **沉浸式全屏**：上部 1/3 封面（日期雕在图上、点「换封面」从图库更换）、中部横线纸写作（自动保存）、手势左右翻页。**主动陪伴**：Buddy 常驻封面右下角带呼吸动画，打开时主动提起前几天的事、写字停顿时轻声陪伴、写出「累/烦」等词立即关怀——主动的话可一键「收进日记」或划走。点 Buddy 头像或 `@Buddy` 让它回应，**回应以「@ 小叶：……」直接写进正文下一行**（和你写的话在同一段文本里，如「今天入职成功了 / @ 小叶：恭喜你啊…」），默认保留、像编辑文字一样选中即可删改。主动关怀「收进日记」同样写进正文。底栏可进语音/天气/洞察/分享 |
| 2 | 日历 | 底部「日历」 | 切换月份、点日期看当天日记、状态标记（今天/已写） |
| 3 | Buddy 对话 | 底部「对话」 | 切换 Buddy、发消息；发「记账」出记账卡、「画一张」出绘图卡、问「上次…」出记忆引用卡 |
| 4 | Buddy 市场 | 底部「Buddy」 | 分类筛选、搜索、订阅/取消、看陪伴天数与默契度 |
| 5 | 我的/设置 | 底部「我的」 | 主动关怀/长期记忆/情绪共鸣/应用锁等开关（即时生效） |
| 6 | 陪伴手册 | 二级 | 默契进度、记忆抽屉、关怀开关、陪伴足迹 |
| 7 | 创建 Buddy | 二级 | 三步向导（命名→人设→能力），完成后新 Buddy 自动进市场并订阅 |
| 8 | 天气 | 二级 | 切城市、切今明、24h 趋势、5 天预报、Tina 提示 |
| 9 | 语音 | 二级 | 点麦克风模拟识别转文字、写入日记、切标点/转录模式、TTS 朗读状态 |
| 10 | 洞察 | 二级 | 情绪曲线、关键词云、统计卡、一键生成周报 |
| 11 | 分享预览 | 二级 | 访客只读视角、访问计数、匿名设置、复制示例链接 |

> 这是**可交互的产品雏形**，不是完整功能版：数据是示例/本地演示，语音识别与 TTS 是状态模拟，LLM 可接真实接口。目的是让你完整走一遍产品体验、验证陪伴闭环。

## 运行（环境已装好）

```bash
cd /Users/felixfang/Documents/GitHub/oneleaf
flutter run
# 或打 release 包
flutter build apk --release
```

> 本机 Flutter 在 `~/flutter/bin`，若 `flutter` 不在 PATH，先 `export PATH="$HOME/flutter/bin:$PATH"`。

## 两种模式

- **演示模式（默认，无需配置）**：所有 Buddy 用本地规则即时回应，不发网络请求。日记、对话、订阅、设置等状态存在本机，重启后仍在。
- **真实 LLM 模式**：用 OpenAI 兼容接口让回应更贴心：

```bash
flutter run \
  --dart-define=LLM_BASE_URL=https://api.deepseek.com/v1 \
  --dart-define=LLM_API_KEY=你的key \
  --dart-define=LLM_MODEL=deepseek-chat
```

建议选**明确承诺不用于训练**的服务商——日记很私密。网络失败会自动降级回演示回应。

## 代码结构

```
lib/
├── main.dart                    入口 + 底部导航主壳 + 二级页面路由表
├── config.dart                  运行配置（dart-define 注入）
├── theme.dart                   极简清新配色
├── models/
│   ├── diary.dart               日记模型 + 四档心情 + 日期工具
│   ├── buddy.dart                Buddy 模型 + 6 个内置示例角色
│   └── chat.dart                对话消息模型
├── services/
│   ├── storage.dart             本地存储（shared_preferences）+ 通用状态 KV
│   └── buddy.dart               Buddy 引擎：系统提示词 + LLM + 多角色对话演示
├── state/
│   └── app_state.dart           全局共享状态（ChangeNotifier，零依赖）
├── widgets/
│   └── common.dart              通用组件（头像/卡片/开关行/空态等）
└── screens/                     11 个页面
    ├── journal_screen.dart      日记（核心闭环）
    ├── chat_screen.dart         Buddy 对话
    ├── calendar_screen.dart     日历
    ├── market_screen.dart       Buddy 市场
    ├── settings_screen.dart     我的/设置
    ├── bond_screen.dart         陪伴手册
    ├── create_buddy_screen.dart 创建 Buddy
    ├── weather_screen.dart      天气
    ├── voice_screen.dart        语音
    ├── insights_screen.dart     洞察
    └── share_screen.dart        分享预览
```

设计取舍：零新增依赖（只 `http` / `shared_preferences`），自绘图表、emoji 头像、ChangeNotifier 状态管理，守住轻量原则。`flutter analyze` 无 error/warning，`flutter test` 全绿，`flutter build apk --debug` 成功。

## 相关文档

- `docs/方案A-下载安装清单.md` — 环境下载安装清单
- `docs/开发前置准备清单.md` — 账号与前置准备
- `docs/跨机协作规范.md` — Mac/Windows 协作
- `Oneleaf-工程文档.md` — 完整技术栈与实施路线
- `Oneleaf-产品创意说明.md` — 产品定义与陪伴创新
