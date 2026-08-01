# 每日自动推送执行规范

建议每天在 `Asia/Shanghai` 时区固定时间执行一次。

## 自动化输入

- 日期：`YYYY-MM-DD`
- 每日词条数：建议 3 条
- 允许领域：通用、物理、哲学、心理学、工程测量
- 允许难度：低、中、高
- 固定词库包：每日热词

## 自动化必须完成的动作

1. 生成 3 条不重复、定义准确且适合费曼式学习的中文热词。
2. 按 `YYYYMMDDNN` 生成整数 ID，`NN` 从 `01` 开始。
3. 输出符合 `schema/words.schema.json` 的 JSON 数组。
4. 将数组同时写入：
   - `daily_hotwords/words.json`
   - `daily_hotwords/archive/YYYY/MM/YYYY-MM-DD.json`
5. 更新 `daily_hotwords/manifest.json`：
   - `updatedAt`
   - `sourceFile`
   - `wordCount`
6. 确认 JSON 为 UTF-8、可解析、ID 无重复、字段值合法。
7. Git 提交信息固定为 `hotwords: publish YYYY-MM-DD`。

## 内容质量要求

- 不直接复制新闻标题；选取标题背后的可解释概念。
- 定义控制在 35～100 个汉字，避免循环定义。
- 拼音使用带声调的拉丁字母。
- 同一天避免三个词属于同一狭窄主题。
- 不删除历史归档，不修改已经发布的旧归档；勘误另作提交说明。

## 失败处理

- 任一步验证失败时，不覆盖 `words.json`，不提交 Git。
- GitHub 推送失败时保留本地归档，下一次运行先重试推送。
- 当天归档已存在时停止执行，避免重复生成与覆盖。
