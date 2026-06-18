---
name: statusline-kit
description: >-
  安装、解析、自定义 Claude Code 两行 status line(CC-statusline-kit)。两档:Calm 抗焦虑档(只显示上下文余量+目录)与 Full 完整档(上下文/花费/Token/模型/分支/路径)。
  当用户想装状态栏、切换 Calm/Full 档、改颜色或预警阈值、看字段含义、或搬到别的机器时使用。
  Use when the user wants to install, switch modes, recolor, or understand the Claude Code status line.
---

# CC-statusline-kit

一套 Claude Code 两行状态栏,核心理念:**状态栏该让人安心,不是让人更忙**。市面头部都在卷信息密度(powerline/成本投影/缓存命中率…),字段越多越要用眼睛搜,反而制造"多线程焦虑"。本 kit 反向定位,默认只回答两个问题:

> **「还能聊多久?」** 上下文余量 · **「我在哪?」** 目录

脚本通过 stdin 接收 Claude Code 注入的 JSON,输出带 ANSI 颜色的文本。

## 两档

| 档位 | 脚本 | 显示 | 适用 |
|------|------|------|------|
| **Calm 抗焦虑档**(默认) | `scripts/statusline.sh` | 上下文余量条 + 目录 | 专注、抗仪表盘焦虑 |
| **Full 完整档** | `scripts/statusline-full.sh` | 上下文·花费·改动·Token + 模型·分支·路径 | 确实想看全部指标 |

切档:把对应脚本 `cp` 到 `~/.claude/statusline.sh` 即可。

## Calm 档字段(默认)

| 显示 | 符号名 | 含义 | 颜色 |
|------|--------|------|------|
| `Context left ██████░░ 58%` | 气量表 | 上下文**剩余**额度(非已用),三档红绿灯 | 绿118>50% / 金220 20-50% / 红203<20% |
| `~/projects/xxx` | 坐标 | 当前目录(`$HOME`→`~`) | 110 钢蓝 |
| `git:(main*)` | 航道 | git 分支(`*`=有改动) | 108 鼠尾草 |

> 预警阈值(50% / 20%)在 `scripts/statusline.sh` 的 `if [ $left_pct ... ]` 块改;三色在 `C_OK`/`C_WARN`/`C_LOW`。

## Full 档字段速查(以屏幕显示顺序)

### 第一行 — 实时指标
| 显示 | 含义 | JSON 来源 | 颜色 |
|------|------|-----------|------|
| `Context ████░░ 42%` | **上下文** 占用进度条 + 百分比 | `.context_window.used_percentage` | 118 lime 青柠 |
| `Cost $1.23` | 本会话 **花费**(美元) | `.cost.total_cost_usd` | 220 gold 金 |
| `· $0.80/hr` | 燃烧率(每小时,需 ccusage) | `ccusage statusline` | 208 orange 橙 |
| `+120 -30` | 本会话增/删行数 | `.cost.total_lines_added/removed` | 48 翠绿 / 203 珊瑚红 |
| `Tok 0.10M` | **当前窗口** Token 消耗(百万) | `.context_window.total_input_tokens` | 81 cyan 青 |
| `/2.40M` | 会话累计 Token(读 transcript 求和) | `.transcript_path` 逐行 usage | 141 violet 紫 |

### 第二行 — 身份信息
| 显示 | 含义 | JSON 来源 | 颜色 |
|------|------|-----------|------|
| `Opus 4.8` | 当前**模型**(自动缩短,去掉 `(1M context)`) | `.model.display_name` | 213 orchid 兰 |
| `git:(main*)` | git 分支(`*`=有改动) | `.git.branch` / `.git.dirty` | 108 sage 鼠尾草 |
| `~/projects/xxx` | 当前窗口所在**项目位置** | `.cwd`(`$HOME`→`~`) | 110 steel 钢蓝 |

> 注:Full 档脚本里物理顺序是 `line1`=身份、`line2`=指标,但末尾 `echo "$line2"` 先于 `echo "$line1"`,所以**屏幕上指标在上、身份在下**。

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
