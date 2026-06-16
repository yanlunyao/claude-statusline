# claude-statusline

Claude Code 终端底部状态栏，实时显示上下文 token 用量。

```
[Opus] Ctx: 37% (74k/200k)
```

颜色编码：
- 绿色：< 50%
- 黄色：50% ~ 79%
- 红色：>= 80%

## 快速安装

```bash
git clone https://github.com/yanlunyao/claude-statusline.git
cd claude-statusline
bash setup.sh
```

然后重启 Claude Code 即可。

## 依赖

- [jq](https://jqlang.github.io/jq/) — JSON 命令行工具（setup.sh 会自动安装）
- Claude Code

## 手动安装

如果不想用 setup.sh：

```bash
# 1. 复制脚本
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# 2. 在 ~/.claude/settings.json 里加：
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

## 工作原理

Claude Code 在每次对话变化时，通过 stdin 向脚本传入 JSON 数据，包含：
- `model.display_name` — 模型名
- `context_window.context_window_size` — 上下文窗口大小
- `context_window.total_input_tokens` — 已用输入 token
- `context_window.total_output_tokens` — 已用输出 token

脚本解析 JSON，计算百分比，输出带颜色的格式化字符串。

## 自定义

编辑 `~/.claude/statusline.sh`，可用的 JSON 字段：

| 字段 | 说明 |
|------|------|
| `model.id` | 完整模型 ID |
| `model.display_name` | 模型短名 |
| `context_window.context_window_size` | 上下文窗口大小 |
| `context_window.total_input_tokens` | 输入 token 数 |
| `context_window.total_output_tokens` | 输出 token 数 |
| `cost.total_cost_usd` | 本次会话费用（美元） |
| `cost.total_duration_ms` | 总耗时 |
| `workspace.current_dir` | 当前目录 |

## License

MIT
