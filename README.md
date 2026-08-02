# 求知 (Qiuzhi)

每天一个名词，15 分钟专注思考，写下自己的解释，再对照标准定义。  
用**费曼学习法**，把「见过」变成「真懂」。

> 示例名词来自内置词库（通用 / 物理 / 哲学 / 心理学 / 工程测量），难度分 低 / 中 / 高。  
> 后续可通过 GitHub 导入词库包，配合 WorkBuddy 自动化实现每日热词更新。

> GitHub：https://github.com/715224/qiuzhi<br>
> Gitee：https://gitee.com/ccy1028/the-pursuit-of-knowledge

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
- 独立热词库（按发布日期 / 热词类型分组）
- 词包管理（查看词条、编辑内置/热词词条、新建自定义词包）
- 全局搜索词包、词名、拼音、分类和解释，结果可直接进入词包或词语详细页。
- 每日自动更新热词（以北京时间中午 12:00 为换日分界）
- 每日多词学习目标（可自定义 1–20 个，完成后自动进入下一词）
- 首页学习仪表盘（快速调整抽词范围、今日词单、等级称号与 XP 经验条）
- 用户点击后才开始抽词，像素候选词滚动并逐渐减速，最终揭晓当天词语。
- AI 书籍词包：配置 OpenAI 兼容接口，导入 TXT/Markdown 后逐段分析整本书。
- AI 自动生成词汇难度、标准解释、一句话解释、生活类比、实际应用和常见误区。
- AI 结果保存为普通自定义词包，可参与抽词并继续查看、编辑。
- 内置菜鸟教程递进词包：一级 28 词、二级 95 词、三级 123 词；高等级完整包含低等级内容。
- 本地持久化（SharedPreferences）
- 两套可保存的界面主题：青色像素 / 粉色萌物像素
- 响应式 Web / PWA：窄屏使用手机底部导航，桌面宽屏自动切换左侧导航。

## 网页版

网页版与 Android 版共用同一套 Flutter 业务代码和本地数据结构，支持词包、搜索、
手动抽词、每日目标、等级经验、详情页、历史、收藏以及青色/粉色主题。浏览器数据
保存在当前网站的本地存储中，不会自动与手机端同步。

### 最简单的打开方式

- 双击项目根目录的 `打开网页版.html`，再点击页面中的“打开求知网页版”。
- 如果浏览器限制本地网页运行，直接双击 `启动网页版.bat`，它会自动构建、启动
  本地服务并打开浏览器，不需要输入命令。

### 本地运行

```bash
flutter pub get
flutter run -d chrome
```

### 构建部署包

```bash
flutter build web --release --no-wasm-dry-run
```

可部署到 Gitee Pages、GitHub Pages、Cloudflare Pages、Vercel、Nginx 或其他静态托管。
如果部署在子目录，需要指定对应基础路径，例如：

```bash
flutter build web --release --no-wasm-dry-run --base-href /the-pursuit-of-knowledge/
```

### 安装为桌面应用

通过 HTTPS 打开网站后，可在 Chrome/Edge 地址栏的“安装应用”入口把它安装为 PWA。
若浏览器没有显示安装按钮，请检查网站是否使用 HTTPS，以及 `manifest.json`、图标和
Flutter 生成的 service worker 是否能正常访问。

### 网页版注意事项

- 远程热词和 AI 接口必须允许浏览器跨域请求（CORS）；否则手机端能访问、网页端仍可能失败。
- API Key 会保存在当前浏览器站点存储中；公共电脑上不要保存个人密钥。
- 清除浏览器站点数据会同时清除目标、历史、收藏、自定义词包和模型配置。
- 每日热词仍以北京时间中午 12:00 为分界，并在打开/恢复页面后检查更新。

## 界面主题

打开「我的」→「界面主题」，可在「青色像素」和「粉色萌物」之间即时切换。
选择结果会保存在手机本地，下次启动自动恢复。粉色主题使用专门重绘的低分辨率
像素素材，原始参考图不会打入 APK。

## 目录结构

```
求知/
├── lib/
│   ├── main.dart                 # 入口：Provider + 底部导航
│   ├── models/word.dart          # 名词数据模型
│   ├── data/word_bank.dart       # 示例词库（25 个名词）
│   ├── providers/app_state.dart  # 全局状态：筛选/历史/收藏/持久化
│   ├── theme/pixel_theme.dart     # 青色 / 粉色主题与动态调色板
│   ├── widgets/pixel_ui.dart      # 像素面板、进度条与主题角色
│   └── screens/
│       ├── today_screen.dart     # 今日名词页
│       ├── focus_screen.dart     # 番茄钟锁屏页
│       ├── explain_screen.dart   # 解释输入页
│       ├── result_screen.dart    # 结果对照页
│       ├── history_screen.dart   # 往期回顾
│       ├── favorites_screen.dart # 收藏
│       └── settings_screen.dart  # 我的 / 设置
├── assets/pink_mascot/            # 粉色萌物像素素材
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
