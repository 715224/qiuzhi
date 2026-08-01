# 每日热词目录

此目录是「求知」App 的每日热词发布区。目录名固定为 `daily_hotwords`，请勿改成中文或随意重命名，以免 GitHub CDN/Raw 路径编码造成拉取失败。

## 目录结构

```text
daily_hotwords/
├── README.md                         # 本说明
├── AUTOMATION.md                     # 每日自动推送执行规范
├── manifest.json                     # 当前版本与归档位置
├── words.json                        # App 稳定入口，每日覆盖更新
├── library.json                      # App 热词总库，每日追加且不覆盖往日
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
| App 累计热词库 | `library.json` | `daily_hotwords/library.json` |
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
  "publishedDate": "2026-08-01",
  "category": "科技",
  "simpleExplanation": "就是让电脑从很多资料里学会理解和回答问题。",
  "lifeAnalogy": "像一个读过很多书的学生，能根据学过的内容回答新问题。",
  "practicalApplication": "可以用于智能客服、资料整理、写作辅助和程序开发。",
  "commonMisconception": "大模型生成的内容不一定正确，不能把流畅回答当成事实。",
  "definition": "基于海量数据训练、能完成语言理解与生成等任务的超大参数神经网络模型。"
}
```

字段约束：

- `field`：`通用`、`物理`、`哲学`、`心理学`、`工程测量`之一。
- `difficulty`：`低`、`中`、`高`之一。
- `pack`：固定为 `每日热词`。
- `publishedDate`：发布日期，格式为 `YYYY-MM-DD`，用于 App 按时间分类。
- `category`：取 `科技 / 财经 / 社会 / 科学 / 文化 / 教育 / 健康 / 心理 / 生活 / 其他`，用于 App 按类型分类。
- `definition`：使用完整中文句子，不写链接，不包含 Markdown。
- `simpleExplanation`：一句小学生也能听懂的概括。
- `lifeAnalogy`：一个具体、容易联想的生活类比。
- `practicalApplication`：说明日常生活或工作中的实际用途。
- `commonMisconception`：指出一个最常见的理解误区。
- 文件编码：UTF-8，无 BOM。

## 每日发布流程

1. 复制 `templates/daily.template.json`，填写当天热词。
2. 保存为 `archive/YYYY/MM/YYYY-MM-DD.json`。
3. 将相同的 JSON 数组覆盖写入 `words.json`。
4. 将当天数组追加到 `library.json`，按 `id` 去重，保留往日词条。
5. 更新 `manifest.json` 的时间、归档路径与词条数量。
6. 提交到 GitHub，提交信息使用 `hotwords: publish YYYY-MM-DD`。

不要让 `words.json` 指向归档文件，也不要每天更改 App 配置地址。App 始终读取稳定入口，归档只用于审计和回溯。

## 发布后的访问地址

仓库推送后，App 可继续填写仓库主页：

```text
https://github.com/715224/qiuzhi
```

App 会优先自动寻找：

```text
daily_hotwords/library.json
```

对应的 CDN 地址为：

```text
https://cdn.jsdelivr.net/gh/715224/qiuzhi@master/daily_hotwords/words.json
```
