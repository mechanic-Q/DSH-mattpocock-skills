<p>
  <a href="https://www.aihero.dev/s/skills-newsletter">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skills-repo-dark_2x.png">
      <source media="(prefers-color-scheme: light)" srcset="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skill-repo-light_2x.png">
      <img alt="Skills" src="https://res.cloudinary.com/total-typescript/image/upload/v1777382277/skill-repo-light_2x.png" width="369">
    </picture>
  </a>
</p>

# Skills For Real Engineers (DSH Edition)

> **This is the DSH edition of [mattpocock/skills](https://github.com/mattpocock/skills)**. It is an adaptation for [DeepSeek Harness](https://github.com/deepseek-ai). **No skill is renamed or removed.** The only changes are the minimum needed to make the set run end-to-end under DSH. The three sections below cover: why this repo is worth your time, why a DSH port was needed at all, and how the port was done.
>
> [中文 README](./README.md) · exact edits in [The exact edits](#the-exact-edits) · install in [Install in DSH](#install-in-dsh)

[![skills.sh](https://skills.sh/b/mattpocock/skills)](https://skills.sh/mattpocock/skills)

## Why this repo is good

This is decades of Matt Pocock's engineering experience compressed into 34 composable skills. It is not another framework that takes over your process.

**It solves a concrete problem.** Mainstream AI-development frameworks (GSD, BMAD, Spec-Kit) work by owning the process. The cost: when the process itself has a bug, you cannot easily reach in and fix it. This set is the opposite. Every skill is short, readable, and editable. You control the flow, and when something is wrong you can edit the file directly.

**Skills split by who can invoke them, and that split is the core of the design.**

| Class | Who can invoke | Job |
| --- | --- | --- |
| **User-invoked** | Only you, by typing `/name` | Orchestration: chains several steps into one workflow |
| **Model-invoked** | You or the model | Discipline: reusable method, called by the class above |

The rule is clean: a user-invoked skill may invoke model-invoked skills, but never another user-invoked skill. So orchestration layers cannot nest inside each other.

**It treats four failure modes** (see upstream's original text below): misalignment, verbosity, code that does not work, and the ball of mud. Each has a skill: `/grill-me` questions you before you start, `/tdd` enforces red-green-refactor, `/improve-codebase-architecture` surveys architecture on a schedule.

**MIT licensed. Change whatever you want.** Upstream explicitly encourages forking and adapting.

**What the DSH edition adds on top:**

- **All 34 skills work with zero renaming**. No name, directory, or frontmatter was touched, so file contents remain line-by-line comparable against upstream.
- **One command to install**: `bash install.sh`, or add this repo in DSH's Skills Manager.
- **One merge away from upstream**. Only 10 files differ, 4 of them skill files, so `git fetch upstream && git merge upstream/main` keeps you current with Matt.

## Why a DSH adaptation was needed

Upstream officially supports **Claude Code, Codex, GitHub Copilot, and Gemini CLI**, plus the generic `npx skills@latest` installer. **DSH is not on that list**, so someone had to wire it up.

The important part: **the problem was never "can DSH read the skill format", it was "does DSH have what the skills reference".** Measured against DSH's actual skill contract, the two are nearly the same format:

- Frontmatter requires the same `name` + `description` pair.
- `disable-model-invocation: true` means exactly the same thing (user-invoked only, reachable solely by typing `/name`).
- Extra keys (`license`, `version`, `homepage`, `author`, `argument-hint`, `metadata`) are silently ignored by DSH, not errors.
- Relative references (`tests.md`, the `*-FORMAT.md` templates, `scripts/`) resolve against the skill's own resource directory and work untouched.
- Invocation is the same shape: the human types `/name`, the model calls the `skill` tool.

Only three things genuinely break, and all are local:

1. **A hard-coded Claude Code CLI call.** `claude-handoff` tells the agent to run `claude --bg ...`. There is no `claude` binary on a DSH machine, so that step always fails.
2. **A slash command DSH does not have.** `ask-matt` repeatedly requires `/clear` (empty the context window). DSH ships `/compact`, `/goal`, `/plan`, `/permission`, `/export`, `/feedback`, and **no `/clear`**.
3. **A directory-depth mismatch.** Upstream nests skills at `skills/engineering/<name>/SKILL.md` (three levels). DSH only scans `<root>/<name>/SKILL.md` (two levels). So **a plain `git clone` of upstream yields zero discovered skills in DSH**; each skill directory has to be flattened into a scanned root.

That third point is the trap most people hit, and it is why this repo ships `install.sh`.

## How the port works: Claude Code / Codex structure to DSH

### Side-by-side

| Dimension | Claude Code / Codex | DSH | Change needed |
| --- | --- | --- | --- |
| Frontmatter fields | `name` + `description` + `disable-model-invocation` | Identical; extra fields ignored | No |
| User invocation | Type `/name` | Type `/name` | No |
| Model invocation | The `Skill` tool | The `skill` tool (**literally that name**) | No, it matches as written |
| Subagents | `Task` / subagent | `subagent`, `subagent_fork` tools | No, wording maps directly |
| `/compact` | Yes | **Yes** | No |
| `/clear` | Yes | **No** | **Yes** |
| Launching a background agent | `claude --bg` | `subagent` + `run_in_background: true` | **Yes** |
| Directory depth | `skills/<bucket>/<name>/SKILL.md` | `<root>/<name>/SKILL.md` | **Yes (flatten)** |
| Instruction file | `CLAUDE.md` / `AGENTS.md` | Reads both | No |
| Multi-harness metadata | `agents/openai.yaml` (used by Codex) | Ignored, no side effects | No |

DSH's scan roots, in priority order (lower number wins):

| Priority | Location | Purpose |
| --- | --- | --- |
| 100 | `<project>/.dsh/skills` | Project-private |
| 200 | `<project>/.agents/skills` | Project-shared |
| 300 | Custom dirs | Configured |
| 400 | `~/.dsh/skills` | **DSH user root** (this repo's default) |
| 500 | `~/.agents/skills` | Shared across harnesses |
| 600 | Bundled | Shipped with DSH |

### The exact edits

There are 108 files under `skills/`. Only 4 of them are changed; the other 104 are **byte-identical** to upstream (verified with a full `cmp` pass).

| # | File | Change | Why |
| --- | --- | --- | --- |
| 1 | `skills/in-progress/claude-handoff/SKILL.md` | Replaced `claude --bg --name "..." -- "$(cat <summary file>)"` and "manage it with `claude agents`" with a call to DSH's `subagent` tool (`run_in_background: true`); `Skill tool` to the `skill` tool | No `claude` binary exists on DSH; the original always failed |
| 2 | `skills/in-progress/README.md` | One-line description of `claude-handoff` updated to match | Keeps 1 and 2 consistent |
| 3 | `skills/engineering/ask-matt/SKILL.md`, `PHASE-BOUNDARIES.md`, `docs/engineering/ask-matt.md`, `docs/productivity/handoff.md` | `/clear` to **New session** | DSH has no `/clear`, but "start a fresh session, get a clean window" is doable, so it describes the **action**, not a command name |
| 4 | Root `README.md`, new `README.en.md` and `install.sh` | DSH install path, installer, and English docs | Upstream's install paths do not cover DSH |

Upstream's `.github/workflows/release.yml` was also removed: it is upstream's own changeset release pipeline, and in a derivative repo it would try to open a version PR on every push to main.

### Why the skills were not renamed

There is a tempting "tidier" option: rename skills to `dsh-tdd`, `dsh-code-review`, and so on. **This repo deliberately does not**, for three reasons:

1. **It would break roughly 100 cross-references.** These skills call each other by name: `grilling` is referenced by 8 skills, `setup-matt-pocock-skills` by 8, `domain-modeling` by 7. Renaming means editing dozens of files.
2. **Upstream forbids it.** See upstream's `.out-of-scope/harness-name-collisions.md`: renaming or aliasing a skill to dodge a harness command is out of scope.
3. **There is no collision in DSH.** DSH's built-in commands are only `compact`, `goal`, `plan`, `permission`, `export`, `feedback`, and none of them collides with these 34 names.

So the DSH prefix appears **only on the repository title**, to mark this as the DSH edition. Directories, filenames, frontmatter, and cross-references inside stay exactly as upstream wrote them.

### Why this approach is the right one

- **Comparable.** Skill content remains line-by-line diffable against upstream, rather than diverging into a rewritten fork.
- **Sustainable.** `git fetch upstream && git merge upstream/main` is the only sync step. With just 4 skill files touched, the conflict surface is tiny (known exceptions: `ask-matt` and `claude-handoff` are also moving upstream, so those two may need a manual merge).
- **Reversible.** In `link` mode the machine's `~/.dsh/skills/` holds junctions pointing back at this repo; delete the links and you are back to stock.
- **Non-invasive.** Skills live in `~/.dsh/skills`. `~/.agents/skills` and `~/.claude/skills` are untouched, so other harnesses are unaffected.

## Install in DSH

**Recommended: install with the DSH Skills Manager.** Open **设置 (Settings) → 技能 (Skills) → 技能仓库 (Skill repositories) → 添加仓库 (Add repository)** and enter:

```text
https://github.com/mechanic-Q/DSH-mattpocock-skills
```

Scan it, then install the skills you want into the **DSH user root** (`~/.dsh/skills`). The manager copies each skill with its resource files and **records its GitHub source**, so 刷新并检查更新 (refresh and check for updates), 查看更新 (view diff), 恢复上一版 (restore previous), and 卸载 (uninstall) all work from the UI.

**Alternative: the installer script.** For working on the skills themselves, or to install all 34 at once:

```bash
git clone https://github.com/mechanic-Q/DSH-mattpocock-skills ~/src/DSH-mattpocock-skills
bash ~/src/DSH-mattpocock-skills/install.sh          # link mode (default)
bash ~/src/DSH-mattpocock-skills/install.sh copy     # copy mode
```

| Mode | DSH can use it | Visible in Skills Manager | Updates |
| --- | --- | --- | --- |
| `link` (default) | yes | **no**: the manager's DSH-source scan skips symlinks/junctions | instant, via `git pull` |
| `copy` | yes | yes | rerun the script after `git pull` |

**This is an easy trap:** in `link` mode the skills work in DSH perfectly, but the manager skips links, so they will not appear in its panel. If you want them listed, searchable, toggleable, and categorizable, install through the manager or use `copy`.

Both modes skip `deprecated/` (retired) and `misc/` (not part of the supported set). `in-progress/` is included **on purpose**: upstream wants those beta skills tried. On Windows, `link` uses a directory junction (`mklink /J`): no admin rights, and unlike `ln -s` under Git Bash it does not silently degrade into a copy. DSH picks skills up live in either mode, with no restart.

Update with `git -C ~/src/DSH-mattpocock-skills pull`. For a manager-installed copy, use 技能仓库 → 刷新并检查更新.

## The 34 skills

Skills with `disable-model-invocation: true` are **user-invoked** (only reachable by typing `/name`); the rest are **model-invoked** (reachable by you or the model).

### Engineering (20)

**User-invoked (11)**

- [`ask-matt`](./skills/engineering/ask-matt/SKILL.md): Ask which skill or flow fits your situation. A router over the user-invoked skills in this repo.
- [`grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md): Relentless interview that sharpens a plan or design while writing `GLOSSARY.md` and ADRs as you go.
- [`triage`](./skills/engineering/triage/SKILL.md): Move issues and external PRs through a state machine of triage roles, categorise, verify, grill if needed, and write agent-ready briefs.
- [`improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md): Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
- [`setup-matt-pocock-skills`](./skills/engineering/setup-matt-pocock-skills/SKILL.md): Configure this repo once: issue tracker, triage label vocabulary, and domain doc layout.
- [`to-spec`](./skills/engineering/to-spec/SKILL.md): Turn the current conversation into a spec and publish it to the issue tracker: no interview, just synthesis.
- [`to-tickets`](./skills/engineering/to-tickets/SKILL.md): Break a plan or spec into tracer-bullet tickets, each declaring its blocking edges.
- [`implement`](./skills/engineering/implement/SKILL.md): Implement a piece of work from a spec or set of tickets.
- [`implement-spec`](./skills/engineering/implement-spec/SKILL.md): Implement a whole spec in one run: implementer subagents across the ready frontier, landing on one integration branch.
- [`wayfinder`](./skills/engineering/wayfinder/SKILL.md): Plan work too large for one agent session as a shared map of decision tickets, and resolve them one at a time.
- [`retro`](./skills/engineering/retro/SKILL.md): Retrospective on a coding session. It suggests changes to the agent's **environment**, not to the code.

**Model-invoked (9)**

- [`tdd`](./skills/engineering/tdd/SKILL.md): Red-green-refactor, with guidance on what makes good and bad tests.
- [`code-review`](./skills/engineering/code-review/SKILL.md): Review changes since a fixed point along two axes (Standards, Spec), run as parallel subagents.
- [`codebase-design`](./skills/engineering/codebase-design/SKILL.md): Shared vocabulary for designing deep modules: interfaces, seams, testability.
- [`domain-modeling`](./skills/engineering/domain-modeling/SKILL.md): Build and sharpen a project's domain model: `GLOSSARY.md` and ADRs.
- [`diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md): Diagnosis loop for hard bugs and performance regressions, gated phase by phase.
- [`research`](./skills/engineering/research/SKILL.md): Investigate a question against high-trust primary sources and capture a cited Markdown file.
- [`pr`](./skills/engineering/pr/SKILL.md): Write a PR body.
- [`prototype`](./skills/engineering/prototype/SKILL.md): Build a throwaway prototype to answer a design question.
- [`wizard`](./skills/engineering/wizard/SKILL.md): Generate an interactive bash wizard for steps only a human can perform (credentials, third-party dashboards, one-off migrations).

### Productivity (7)

**User-invoked (5)**

- [`grill-me`](./skills/productivity/grill-me/SKILL.md): Relentless interview to sharpen a plan or design, for non-code work.
- [`handoff`](./skills/productivity/handoff/SKILL.md): Compact the current conversation into a handoff document for another agent.
- [`teach`](./skills/productivity/teach/SKILL.md): Teach you a new skill or concept, within this workspace.
- [`to-questionnaire`](./skills/productivity/to-questionnaire/SKILL.md): Turn a decision you cannot answer alone into a questionnaire for someone else.
- [`wait-what`](./skills/productivity/wait-what/SKILL.md): The moment a message does not land, re-pitch it with the missing context.

**Model-invoked (2)**

- [`grilling`](./skills/productivity/grilling/SKILL.md): The reusable interview primitive behind `grill-me`, `grill-with-docs`, `triage`, `wayfinder`, and `improve-codebase-architecture`.
- [`writing-for-agents`](./skills/productivity/writing-for-agents/SKILL.md): Writing documents for agents: skills, `AGENTS.md` / `CLAUDE.md`.

### In-progress (7, beta)

Upstream keeps these in `in-progress/`: public on purpose so people can try them and report breakage, and **they can change or disappear without warning**. All are user-invoked.

- [`chief-of-staff`](./skills/in-progress/chief-of-staff/SKILL.md): Pursue a long-running goal in a single session by co-ordinating subagents.
- [`claude-handoff`](./skills/in-progress/claude-handoff/SKILL.md): Hand off to a fresh background agent (rewritten in this edition to use DSH's `subagent` tool).
- [`loop-me`](./skills/in-progress/loop-me/SKILL.md): Grill you about the workflows you want to build.
- [`setup-ts-deep-modules`](./skills/in-progress/setup-ts-deep-modules/SKILL.md): Wire dependency-cruiser into a TypeScript repo so each package is a deep module.
- [`writing-beats`](./skills/in-progress/writing-beats/SKILL.md) / [`writing-fragments`](./skills/in-progress/writing-fragments/SKILL.md) / [`writing-shape`](./skills/in-progress/writing-shape/SKILL.md): Assemble raw material into a written piece.

### Not installed (4)

`skills/misc/` (`git-guardrails-claude-code`, `migrate-to-shoehorn`, `scaffold-exercises`, `setup-pre-commit`) is **not installed**. `git-guardrails-claude-code` is entirely Claude Code settings/hook configuration and does not apply to DSH; the other three are rarely used odds and ends that upstream itself does not promote (its own `link-skills.sh` skips `misc/` too). `skills/deprecated/` is empty.

## Staying in sync with upstream

```bash
git -C ~/src/DSH-mattpocock-skills fetch upstream
git -C ~/src/DSH-mattpocock-skills merge upstream/main
```

The `upstream` remote already points at `https://github.com/mattpocock/skills`. Current base: upstream main `49dd158`.

---

Upstream's original README, including the four failure modes these skills were built to fix and the full per-skill reference, is reproduced in full at the bottom of [the Chinese README](./README.md), and lives at [mattpocock/skills](https://github.com/mattpocock/skills).
