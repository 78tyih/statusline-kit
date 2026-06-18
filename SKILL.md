---
name: statusline-kit
description: >-
  安装、解析、自定义 Claude Code 两行 status line(上下文/花费/Token/模型/项目位置)。
  当用户想装状态栏、改状态栏颜色、看每个字段含义、或把这套 status line 搬到别的机器时使用。
  Use when the user wants to install, recolor, or understand the Claude Code two-line status line.
---

# Statusline Kit

一套现成的 Claude Code 两行状态栏:**第一行是实时指标(上下文/花费/Token),第二行是身份信息(模型/分支/项目位置)**。每个数值都用不同颜色区分,一眼能读。

脚本通过 stdin 接收 Claude Code 注入的 JSON,输出两行带 ANSI 颜色的文本。

## 字段速查(以屏幕显示顺序)

### 第一行 — 实时指标
| 显示 | 含义 | JSON 来源 | 颜色 |
|------|------|-----------|------|
| `📄 ████░░ 42%` | **上下文** 占用进度条 + 百分比 | `.context_window.used_percentage` | 118 lime 青柠 |
| `💰 $1.23` | 本会话 **花费**(美元) | `.cost.total_cost_usd` | 220 gold 金 |
| `· $0.80/hr` | 燃烧率(每小时,需 ccusage) | `ccusage statusline` | 208 orange 橙 |
| `✏️ +120 -30` | 本会话增/删行数 | `.cost.total_lines_added/removed` | 48 翠绿 / 203 珊瑚红 |
| `🔑 0.10M` | **当前窗口** Token 消耗(百万) | `.context_window.total_input_tokens` | 81 cyan 青 |
| `/2.40M` | 会话累计 Token(读 transcript 求和) | `.transcript_path` 逐行 usage | 141 violet 紫 |

> emoji 图标:📄上下文 / 💰花费 / ✏️ 改动行数 / 🔑Token。终端用 Apple Color Emoji 彩色渲染;`✏️` 后补一个空格防变体选择符占位糊。不想要 emoji 就把 `line2=` 那几行的 emoji 换回 `${GRAY}Context${RESET}` 之类文字标签即可。

### 第二行 — 身份信息
| 显示 | 含义 | JSON 来源 | 颜色 |
|------|------|-----------|------|
| `Opus 4.8` | 当前**模型**(自动缩短,去掉 `(1M context)`) | `.model.display_name` | 213 orchid 兰 |
| `git:(main*)` | git 分支(`*`=有改动) | `.git.branch` / `.git.dirty` | 108 sage 鼠尾草 |
| `~/projects/xxx` | 当前窗口所在**项目位置** | `.cwd`(`$HOME`→`~`) | 110 steel 钢蓝 |

> 注:脚本里物理顺序是 `line1`=身份、`line2`=指标,但末尾 `echo "$line2"` 先于 `echo "$line1"`,所以**屏幕上指标在上、身份在下**。

## 安装

1. 拷贝脚本到目标机:
   ```bash
   mkdir -p ~/.claude
   cp scripts/statusline.sh ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```
2. 在 `~/.claude/settings.json` 注册:
   ```json
   {
     "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
   }
   ```
3. 重开一个 Claude Code 会话即可看到。

**依赖**:`jq`(必需)、`python3`(算会话累计 Token,缺了只是不显示 `/x.xxM`)、`ccusage`(可选,显示 `$/hr` 燃烧率,缺了静默跳过)。

## 自定义颜色

脚本顶部 `# Distinct accent palette` 区块集中定义了每个指标的颜色,改这里即可,不用动渲染逻辑:

```bash
C_CTX='\033[38;5;118m'    # 上下文 %
C_COST='\033[38;5;220m'   # 花费
C_RATE='\033[38;5;208m'   # 燃烧率
C_ADD='\033[38;5;48m'     # 增行
C_DEL='\033[38;5;203m'    # 删行
C_TOKW='\033[38;5;81m'    # 当前窗口 Token
C_TOKS='\033[38;5;141m'   # 会话累计 Token
C_MODEL='\033[38;5;213m'  # 模型
C_GIT='\033[38;5;108m'    # 分支
C_PATH='\033[38;5;110m'   # 项目位置
```

格式是 256 色:`\033[38;5;<N>m`,`N` 取 0–255。挑色板:
```bash
for i in {16..231}; do printf "\033[38;5;${i}m%3d\033[0m " $i; [ $(((i-15)%12)) -eq 0 ] && echo; done
```
**原则**:相邻字段用对比色,别让两个值撞同一色(本套之前 Context/Cost/Tok 都是 81 青色,已拆开)。

## 本地测试(不开会话)

```bash
echo '{"model":{"display_name":"Opus 4.8 (1M context)"},"cwd":"'"$HOME"'/projects/demo","context_window":{"used_percentage":42.5,"total_input_tokens":104900},"cost":{"total_cost_usd":1.23,"total_lines_added":120,"total_lines_removed":30,"total_duration_ms":600000},"git":{"branch":"main","dirty":true}}' | bash ~/.claude/statusline.sh
```

## 改布局/加字段

- 加字段:先 `jq -r '.字段 // 默认'` 解析,再 append 到 `line1`/`line2`,套 `${颜色}...${RESET}`。
- 调上下顺序:改文件末尾两行 `echo` 的先后。
- 进度条宽度/字符:`make_bar <pct> <width> <color>`,字符在函数里的 `█`/`░`。
