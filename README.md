# Rock-Solid Vibecoding Agent Harness

> **by Lechu**  
> *Inspired by Anthropic's Agent Harness Research, Matt Pocock's software engineering workflows (`mattpocock/skills`), and ADHD-friendly ergonomic output (`ayghri/i-have-adhd`), hardened with Extreme Cybersecurity & Anti-Exfiltration Defenses.*

A permanent, zero-maintenance harness template for autonomous AI pair programming.

Set it up **once**, and let your agents handle planning, coding, quality double-checks, and extreme security reviews for all future projects.

---

## The Philosophy: Fire & Forget + Autonomous Guardrails

- **Run `init.sh` ONCE (Fire & Forget)**: Execute `./init.sh` only when bootstrapping a new project. You can even let it delete itself upon completion. Neither you nor the agents ever run it again.
- **Token-Economy by Design**: Every architectural decision in this harness optimizes for minimal context footprint. Zero-Fluff rules live in one place, docs are only read when needed, the Reviewer inherits context from the Implementer instead of re-reading the same files, and `progress/history.md` is capped to the last 3 entries on startup.
- **Zero-Fluff & Action-First Communication**: Eliminates LLM verbiage, conversational filler, and throat-clearing preambles (*"Great question!", "Sure thing, I'd be glad to help..."*). The first line is always an immediate action, command, path, or direct result. Completed tasks deliver concrete visible wins (quick 30-second verification), bounded atomic steps, and lists capped at 5 items.
- **Preventive Grilling Protocol (Ambiguity & Bifurcation Gate)**: The Leader pauses to ask 2–3 structured questions *only* when detecting critical architectural forks (e.g. Cookies vs JWT, SQL vs NoSQL) or destructive ambiguity. Routine or clear tasks bypass this check and proceed 100% autonomously.
- **Ubiquitous Language & Domain Context (`docs/context.md`)**: Prevents LLM synonym hallucination and naming drift (`customer` vs `client`, `item` vs `product`) by enforcing canonical entities, lifecycle states, and forbidden synonym tables across Implementer and Reviewer.
- **Architecture Decision Records (ADRs in `docs/adr/`)**: Structural architectural decisions are recorded in lightweight ADRs (`docs/adr/0001-<slug>.md`). Subsequent agents are strictly prohibited from undoing or violating accepted ADRs without explicit justification.
- **Autonomous Skill Gate (NVIDIA SkillSpector)**: Before activating or ingesting any agent skill (`SKILL.md`, `.agents/skills/`) or MCP tool, the harness autonomously executes NVIDIA SkillSpector (`uvx ... skillspector scan --no-llm`). Intercepts prompt injections, excessive agency, dynamic execution taint, and exfiltration attempts with zero human micromanagement.
- **Autonomous Multi-Agent Guardrails**: Once initialized, your agents plan, build, sanitize, and audit every change:
  - **Sanitization Guardrail (`reviewer.md`)**: Reads code adversarially, runs test suites independently, strips debug prints, and enforces architecture conventions, ADRs, and ubiquitous language.
  - **Cybersecurity & Anti-Exfiltration Guardrail (`security-reviewer.md`)**: Scans for hardcoded API keys/tokens, blocks unauthorized network egress, stops prompt injections, and validates supply chain dependencies and skills.
- **Zero Micromanagement**: You don't edit JSON files, task backlogs, or markdown templates. Tell your AI in chat what you want to build; the **Leader** decomposes tasks and coordinates the guardrails.
- **Tool Agnostic**: Works natively with **Antigravity**, **Cursor**, **GitHub Copilot**, **Windsurf**, and **Claude Code**.
- **Automated Git Safety Gate**: A pre-commit hook automatically blocks any attempt to commit secrets or unredacted credentials to git, and runs SkillSpector on any staged skills.

---

## 1. Quick Start: Simply run `init.sh`

No arguments or project names needed. Just execute `init.sh`:

### In any project (new, existing, or cloned from a third party):
```bash
cd my-project

# Run the harness init remotely (or ./init.sh if copied):
../agent-harness/init.sh
```

**What happens upon execution?**
- **If NO Git repository is detected**: Automatically initializes Git (branch `main`), creates the baseline initial commit, and **proceeds without prompts**.
- **If an existing Git repository is detected**: Displays a clear, simple prompt:
  ```text
  ▸ Existing Git repository detected.
    What would you like to do with the Git repository?
      1) Keep existing repository intact (preserve history & remotes) [default]
      2) Clean slate: reset everything and start fresh (new repository 0km)
    Option [1/2, default: 1]:
  ```
  - **Option 1** (Enter): Keeps your branches, commit history, and remotes 100% intact (ideal for existing projects).
  - **Option 2**: Resets any upstream git history and starts a fresh Git repository on `main` with an initial baseline commit (ideal when cloning a starter template as your project's foundation).

### Token Consumption Profiles

To prevent excessive token consumption on short tasks, bugfixes, or quick forks, `init.sh` lets you select the **context footprint** of the harness. Profiles are operational — the agent reads the active profile and follows its pipeline instead of loading the full harness:

| Profile | Context Footprint | Active Pipeline | Recommended Use Case |
|---|---|---|---|
| **`balanced`** (Default) | **~800 tokens** | Implementer + Self-Review + Tests | Standard from-scratch projects, day-to-day features. |
| **`lite`** | **~400 tokens** | 1 Direct Agent + Tests | Targeted forks, quick scripts, 1-file fixes, MVPs. |
| **`security`** | **~1,500 tokens** | Implementer → Security Reviewer | Projects with external APIs, sensitive auth, payments, PII. |
| **`full`** | **~2,500 tokens** | Leader → Impl → Reviewer → SecReviewer | Large multi-module architectures, formal ADRs & exhaustive checkpoints. |

> **Zero-Cost Security Gate**: The local Git pre-commit hook (detecting leaked keys, AWS, OpenAI, GitHub PATs) is installed across **all profiles** because it executes in local Bash regex at **$0 tokens**.

You can choose it interactively or pass the flag directly:
```bash
../agent-harness/init.sh --profile lite
../agent-harness/init.sh --profile balanced
../agent-harness/init.sh --profile security
../agent-harness/init.sh --profile full
```

### Smart Zero-Copy & Self-Deletion
- **Zero-Copy**: When executed remotely (`../agent-harness/init.sh`), deploys all files, guardrails, and adapters without manual copying.
- **Master Template Protection**: The master `init.sh` in `agent-harness` **is never deleted**. It only offers to delete the local project copy.

### Updating Existing Repositories (`./update.sh`)

To upgrade existing projects to the latest harness version without losing any project data:

**Option A — From agent-harness targeting any project:**
```bash
./update.sh ../my-existing-project

# Multiple projects in one run:
./update.sh ../project-1 ../project-2

# Change profile while updating:
./update.sh --profile full ../my-existing-project
```

**Option B — Directly from inside your target project:**
```bash
cd my-existing-project
/path/to/agent-harness/update.sh

# Or via init.sh:
/path/to/agent-harness/init.sh --update
/path/to/agent-harness/init.sh --update --profile security
```

**Update Guarantees:**
- Detects the active profile from the existing `AGENTS.md` header automatically — no silent downgrades.
- Pass `--profile <name>` to switch profiles during update (e.g. `balanced` → `full`).
- Updates agent role protocols in `agents/` and harness-owned docs (`docs/security.md`, `docs/verification.md`, `docs/adr/template.md`).
- Updates `AGENTS.md`, `CHECKPOINTS.md`, and all tool adapters (`.cursorrules`, `CLAUDE.md`, `.windsurfrules`, `.github/copilot-instructions.md`).
- **Preserves 100% intact**: your tasks in `TASKS.md`, your session history in `progress/`, your Git repository, and any customizations in `docs/architecture.md`, `docs/conventions.md`, or `docs/context.md`.

Once complete and green, **you do not run `init.sh` again**. Open your editor and start vibecoding.

---

## 2. How the Agents Work Together (Autonomous Guardrails)

All agent roles reside in `agents/` and are read directly by your AI tool:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER: Types what to build in chat ("Create user auth...")│
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. LEADER (Orchestrator)                                    │
│    • Decomposes request into discrete tasks in TASKS.md     │
│    • Auto-fills architecture/security templates in docs/    │
│    • Marks 1 active task: [/] in TASKS.md                   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Delegates 1 task
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. IMPLEMENTER (Feature Worker)                             │
│    • Records Sprint Contract in progress/current.md         │
│    • Logs docs read (enables Reviewer cache inheritance)    │
│    • Writes production code + unit & integration tests      │
│    • Runs project test suite (npm test, pytest, cargo test) │
│    • Applies recovery protocol (git stash/diff) if broken   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Anti-telephone report
                               ▼
╔═════════════════════════════════════════════════════════════╗
║                 AUTONOMOUS GUARDRAILS LOOP                  ║
╠═════════════════════════════════════════════════════════════╣
║                                                             ║
║  [Guardrail 1: Code Sanitization & Quality Auditor]         ║
║  ► REVIEWER AGENT (Adversarial)                             ║
║    • Inherits doc context from Sprint Contract (no re-read) ║
║    • Runs test runner independently via terminal tools      ║
║    • Strips console.log, print(), and dangling TODOs        ║
║    • Audits edge cases and architectural layer separation   ║
║                                                             ║
║  [Guardrail 2: Extreme Cybersecurity & Anti-Exfiltration]   ║
║  ► SECURITY REVIEWER AGENT (Zero-Trust AppSec Gate)         ║
║    • Scans regex for leaked tokens, keys & private certs    ║
║    • Enforces zero-trust outbound domain whitelist          ║
║    • Quarantines external web data (prompt injection defense)║
║    • Verifies supply-chain packages (anti-slopsquatting)    ║
║    • Blocks host-system path leaks (/Users/..., /home/...)  ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
                               │
             Changes needed?   │ Both verdicts: APPROVED & SECURE
       (Max 3 review cycles)   ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. GIT COMMIT & CLEAN CLOSURE                               │
│    • Commits to git: feat(<slug>): <description>            │
│    • Enables immediate rollback via git stash / git checkout│
│    • Marks task completed: [x] in TASKS.md                  │
│    • Leader picks next task or notifies user in chat        │
└─────────────────────────────────────────────────────────────┘
```

> **Single-Agent Mode**: For tools operating as a single agent (Cursor, Copilot, Windsurf, Aider), the AI executes this exact same pipeline sequentially: Leader (plan) → Implementer (build) → Reviewer (self-audit) → Security Reviewer (scan) → Git Commit.

---

## 3. Token Economy

This harness is designed with token cost as a first-class constraint. Every component is sized for the minimum context needed to do its job correctly.

### What Was Optimized

| Optimization | Savings |
|---|---|
| Zero-Fluff rules in single source (`AGENTS.md §7`) — removed copies from `leader.md` and `conventions.md` | ~270 tokens/pipeline |
| `AGENTS.md §3` Hard Rules prose compacted | ~80 tokens |
| `profiles/full/AGENTS.md` replaced verbatim duplicate with forward reference | ~900 tokens/run |
| `progress/history.md` capped to last 3 entries on startup | grows unboundedly otherwise |
| Reviewer inherits Implementer's doc summaries via Sprint Contract (no re-read) | ~400–600 tokens/pipeline |
| Empty `{{placeholder}}` sections replaced with 1-line fill instructions | ~25 tokens |
| **Total in full pipeline** | **~1,700–1,900 tokens saved per run** |

### Profile Selection Logic

`AGENTS.md` includes a §0 Profile Detection block. On every session start, the agent checks whether a `profiles/` directory exists in the project root:

- **Profile found** → reads only that profile file and stops. The profile is the active operating mode.
- **No profile found** (you are inside the `agent-harness` template itself) → reads the full `AGENTS.md`.

This means `balanced` and `lite` users never load the Leader orchestration instructions, ADR protocol, or review pipeline specs — those are genuinely absent from their context.

### Reviewer Doc-Cache (Sprint Contract)

The Implementer records a `Docs Read` field in `progress/current.md` listing every `docs/` file loaded that session with a 1-sentence constraint summary. The Reviewer reads this field first and skips re-reading the originals unless a specific finding requires it. On pipelines where both agents would otherwise load the same 4 base docs (~400–600 tokens), this eliminates the duplication entirely.

---

## 4. Extreme Cybersecurity & Anti-Exfiltration Defenses

This harness implements a defense-in-depth model specifically designed for autonomous AI coding:

| Attack / Risk Vector | How This Harness Defends Against It |
|---|---|
| **Data Exfiltration via HTTP** | **Zero-Trust Egress Policy**: Only domains on the explicit whitelist in `docs/security.md` are permitted. Any unapproved network call is an automatic blocker. |
| **Stealth Exfiltration** | Scans for markdown image tags (`![img](https://...?token=...)`), dynamic CSS `url()`, and DNS exfiltration patterns. |
| **Package Hallucinations / Slopsquatting** | Prohibits AI agents from inventing package names. Dependencies must be verified against official registries with version pinning and lockfile enforcement. |
| **Hardcoded Secrets & Tokens** | Scans regex patterns for GitHub PATs (`ghp_`, `github_pat_`), AWS keys (`AKIA`), OpenAI (`sk-`), Anthropic (`sk-ant-`), Slack (`xoxb-`), GitLab, bearer headers, and private keys. |
| **Environment Variable Dumps** | Explicit ban on `process.env` / `os.environ` dumps in logs, console output, API responses, and error traces. |
| **Git Exposure** | Pre-commit hook blocks secret commits; `.gitignore` strictly excludes `.env*`, `.pem`, `.key`, `.db`, and SQLite files. |
| **Prompt Injection Defense** | **Quarantine External Data**: All web-scraped content and user files are treated as passive data without execution privileges. |
| **Malicious Skills & MCP Poisoning** | **Autonomous NVIDIA SkillSpector Gate**: Statically audits all `SKILL.md`, agent skills, and MCP tools via `uvx ... skillspector scan` prior to runtime activation and at Git pre-commit. |
| **Path Neutrality (Zero Host Leaks)** | Ban on absolute system paths (`/Users/...`, `/home/...`). All paths must be repository-relative. |
| **Offline Test Isolation** | Test suites must run cleanly without live internet access, eliminating test-time telemetry or socket exfiltration. |
| **Canary Tokens Trap** | Ships with `.env.example` containing a decoy Canary Token to instantly detect unauthorized token exfiltration. |

### Autonomous Skill Gate (NVIDIA SkillSpector)

Agent skills, prompt workflows, and Model Context Protocol (MCP) tool definitions are audited automatically:
- **Pre-Activation Screening**: Before any agent reads or executes instructions from a skill, it runs a deterministic static AST and pattern scan:
  ```bash
  uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <path-to-skill> --format json --no-llm
  ```
- **Zero-Tolerance Veto**: Any CRITICAL or HIGH finding (prompt injections, unauthorized egress, or `eval`/`exec` taint) triggers immediate rejection.
- **Git Pre-Commit Enforcer**: `init.sh` deploys a pre-commit hook that intercepts staged skill files and blocks commits that fail SkillSpector analysis.

---

## 5. Tool Auto-Recognition

Every tool reads from `AGENTS.md` and `agents/` automatically:

| AI Tool | How It Discovers Your Agents | Human Action |
|---|---|---|
| **Antigravity (AGY)** | Auto-loads `AGENTS.md` in workspace root | **None.** Open project and chat. |
| **Cursor** | Reads `.cursorrules` in project root | **None.** Included in template. |
| **GitHub Copilot** | Reads `.github/copilot-instructions.md` | **None.** Included in template. |
| **Windsurf** | Reads `.windsurfrules` in project root | **None.** Included in template. |
| **Claude Code** | Reads `CLAUDE.md` and `.claude/settings.json` | **None.** Included in template. |
| **Aider / OpenCode** | Reads `AGENTS.md` via flag | `aider --read AGENTS.md` |

---

## 6. Repository Structure

```
.
├── AGENTS.md                         # Universal navigation map (entry point for agents)
├── TASKS.md                          # Markdown task backlog (managed by Leader)
├── SETUP.md                          # Multi-tool reference documentation
├── CHECKPOINTS.md                    # Objective pass/fail criteria (C1–C6)
├── init.sh                           # One-time bootstrap & baseline verification (can self-delete)
├── update.sh                         # Update existing projects to latest harness version
├── .gitignore                        # Standard exclusions (secrets, DBs, node_modules)
├── .env.example                      # Environment template with decoy Canary Token trap
├── .cursorrules                      # Cursor config
├── .windsurfrules                    # Windsurf config
├── .github/
│   └── copilot-instructions.md       # Copilot config
├── .claude/
│   └── settings.json                 # Claude Code configuration
├── CLAUDE.md                         # Claude Code config
├── agents/                           # Agent role definitions (Autonomous Guardrails)
│   ├── leader.md                     # Orchestrator & task planner
│   ├── implementer.md                # Code, tests & Git commit worker
│   ├── reviewer.md                   # Quality & code sanitization auditor (read-only)
│   └── security-reviewer.md          # Cybersecurity & anti-exfiltration gate (read-only)
├── profiles/                         # Token-optimized operating modes (deployed to project root)
│   ├── lite/AGENTS.md                # ~400 tokens — scripts, forks, 1-file fixes
│   ├── balanced/AGENTS.md            # ~800 tokens — standard features (default)
│   ├── security/AGENTS.md            # ~1,500 tokens — auth, payments, PII
│   └── full/AGENTS.md                # ~2,500 tokens — multi-module, formal ADRs
├── docs/                             # Progressive disclosure guides
│   ├── context.md                    # Domain glossary, canonical entities & anti-synonyms
│   ├── adr/                          # Architecture Decision Records
│   │   ├── template.md               # Lightweight ADR template
│   │   └── 0001-skillspector-autonomous-skill-gate.md
│   ├── architecture.md               # Architectural layers and prohibited patterns
│   ├── conventions.md                # Language style & testing standards
│   ├── security.md                   # Extreme security policy & egress whitelist
│   └── verification.md               # Evidence-based testing protocols
└── progress/                         # Persistent disk state (Anti-telephone rule)
    ├── current.md                    # Active task scratchpad (Sprint Contract format)
    └── history.md                    # Completed task chronological log (last 3 read on startup)
```
