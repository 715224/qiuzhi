# 求知 (Qiuzhi)

每天一个名词，15 分钟专注思考，写下自己的解释，再对照标准定义。  
用**费曼学习法**，把「见过」变成「真懂」。

> 示例名词来自内置词库（通用 / 物理 / 哲学 / 心理学 / 工程测量），难度分 低 / 中 / 高。  
> 后续可通过 GitHub 导入词库包，配合 WorkBuddy 自动化实现每日热词更新。

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

### 3. 运行

连接安卓设备或启动模拟器，然后：

```bash
flutter run
```

热重载：保存文件后按 `r`；完整重启按 `R`。

## 后续可扩展

- **GitHub 导入词库包**：从 `raw.githubusercontent.com` 拉取 JSON 词库，实现词库热更新。
- **WorkBuddy 自动化每日热词**：写一个定时任务，每日生成热词 JSON 推送到 GitHub 仓库，App 单向拉取。
- **每日提醒**：接入 `flutter_local_notifications` 做固定时间推送。
- **解释 AI 点评**：将用户解释送往大模型，给出差距与改进建议。

## 技术栈

| 项 | 选型 |
| --- | --- |
| 框架 | Flutter 3.x (Dart) |
| 状态管理 | Provider |
| 本地存储 | shared_preferences |
| 最小 SDK | Dart ≥ 3.0 |
