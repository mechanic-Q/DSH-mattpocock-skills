<p>
  <a href="https://www.aihero.dev/s/skills-newsletter">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skills-repo-dark_2x.png">
      <source media="(prefers-color-scheme: light)" srcset="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skill-repo-light_2x.png">
      <img alt="Skills" src="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skill-repo-light_2x.png" width="369">
    </picture>
  </a>
</p>

# Skills For Real Engineers（DSH 版）

> **这是 [mattpocock/skills](https://github.com/mattpocock/skills) 的 DSH 版**：面向 [DeepSeek Harness](https://github.com/deepseek-ai) 的适配。**技能一个不改名、不删减**，只做让它能在 DSH 里完整跑起来所必需的最小改动。下面的中文部分讲清三件事：这个库好在哪、为什么要适配 DSH、以及怎么从 Claude Code / Codex 的结构移植到 DSH。
>
> [English README](./README.en.md) · 精确改动清单见 [DSH adaptations](#dsh-adaptations) · 安装见 [在 DSH 里安装](#在-dsh-里安装)

[![skills.sh](https://skills.sh/b/mattpocock/skills)](https://skills.sh/mattpocock/skills)

## 这个库好在哪？

这是 Matt Pocock 用了几十年的工程经验，压缩成 34 个可组合的 skill。它不是又一个"接管你流程"的框架。

**它解决的问题很具体。** 主流的 AI 开发框架（GSD、BMAD、Spec-Kit）思路是：把流程抓在自己手里。代价是流程一旦出 bug，你很难插手修。这个库相反：每个 skill 都短、能读、能改，流程由你控制，出问题你能直接改文件。

**它按"谁能唤起"分成两类，这是它设计的核心。**

| 类别 | 谁能唤起 | 职责 |
| --- | --- | --- |
| **User-invoked** | 只有你手打 `/名字` 才能唤起 | 编排：把多个步骤串成一条工作流 |
| **Model-invoked** | 你或模型都能唤起 | 纪律：可复用的方法论，被上面那类调用 |

规则很干净：user-invoked 可以调用 model-invoked，但永远不能调用另一个 user-invoked。所以编排层不会互相套娃。

**它同时治四种失败模式**（详见下方上游原文）：需求没说清、agent 太啰嗦、代码跑不通、代码库变成泥球。每种都有对应的 skill，比如 `/grill-me` 负责在动手前把你问清楚，`/tdd` 负责红绿重构，`/improve-codebase-architecture` 负责定期体检架构。

**MIT 协议，随便改。** 上游明确鼓励你 fork 和改。

**那 DSH 版额外好在哪？**

- **34 个 skill 零改名直接可用**：一个名字、一个目录、一份 frontmatter 都没动，所以文件内容仍然能和上游逐行对比。
- **一条命令装完**：`bash install.sh`，或者直接在 DSH 的技能管理器里添加本仓库。
- **离上游只差 1 次 merge**：改动只碰了 10 个文件（其中技能文件只有 4 个），所以 `git fetch upstream && git merge upstream/main` 就能跟上 Matt 的更新。

## 为什么要做 DSH 适配？

上游官方支持的 harness 是 **Claude Code、Codex、GitHub Copilot、Gemini CLI**，外加通用的 `npx skills@latest`；**没有 DSH**。所以这个库需要有人把它接过来。

但要注意：**问题不在"DSH 读不读得懂"，而在"skill 里引用的东西 DSH 有没有"。** 实测下来，DSH 的 skill 契约和上游几乎是同一套：

- frontmatter 同样要求 `name` + `description`；
- `disable-model-invocation: true` 语义完全相同（只允许用户手打 `/名字` 唤起）；
- `license` / `version` / `homepage` / `author` / `argument-hint` / `metadata` 这些多余字段，DSH 直接忽略，不报错；
- 相对路径引用（`tests.md`、`*-FORMAT.md`、`scripts/`）DSH 会按 skill 自己的资源目录解析，原样可用；
- 调用方式也是"用户打 `/名字`"对"模型调 `skill` 工具"。

真正跑不通的只有三类，都很局部：

1. **写死了 Claude Code CLI**：`claude-handoff` 这个 skill 让 agent 去执行 `claude --bg ...`。DSH 机器上根本没有 `claude` 这个命令，这一步必然失败。
2. **用了 DSH 不存在的斜杠命令**：`ask-matt` 反复要求 `/clear`（清空上下文窗口）。DSH 只有 `/compact`、`/goal`、`/plan`、`/permission`、`/export`、`/feedback`，**没有 `/clear`**。
3. **目录层级对不上**：上游把 skill 放在 `skills/engineering/<名字>/SKILL.md`（三层），而 DSH 只扫描 `<扫描根>/<名字>/SKILL.md`（两层）。所以**从 GitHub 原样 clone 下来，DSH 一个 skill 都发现不了**，必须把每个 skill 目录"摊平"进扫描根。

第 3 条是移植时最容易踩的坑，也是这个仓库提供 `install.sh` 的原因。

## 怎么从 Claude Code / Codex 的结构移植到 DSH

### 两边结构对照

| 维度 | Claude Code / Codex | DSH | 需要改吗 |
| --- | --- | --- | --- |
| frontmatter 字段 | `name` + `description` + `disable-model-invocation` | 完全相同，额外字段忽略 | 否 |
| 用户唤起 | 手打 `/名字` | 手打 `/名字` | 否 |
| 模型唤起 | `Skill` 工具 | `skill` 工具（**名字就是这么叫的**） | 否，字面就能对上 |
| 子代理 | `Task` / subagent | `subagent`、`subagent_fork` 工具 | 否，措辞可直接映射 |
| `/compact` | 有 | **有** | 否 |
| `/clear` | 有 | **没有** | **是** |
| 后台起 agent | `claude --bg` | `subagent` + `run_in_background: true` | **是** |
| 目录层级 | `skills/<分类>/<名字>/SKILL.md` | `<扫描根>/<名字>/SKILL.md` | **是（摊平）** |
| 指令文件 | `CLAUDE.md` / `AGENTS.md` | 两个都读 | 否 |
| 多 harness 元数据 | `agents/openai.yaml`（Codex 用） | 忽略，无副作用 | 否 |

DSH 的扫描根和优先级（数字越小越优先）：

| 优先级 | 位置 | 用途 |
| --- | --- | --- |
| 100 | `<项目>/.dsh/skills` | 项目私有 |
| 200 | `<项目>/.agents/skills` | 项目共享 |
| 300 | 自定义目录 | 配置指定 |
| 400 | `~/.dsh/skills` | **DSH 用户目录**（本库默认装这里） |
| 500 | `~/.agents/skills` | 跨 harness 共享 |
| 600 | 内置 | DSH 自带 |

### 具体改了什么

`skills/` 下共 108 个文件，只有 4 个被改动，其余 104 个与上游**逐字节相同**（已用 `cmp` 全量核对）。

| # | 文件 | 改了什么 | 为什么 |
| --- | --- | --- | --- |
| 1 | `skills/in-progress/claude-handoff/SKILL.md` | 把 `claude --bg --name "..." -- "$(cat <摘要文件>)"` 和"用 `claude agents` 管理任务"换成调用 DSH 的 `subagent` 工具（`run_in_background: true`），并把 `Skill tool` 改成 `skill` 工具 | DSH 上不存在 `claude` 命令，原来的做法 100% 失败 |
| 2 | `skills/in-progress/README.md` | `claude-handoff` 的一行说明同步改成用 `subagent` 工具 | 与第 1 条保持一致 |
| 3 | `skills/engineering/ask-matt/SKILL.md`、`PHASE-BOUNDARIES.md`、`docs/engineering/ask-matt.md`、`docs/productivity/handoff.md` | 把 `/clear` 改成 **New session**（新会话） | DSH 没有 `/clear` 命令；但"开一个新会话、拿到一个干净窗口"这件事在 DSH 里做得到，所以改成描述**动作**而不是命令名 |
| 4 | 根 `README.md`、新增 `README.en.md` 与 `install.sh` | DSH 安装路径 + 安装脚本 + 英文说明 | 上游的安装方式覆盖不到 DSH |

另外删掉了上游的 `.github/workflows/release.yml`：它是给上游自己的发布流程用的 changeset 工作流，在派生库里每次推送 main 都会试图开一个版本 PR，属于无关噪音。

### 为什么不给技能改名

有一种"看起来更整齐"的做法：把技能改名成 `dsh-tdd`、`dsh-code-review`。**这个库故意不这么做**，原因有三：

1. **会打断约 100 处交叉引用。** 这些 skill 互相按名字调用，例如 `grilling` 被 8 个 skill 引用、`setup-matt-pocock-skills` 被 8 个、`domain-modeling` 被 7 个。改名就要同步改几十个文件。
2. **上游明确禁止这么做。** 见上游 `.out-of-scope/harness-name-collisions.md`：改名或加别名来躲避 harness 的命令重名，属于 out of scope。
3. **DSH 里根本没有重名冲突。** DSH 的内置命令只有 `compact`、`goal`、`plan`、`permission`、`export`、`feedback`，和这 34 个 skill 名字一个都不撞。

所以 DSH 这个前缀**只出现在仓库标题上**，用来标明"这是 DSH 版"；仓库里的目录、文件名、frontmatter、交叉引用全部保持原样。

### 这样改的好处

- **可对比**：技能内容仍与上游逐行可比，不是一份被大改过的分叉。
- **可持续**：`git fetch upstream && git merge upstream/main` 是唯一的同步动作。因为只碰了 4 个技能文件，未来冲突面很小（已知例外：`ask-matt` 和 `claude-handoff` 上游也在演进，这两个文件合并时可能需要手工处理）。
- **可回退**：`link` 模式安装时，本机 `~/.dsh/skills/` 里只是指回本仓库的目录链接，删掉链接就退回原状。
- **不侵入**：技能写在 `~/.dsh/skills`，不碰 `~/.agents/skills`、不碰 `~/.claude/skills`，别的 harness 不受影响。

## 在 DSH 里安装

**推荐：用 DSH 的技能管理器装。** 打开 **设置 → 技能 → 技能仓库 → 添加仓库**，填入：

```text
https://github.com/mechanic-Q/DSH-mattpocock-skills
```

扫描后把想用的技能安装到 **DSH 用户目录**（`~/.dsh/skills`）。管理器会把技能连资源文件一起复制过去，并**记录 GitHub 来源**，于是"刷新并检查更新""查看更新（差异预览）""恢复上一版""卸载"这些功能都能用。

**备选：用安装脚本。** 适合要改 skill 本身，或者想一次装齐 34 个的情况：

```bash
git clone https://github.com/mechanic-Q/DSH-mattpocock-skills ~/src/DSH-mattpocock-skills
bash ~/src/DSH-mattpocock-skills/install.sh          # link 模式（默认）
bash ~/src/DSH-mattpocock-skills/install.sh copy     # copy 模式
```

| 模式 | DSH 能用 | 技能管理器里可见 | 更新方式 |
| --- | --- | --- | --- |
| `link`（默认） | 能 | **不能**（管理器扫描 DSH 源时会跳过符号链接/junction） | 即时，`git pull` 即可 |
| `copy` | 能 | 能 | `git pull` 后重跑脚本 |

**这是个容易踩的坑**：`link` 模式下 skill 在 DSH 里工作完全正常，但因为管理器跳过链接，你在面板里看不到它。想要"能搜、能开关、能分类、能检查更新"，就用管理器安装或者 `copy` 模式。

两种模式都会跳过 `deprecated/`（已废弃）和 `misc/`（非正式收录）；`in-progress/` 是**故意收录**的，上游也希望这些 beta 技能被试用。Windows 下 `link` 用目录 junction（`mklink /J`），不需要管理员权限，而且和 Git Bash 下的 `ln -s` 不同，它不会悄悄退化成复制。两种模式 DSH 都是即时生效，不用重启。

更新：`git -C ~/src/DSH-mattpocock-skills pull`。如果是管理器安装的，用「技能仓库 → 刷新并检查更新」。

## 技能清单（34 个）

`disable-model-invocation: true` 的是 **User-invoked**（只有你手打 `/名字` 才能唤起）；其余是 **Model-invoked**（你或模型都能唤起）。

### Engineering（20 个）

**User-invoked（11）**

- [`ask-matt`](./skills/engineering/ask-matt/SKILL.md)：不知道用哪个 skill 时问它，它是全部 user-invoked 技能的路由表。
- [`grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md)：一边盘问你的方案，一边顺手把 `GLOSSARY.md` 和 ADR 写出来。
- [`triage`](./skills/engineering/triage/SKILL.md)：让 issue / 外部 PR 走一遍分诊状态机，分类、核实、必要时盘问，产出 agent 可直接执行的简报。
- [`improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md)：扫描代码库找"可深化模块"的候选，出一份 HTML 报告，再挑一个盘问下去。
- [`setup-matt-pocock-skills`](./skills/engineering/setup-matt-pocock-skills/SKILL.md)：每个项目跑一次，配置 issue tracker、分诊标签、文档目录。
- [`to-spec`](./skills/engineering/to-spec/SKILL.md)：把当前对话直接综合成一份 spec 并发到 issue tracker，不采访。
- [`to-tickets`](./skills/engineering/to-tickets/SKILL.md)：把方案拆成一串"曳光弹"式 ticket，每个声明自己的阻塞边。
- [`implement`](./skills/engineering/implement/SKILL.md)：按 spec 或 ticket 实现单个工作项。
- [`implement-spec`](./skills/engineering/implement-spec/SKILL.md)：一次实现整份 spec，按就绪边界并行派发 implementer 子代理，落到一条集成分支。
- [`wayfinder`](./skills/engineering/wayfinder/SKILL.md)：把一个大到一次会话装不下的工作，铺成一张决策 ticket 地图，逐个解决。
- [`retro`](./skills/engineering/retro/SKILL.md)：对一次编码会话做复盘，产出的是对**环境**的改进建议，不是对代码的。

**Model-invoked（9）**

- [`tdd`](./skills/engineering/tdd/SKILL.md)：红绿重构循环，附带"什么算好测试/坏测试"的指导。
- [`code-review`](./skills/engineering/code-review/SKILL.md)：从某个固定点开始，沿两个轴审代码（Standards 是否合规 / Spec 是否符合原始要求），两轴并行跑子代理。
- [`codebase-design`](./skills/engineering/codebase-design/SKILL.md)：设计"深模块"的共享词汇，决定接口边界和 seam 放哪里。
- [`domain-modeling`](./skills/engineering/domain-modeling/SKILL.md)：建设和打磨项目领域模型，写 `GLOSSARY.md` 和 ADR。
- [`diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md)：难 bug 和性能回退的诊断循环，逐阶段设闸。
- [`research`](./skills/engineering/research/SKILL.md)：对着高可信一手资料做调研，产出一份带引用的 Markdown 文件。
- [`pr`](./skills/engineering/pr/SKILL.md)：写 PR 描述。
- [`prototype`](./skills/engineering/prototype/SKILL.md)：搭一次性原型回答设计问题（状态模型对不对、UI 该长什么样）。
- [`wizard`](./skills/engineering/wizard/SKILL.md)：生成一个交互式 bash 向导，带人走完只有人才能做的步骤（开凭证、点第三方后台、一次性迁移）。

### Productivity（7 个）

**User-invoked（5）**

- [`grill-me`](./skills/productivity/grill-me/SKILL.md)：不留情面地盘问你的方案，非代码场景用。
- [`handoff`](./skills/productivity/handoff/SKILL.md)：把当前对话压缩成一份交接文档，给下一个 agent 接手。
- [`teach`](./skills/productivity/teach/SKILL.md)：在当前工作区里教你一个新技能或概念。
- [`to-questionnaire`](./skills/productivity/to-questionnaire/SKILL.md)：把你自己答不了的决策，变成一份给别人的问卷。
- [`wait-what`](./skills/productivity/wait-what/SKILL.md)：某条消息没听懂时立刻发它，agent 会用你缺的上下文重新讲一遍。

**Model-invoked（2）**

- [`grilling`](./skills/productivity/grilling/SKILL.md)：把用户往死里问的底层原语，被 `grill-me`、`grill-with-docs`、`triage`、`wayfinder`、`improve-codebase-architecture` 共用。
- [`writing-for-agents`](./skills/productivity/writing-for-agents/SKILL.md)：写给 agent 看的文档（skill、`AGENTS.md` / `CLAUDE.md`）。

### In-progress（7 个，beta）

上游把这些放在 `in-progress/`：公开是为了让人试用和反馈，**可能随时改动或消失**。全部为 user-invoked。

- [`chief-of-staff`](./skills/in-progress/chief-of-staff/SKILL.md)：在一个会话里靠协调子代理推进一个长期目标。
- [`claude-handoff`](./skills/in-progress/claude-handoff/SKILL.md)：把当前对话交给一个全新的后台 agent 立刻接手（**本库已改成 DSH 的 `subagent` 工具**）。
- [`loop-me`](./skills/in-progress/loop-me/SKILL.md)：盘问你想要的工作流该长什么样。
- [`setup-ts-deep-modules`](./skills/in-progress/setup-ts-deep-modules/SKILL.md)：给 TypeScript 仓库接上 dependency-cruiser，让每个包都是"深模块"。
- [`writing-beats`](./skills/in-progress/writing-beats/SKILL.md) / [`writing-fragments`](./skills/in-progress/writing-fragments/SKILL.md) / [`writing-shape`](./skills/in-progress/writing-shape/SKILL.md)：把素材整理成文章的探索/成型三段式。

### 未收录（4 个）

`skills/misc/`（`git-guardrails-claude-code`、`migrate-to-shoehorn`、`scaffold-exercises`、`setup-pre-commit`）**不安装**。其中 `git-guardrails-claude-code` 整份都是 Claude Code 的 settings/hook 配置，对 DSH 不适用；其余三个属于很少用的杂项，上游自己也不推荐（它的 `link-skills.sh` 同样跳过 `misc/`）。`skills/deprecated/` 是空的。

## 与上游同步

```bash
git -C ~/src/DSH-mattpocock-skills fetch upstream
git -C ~/src/DSH-mattpocock-skills merge upstream/main
```

本库的 `upstream` 已指向 `https://github.com/mattpocock/skills`。当前基线是上游 main 的 `49dd158`。

## DSH adaptations

> This section is specific to this DSH edition. It is the only part of this file that is not upstream's text. The Chinese summary of the same material is at the top of this file.

This repository is a **DSH version** of [mattpocock/skills](https://github.com/mattpocock/skills): the full skill set, with the small number of changes needed to run under [DeepSeek Harness](https://github.com/deepseek-ai). Upstream is MIT-licensed and the original copyright is retained. See [LICENSE](./LICENSE).

Nothing is renamed. Every skill keeps its upstream name, directory, and frontmatter, so this repo stays diffable against upstream and the ~100 cross-skill references inside the set keep working.

The changes are deliberately minimal:

| # | File | Change |
| --- | --- | --- |
| 1 | `skills/in-progress/claude-handoff/SKILL.md` | Launch mechanism: the Claude Code CLI (`claude --bg --name …`, `claude agents`) → DSH's `subagent` tool with `run_in_background: true`. Also `Skill tool` → `skill` tool. |
| 2 | `skills/in-progress/README.md` | One-line description of `claude-handoff` updated to match. |
| 3 | `skills/engineering/ask-matt/SKILL.md`, `skills/engineering/ask-matt/PHASE-BOUNDARIES.md`, `docs/engineering/ask-matt.md`, `docs/productivity/handoff.md` | `/clear` (a Claude Code command DSH does not have) → **New session**, DSH's equivalent for emptying the window. |
| 4 | `README.md`, new `README.en.md`, new `install.sh` | DSH install path, installer, and English docs. |

What did **not** need changing:

- **Frontmatter.** DSH reads the same `name` / `description` pair, and honours `disable-model-invocation: true` with exactly the same meaning (user-invoked only, reachable solely by typing `/name`). Unknown keys (`license`, `version`, `homepage`, `author`, `argument-hint`, `metadata`) are silently ignored. `agents/openai.yaml` is Codex metadata; DSH ignores it.
- **Tool names.** DSH's skill loader is literally the `skill` tool, so "call the Skill tool with `grilling`" resolves as written. Subagent wording maps onto DSH's `subagent` tool.
- **`/compact`.** DSH has it natively.
- **Relative bundle links.** DSH resolves them against the skill's own resource directory, so `tests.md`, `mocking.md`, the `*-FORMAT.md` templates, and `scripts/` all work untouched.
- **`AGENTS.md` vs `CLAUDE.md`.** DSH reads both, so `setup-matt-pocock-skills`' selection rule holds.

Not promoted: `skills/misc/` (its `git-guardrails-claude-code` is entirely Claude Code settings/hook configuration) and `skills/deprecated/` (empty). `skills/in-progress/` is included, as upstream intends it to be tried.

---

# 附录：上游原版 README（英文）

以下是上游 `README.md` 的正文，**逐字未改**（已用 diff 核对）。仅省略了三处已在本文件开头出现过的内容：顶部 banner 图、`# Skills For Real Engineers` 标题行、skills.sh 徽章。

其中 `## Installation (30-second setup)` 一节讲的是 Claude Code / Codex / Copilot / Gemini 的装法；**DSH 的装法在前面的「在 DSH 里安装」**。保留原文是为了让改动可对比。

My agent skills that I use every day to do real engineering - not vibe coding.

Developing real applications is hard. Approaches like GSD, BMAD, and Spec-Kit try to help by owning the process. But while doing so, they take away your control and make bugs in the process hard to resolve.

These skills are designed to be small, easy to adapt, and composable. They work with any model. They're based on decades of engineering experience. Hack around with them. Make them your own. Enjoy.

If you want to keep up with changes to these skills, and any new ones I create, you can join ~60,000 other devs on my newsletter:

[Sign Up To The Newsletter](https://www.aihero.dev/s/skills-newsletter)

## Installation (30-second setup)

A plugin updates itself. [skills.sh](https://skills.sh/mattpocock/skills) copies editable files into your project, and you update them by hand. Pick one per agent, because installing both gives you every skill twice.

### 1. Get the skills

<details>
<summary><strong>Claude Code</strong></summary>

```bash
claude plugin install mattpocock-skills@claude-plugins-official
```

Updates itself by default.

</details>

<details>
<summary><strong>Codex</strong></summary>

```bash
codex plugin marketplace add mattpocock/skills
codex plugin add mattpocock-skills@mattpocock
```

Updates itself at startup.

</details>

<details>
<summary><strong>GitHub Copilot</strong> (CLI and VS Code)</summary>

```bash
copilot plugin marketplace add mattpocock/skills
copilot plugin install mattpocock-skills@mattpocock
```

Then, once, add to `~/.copilot/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "mattpocock": { "source": { "source": "github", "repo": "mattpocock/skills" }, "autoUpdate": true }
  }
}
```

In VS Code, run **Chat: Install Plugin From Source** and enter `https://github.com/mattpocock/skills`. It updates daily.

</details>

<details>
<summary><strong>Gemini CLI</strong> (manual updates)</summary>

```bash
gemini skills install https://github.com/mattpocock/skills.git --path skills/engineering
gemini skills install https://github.com/mattpocock/skills.git --path skills/productivity
```

Re-run both commands to update.

</details>

<details>
<summary><strong>Any other agent, or editable files</strong> (manual updates)</summary>

```bash
npx skills@latest add mattpocock/skills -a <agent>  # cursor, opencode, devin, windsurf, amp, pi; omit -a to choose
```

When the installer asks which skills to take, include `setup-matt-pocock-skills`. To update, run `npx skills@latest update`, and re-run `add` to pick up new skills.

</details>

### 2. Run `/setup-matt-pocock-skills`

In your agent, run it once per repo. It will:

- Ask you which issue tracker you want to use (GitHub, GitLab, local files, or anything else you describe)
- Ask you what labels you apply to tickets when you triage them (`/triage` uses labels)
- Ask you where you want to save any docs we create

### 3. Bam - you're ready to go.

## Why These Skills Exist

I built these skills as a way to fix common failure modes I see with Claude Code, Codex, and other coding agents.

### #1: The Agent Didn't Do What I Want

> "No-one knows exactly what they want"
>
> David Thomas & Andrew Hunt, [The Pragmatic Programmer](https://www.amazon.co.uk/Pragmatic-Programmer-Anniversary-Journey-Mastery/dp/B0833F1T3V)

**The Problem**. The most common failure mode in software development is misalignment. You think the dev knows what you want. Then you see what they've built - and you realize it didn't understand you at all.

This is just the same in the AI age. There is a communication gap between you and the agent. The fix for this is a **grilling session** - getting the agent to ask you detailed questions about what you're building.

**The Fix** is to use:

- [`/grill-me`](./skills/productivity/grill-me/SKILL.md) - for non-code uses
- [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) - same as [`/grill-me`](./skills/productivity/grill-me/SKILL.md), but adds more goodies (see below)

These are my most popular skills. They help you align with the agent before you get started, and think deeply about the change you're making. Use them _every_ time you want to make a change.

### #2: The Agent Is Way Too Verbose

> With a ubiquitous language, conversations among developers and expressions of the code are all derived from the same domain model.
>
> Eric Evans, [Domain-Driven-Design](https://www.amazon.co.uk/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)

**The Problem**: At the start of a project, devs and the people they're building the software for (the domain experts) are usually speaking different languages.

I felt the same tension with my agents. Agents are usually dropped into a project and asked to figure out the jargon as they go. So they use 20 words where 1 will do.

**The Fix** for this is a shared language. It's a document that helps agents decode the jargon used in the project.

<details>
<summary>
Example
</summary>

Here's an example [glossary](https://github.com/mattpocock/course-video-manager/blob/076a5a7a182db0fe1e62971dd7a68bcadf010f1c/CONTEXT.md) (still named `CONTEXT.md` at that pinned commit, from before the skills renamed the convention), from my `course-video-manager` repo. Which one is easier to read?

- **BEFORE**: "There's a problem when a lesson inside a section of a course is made 'real' (i.e. given a spot in the file system)"
- **AFTER**: "There's a problem with the materialization cascade"

This concision pays off session after session.

</details>

This is built into [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md). It's a grilling session, but that helps you build a shared language with the AI, and document hard-to-explain decisions in ADR's.

It's hard to explain how powerful this is. It might be the single coolest technique in this repo. Try it, and see.

> [!TIP]
> A shared language has many other benefits than reducing verbosity:
>
> - **Variables, functions and files are named consistently**, using the shared language
> - As a result, the **codebase is easier to navigate** for the agent
> - The agent also **spends fewer tokens on thinking**, because it has access to a more concise language

### #3: The Code Doesn't Work

> "Always take small, deliberate steps. The rate of feedback is your speed limit. Never take on a task that’s too big."
>
> David Thomas & Andrew Hunt, [The Pragmatic Programmer](https://www.amazon.co.uk/Pragmatic-Programmer-Anniversary-Journey-Mastery/dp/B0833F1T3V)

**The Problem**: Let's say that you and the agent are aligned on what to build. What happens when the agent _still_ produces crap?

It's time to look at your feedback loops. Without feedback on how the code it produces actually runs, the agent will be flying blind.

**The Fix**: You need the usual tranche of feedback loops: static types, browser access, and automated tests.

For automated tests, a red-green-refactor loop is critical. This is where the agent writes a failing test first, then fixes the test. This helps give the agent a consistent level of feedback that results in far better code.

I've built a **[`/tdd`](./skills/engineering/tdd/SKILL.md) skill** you can slot into any project. It encourages red-green-refactor and gives the agent plenty of guidance on what makes good and bad tests.

For debugging, I've also built a **[`/diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md)** skill that wraps best debugging practices into a disciplined loop, gated phase by phase.

### #4: We Built A Ball Of Mud

> "Invest in the design of the system _every day_."
>
> Kent Beck, [Extreme Programming Explained](https://www.amazon.co.uk/Extreme-Programming-Explained-Embrace-Change/dp/0321278658)

> "The best modules are deep. They allow a lot of functionality to be accessed through a simple interface."
>
> John Ousterhout, [A Philosophy Of Software Design](https://www.amazon.co.uk/Philosophy-Software-Design-2nd/dp/173210221X)

**The Problem**: Most apps built with agents are complex and hard to change. Because agents can radically speed up coding, they also accelerate software entropy. Codebases get more complex at an unprecedented rate.

**The Fix** for this is a radical new approach to AI-powered development: caring about the design of the code.

This is built in to every layer of these skills:

- [`/to-spec`](./skills/engineering/to-spec/SKILL.md) quizzes you about which modules you're touching before creating a spec

And crucially, [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) surveys a codebase for deepening opportunities and hands you the candidates. I recommend running it on your codebase once every few days. It is a survey, not a rescue: on a genuinely old codebase it will find real candidates, but it won't untangle the mud for you.

### Summary

Software engineering fundamentals matter more than ever. These skills are my best effort at condensing these fundamentals into repeatable practices, to help you ship the best apps of your career. Enjoy.

## Reference

These split on one axis: who can invoke them. **User-invoked** skills are reachable only when you type them (e.g. `/grill-me`); their job is to orchestrate. **Model-invoked** skills can be invoked by you _or_ reached for automatically by the agent when the task fits; they hold the reusable discipline. A user-invoked skill may invoke model-invoked skills, but never another user-invoked one.

### Engineering

Skills I use daily for code work.

**User-invoked**

- **[ask-matt](./skills/engineering/ask-matt/SKILL.md)**: Ask which skill or flow fits your situation. A router over the user-invoked skills in this repo.
- **[grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md)**: Grilling session that also builds your project's domain model, sharpening terminology and updating `GLOSSARY.md` and ADRs inline.
- **[triage](./skills/engineering/triage/SKILL.md)**: Move issues through a state machine of triage roles.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md)**: Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
- **[setup-matt-pocock-skills](./skills/engineering/setup-matt-pocock-skills/SKILL.md)**: Configure this repo for the engineering skills (issue tracker, triage labels, domain doc layout). Run once per repo before using the other engineering skills.
- **[to-spec](./skills/engineering/to-spec/SKILL.md)**: Turn the current conversation into a spec and publish it to the issue tracker. No interview, just synthesizes what you've already discussed.
- **[to-tickets](./skills/engineering/to-tickets/SKILL.md)**: Break any plan, spec, or conversation into a set of tracer-bullet tickets, each declaring its blocking edges, written as text in a local file, or as native blocking links on a real tracker.
- **[implement](./skills/engineering/implement/SKILL.md)**: Build the work described by a spec or set of tickets, driving `/tdd` at pre-agreed seams and closing out with `/code-review` before committing.
- **[implement-spec](./skills/engineering/implement-spec/SKILL.md)**: Implement a whole spec on one integration branch. Works the tickets as a task graph, running implementer subagents across the ready frontier for maximum concurrency, then closes out with `/code-review`.
- **[wayfinder](./skills/engineering/wayfinder/SKILL.md)**: Plan a huge chunk of work, more than one agent session can hold, as a shared map of decision tickets on the issue tracker, and resolve them one at a time until the way to the destination is clear.
- **[retro](./skills/engineering/retro/SKILL.md)**: Suggest improvements to the coding agent's environment (navigation, automated checks, coding standards, steering files, tooling) after a session, most severe first.

**Model-invoked**

- **[prototype](./skills/engineering/prototype/SKILL.md)**: Build a throwaway prototype to answer a design question, either a single shareable HTML file for state/logic questions, or several radically different UI variations toggleable from one route.
- **[diagnosing-bugs](./skills/engineering/diagnosing-bugs/SKILL.md)**: Disciplined diagnosis loop for hard bugs and performance regressions: build a feedback loop that goes red on this bug → minimise → hypothesise → instrument → fix → regression-test.
- **[research](./skills/engineering/research/SKILL.md)**: Investigate a question against high-trust primary sources and capture the findings as a cited Markdown file in the repo, run as a background agent.
- **[tdd](./skills/engineering/tdd/SKILL.md)**: Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **[domain-modeling](./skills/engineering/domain-modeling/SKILL.md)**: Actively build and sharpen a project's domain model: challenge terms against the glossary, stress-test with edge-case scenarios, and update `GLOSSARY.md` and ADRs inline.
- **[codebase-design](./skills/engineering/codebase-design/SKILL.md)**: Shared discipline and vocabulary for designing deep modules: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface.
- **[code-review](./skills/engineering/code-review/SKILL.md)**: Two-axis review of the diff since a fixed point: **Standards** (does it follow the repo's coding standards, plus a Fowler smell baseline?) and **Spec** (does it faithfully implement the originating issue/spec?), run as parallel sub-agents so neither pollutes the other.
- **[pr](./skills/engineering/pr/SKILL.md)**: The shape a pull request body should take: a summary as the smallest visual that makes the change clear, before/after evidence that it works, and a merge-danger call (one-way or two-way door, plus blast radius).
- **[wizard](./skills/engineering/wizard/SKILL.md)**: Generate an interactive bash wizard that walks a human through steps only they can perform: provisioning infrastructure, setting up credentials or CI secrets, walking an unfamiliar third-party dashboard, or running a one-off migration or cutover.

### Productivity

General workflow tools, not code-specific.

**User-invoked**

- **[grill-me](./skills/productivity/grill-me/SKILL.md)**: Get relentlessly interviewed about a plan or design until every branch of the design tree is resolved.
- **[handoff](./skills/productivity/handoff/SKILL.md)**: Compact the current conversation into a handoff document so another agent can continue the work.
- **[teach](./skills/productivity/teach/SKILL.md)**: Teach the user a new skill or concept over multiple sessions, using the current directory as a stateful teaching workspace.
- **[to-questionnaire](./skills/productivity/to-questionnaire/SKILL.md)**: Turn a decision you can't answer alone into a Markdown questionnaire for the one person who can, filled in async, or together over a meeting. It grills you about the send (who it's for, what you need back), not the subject.
- **[wait-what](./skills/productivity/wait-what/SKILL.md)**: Fire this the moment a message doesn't land. The agent re-pitches it with the context you're missing, in plain English, using your `GLOSSARY.md` vocabulary.

**Model-invoked**

- **[grilling](./skills/productivity/grilling/SKILL.md)**: Interview the user relentlessly about a plan, decision, or idea until every branch of the design tree is resolved. The reusable interview primitive behind `grill-me`, `grill-with-docs`, `triage`, `wayfinder` and `improve-codebase-architecture`.
- **[writing-for-agents](./skills/productivity/writing-for-agents/SKILL.md)**: Writing documents for agents: skills, AGENTS.md/CLAUDE.md, and any doc an agent reaches by a pointer.
