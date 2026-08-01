# 每日热词目录

此目录是「求知」App 的每日热词发布区。目录名固定为 `daily_hotwords`，请勿改成中文或随意重命名，以免 GitHub CDN/Raw 路径编码造成拉取失败。

## 目录结构

```text
daily_hotwords/
├── README.md                         # 本说明
├── AUTOMATION.md                     # 每日自动推送执行规范
├── manifest.json                     # 当前版本与归档位置
├── words.json                        # App 稳定入口，每日覆盖更新
├── archive/
│   └── YYYY/MM/YYYY-MM-DD.json       # 每日不可变归档
├── schema/
│   └── words.schema.json             # JSON Schema
└── templates/
    └── daily.template.json           # 新建每日内容的模板
```

## 固定命名规则

| 类型 | 命名 | 示例 |
|---|---|---|
| App 稳定入口 | `words.json` | `daily_hotwords/words.json` |
| 每日归档 | `archive/YYYY/MM/YYYY-MM-DD.json` | `archive/2026/08/2026-08-01.json` |
| 词条 ID | `YYYYMMDDNN` | `2026080101` |
| Git 提交信息 | `hotwords: publish YYYY-MM-DD` | `hotwords: publish 2026-08-01` |

其中 `NN` 是当天两位序号，从 `01` 开始。ID 必须是整数且全库唯一。

## 词库 JSON 格式

根节点必须是数组。每条词必须包含以下字段：

```json
{
  "id": 2026080101,
  "word": "大模型",
  "pinyin": "dà mó xíng",
  "field": "通用",
  "difficulty": "中",
  "pack": "每日热词",
  "definition": "基于海量数据训练、能完成语言理解与生成等任务的超大参数神经网络模型。"
}
```

字段约束：

- `field`：`通用`、`物理`、`哲学`、`心理学`、`工程测量`之一。
- `difficulty`：`低`、`中`、`高`之一。
- `pack`：固定为 `每日热词`。
- `definition`：使用完整中文句子，不写链接，不包含 Markdown。
- 文件编码：UTF-8，无 BOM。

## 每日发布流程

1. 复制 `templates/daily.template.json`，填写当天热词。
2. 保存为 `archive/YYYY/MM/YYYY-MM-DD.json`。
3. 将相同的 JSON 数组覆盖写入 `words.json`。
4. 更新 `manifest.json` 的时间、归档路径与词条数量。
5. 提交到 GitHub，提交信息使用 `hotwords: publish YYYY-MM-DD`。

不要让 `words.json` 指向归档文件，也不要每天更改 App 配置地址。App 始终读取稳定入口，归档只用于审计和回溯。

## 发布后的访问地址

仓库推送后，App 可继续填写仓库主页：

```text
https://github.com/715224/qiuzhi
```

App 会优先自动寻找：

```text
daily_hotwords/words.json
```

对应的 CDN 地址为：

```text
https://cdn.jsdelivr.net/gh/715224/qiuzhi@master/daily_hotwords/words.json
```
