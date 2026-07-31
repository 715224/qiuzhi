# 求知 (Qiuzhi)

每天一个名词，15 分钟专注思考，写下自己的解释，再对照标准定义。  
用**费曼学习法**，把「见过」变成「真懂」。

> 示例名词来自内置词库（通用 / 物理 / 哲学 / 心理学 / 工程测量），难度分 低 / 中 / 高。  
> 后续可通过 GitHub 导入词库包，配合 WorkBuddy 自动化实现每日热词更新。

> 项目仓库：https://github.com/715224/qiuzhi（公共仓库，本机 `C:\Users\16195\Desktop\求知` 已通过 git 连接，可随时 `git push` 更新。）

---

## 核心流程

1. **今日名词**：每天按「日期 + 领域 + 难度」确定性抽取一个名词（不显示答案）。
2. **开始求知**：进入深色全屏「番茄钟锁屏」，环形进度 + 15 分钟专注计时，只有一个低调的「提前结束」按钮。
3. **写下解释**：计时结束后，用你自己的话解释这个词（费曼关键一步）。
4. **对照结果**：你写的解释 vs 标准定义并列展示，可收藏、记入往期。

## 功能

- 今日名词（确定性每日抽取）
- 15 分钟番茄钟锁屏专注
- 解释输入与标准定义对照
- 领域选择（通用 / 物理 / 哲学 / 心理学 / 工程测量）
- 难度选择（低 / 中 / 高，默认中）
- 词库包开关（通用知识包 / 哲学包 / 心理学术语包 / 工程测量术语包）
- 往期回顾、收藏
- 本地持久化（SharedPreferences）

## 目录结构

```
求知/
├── lib/
│   ├── main.dart                 # 入口：Provider + 底部导航
│   ├── models/word.dart          # 名词数据模型
│   ├── data/word_bank.dart       # 示例词库（25 个名词）
│   ├── providers/app_state.dart  # 全局状态：筛选/历史/收藏/持久化
│   └── screens/
│       ├── today_screen.dart     # 今日名词页
│       ├── focus_screen.dart     # 番茄钟锁屏页
│       ├── explain_screen.dart   # 解释输入页
│       ├── result_screen.dart    # 结果对照页
│       ├── history_screen.dart   # 往期回顾
│       ├── favorites_screen.dart # 收藏
│       └── settings_screen.dart  # 我的 / 设置
├── pubspec.yaml
└── analysis_options.yaml
```

## 在本地运行

> 当前仓库只包含 Dart 源码，**尚未包含** `android/`、`ios/` 等平台目录。  
> 需要先安装 Flutter，再生成平台目录。

### 1. 安装 Flutter

参考官方文档：https://docs.flutter.dev/get-started/install

安装后确认环境：

```bash
flutter doctor
```

请确保 Android 工具链可用（Android Studio / SDK），本应用当前面向 Android。

### 2. 生成平台目录并安装依赖

在 `求知/` 目录下执行：

```bash
flutter create .
flutter pub get
```

`flutter create .` 会补全 `android/`、`ios/` 等目录，**不会覆盖 `lib/` 下的代码**。

> ⚠️ **联网权限**：远程词库需要联网。请确认 `android/app/src/main/AndroidManifest.xml`
> 的 `<manifest>` 内已包含（Flutter 默认可能没有）：
> ```xml
> <uses-permission android:name="android.permission.INTERNET"/>
> ```

### 3. 运行

连接安卓设备或启动模拟器，然后：

```bash
flutter run
```

热重载：保存文件后按 `r`；完整重启按 `R`。

## 远程词库（每日热词 / GitHub 导入）

App 支持从 GitHub 拉取远程词库，实现每日热词更新。**已内置实现**，配置即用。

### 1. 准备 words.json

在 GitHub 新建一个公开仓库，放一个 `words.json`，内容是一个名词数组：

```json
[
  {
    "id": 1001,
    "word": "大模型",
    "pinyin": "dà mó xíng",
    "field": "通用",
    "difficulty": "中",
    "pack": "每日热词",
    "definition": "基于海量数据训练、能完成语言理解与生成等任务的超大参数神经网络模型。"
  },
  {
    "id": 1002,
    "word": "具身智能",
    "pinyin": "jù shēn",
    "field": "通用",
    "difficulty": "高",
    "pack": "每日热词",
    "definition": "将感知、决策与身体行动结合，在真实环境中完成任务的智能体。"
  }
]
```

> 字段说明：`pack` 建议统一填 `每日热词`（与 App 里的远程包名对应）；
> `field` 取「通用 / 物理 / 哲学 / 心理学 / 工程测量」之一；`difficulty` 取「低 / 中 / 高」。
> 缺失字段会自动补默认值，不会导致崩溃。

### 2. 拿到 raw 地址

在仓库里打开 `words.json` → 点击 **Raw** → 复制浏览器地址，形如：

```
https://raw.githubusercontent.com/<你的用户名>/<仓库名>/main/words.json
```

### 3. 在 App 里配置

打开「我的」→「每日热词（GitHub 远程）」，粘贴上面的地址 → 点「应用并刷新」。
App 会立即拉取并缓存；之后**每次打开 App 都会静默刷新一次**（断网则用上次缓存）。
拉取成功后在「词库包」里会出现「每日热词」开关，打开后它就参与每日抽取。

### 4. 配合 WorkBuddy 自动化做每日更新

由 WorkBuddy 自动化每天生成新的 `words.json` 并推送到该 GitHub 仓库，App 单向拉取即可。
内容生产在自动化侧，App 逻辑保持轻量。（自动化任务可在 App 骨架与仓库就绪后用 `automation_update` 创建。）

## 后续可扩展

- **每日提醒**：接入 `flutter_local_notifications` 做固定时间推送。
- **解释 AI 点评**：将用户解释送往大模型，给出差距与改进建议。
- **多远程源**：支持配置多个 GitHub 仓库 / 分支，按包名分别开关。

## 技术栈

| 项 | 选型 |
| --- | --- |
| 框架 | Flutter 3.x (Dart) |
| 状态管理 | Provider |
| 本地存储 | shared_preferences |
| 最小 SDK | Dart ≥ 3.0 |
