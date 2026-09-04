# Rock-Solid Vibecoding Agent Harness

> **by Lechu**  
> *Inspired by Anthropic's Agent Harness Research and Hardened with Extreme Cybersecurity & Anti-Exfiltration Defenses.*

A permanent, zero-maintenance harness template for autonomous AI pair programming. 

Set it up **once**, and let your agents handle planning, coding, quality double-checks, and extreme security reviews for all future projects.

---

## The Philosophy: Fire & Forget + Autonomous Guardrails

- **Run `init.sh` ONCE (Fire & Forget)**: Execute `./init.sh` only when bootstrapping a new project. You can even let it delete itself upon completion. Neither you nor the agents ever run it again.
- **Autonomous Multi-Agent Guardrails**: Once initialized, your agents talk to each other to plan, build, sanitize, and audit every change:
  - **Sanitization Guardrail (`reviewer.md`)**: Re-reads all code adversarially, runs test suites independently, strips console logs/debug prints, and enforces architecture conventions.
  - **Cybersecurity & Anti-Exfiltration Guardrail (`security-reviewer.md`)**: Scans every line for hardcoded API keys/tokens, blocks unauthorized network egress, stops prompt injections, and validates supply chain dependencies.
- **Zero Micromanagement**: You don't edit JSON files, task backlogs, or markdown templates. You simply tell your AI in chat what you want to build; the **Leader** agent decomposes tasks and coordinates the guardrails.
- **Tool Agnostic**: Works natively with **Antigravity**, **Cursor**, **GitHub Copilot**, **Windsurf**, and **Claude Code**.
- **Automated Git Safety Gate**: A pre-commit hook automatically blocks any attempt to commit secrets or unredacted credentials to git.

---

## 1. Quick Start: Clone Once, Run Once

### Option A: Starting a New Project from Scratch
```bash
# 1. Clone this template into your new project directory
git clone https://github.com/lechu77/agent-harness.git my-new-project
cd my-new-project

# 2. Run initial setup (detaches template git history, initializes clean repo)
./init.sh my-new-project

# 3. Open your favorite AI tool and start building!
```

### Option B: Adding to an Existing Repository
If you already have an existing project and want to equip it with this harness:
```bash
# 1. Copy the harness files into your existing project root
# (AGENTS.md, TASKS.md, CHECKPOINTS.md, init.sh, agents/, docs/, progress/, etc.)

# 2. Run setup in your existing project
./init.sh

# 3. init.sh detects your existing repo, preserves your git history 100%,
#    and installs the pre-commit security hook!
```

### Smart Git Preservation
- **Template repo detected**: `./init.sh` safely detaches the template git history so you start with a clean slate and no git conflicts.
- **Existing project detected**: `./init.sh` **never** touches or deletes your `.git` folder. All existing branches, remotes, and commit history remain completely intact.

Once this exits green, **you are done with setup forever**.

---

## 2. How the Agents Work Together

All agent roles reside in `agents/` and are read directly by your AI tool:

```
Leader (Orchestrator)
  │
  ├── 1. Reads your prompt from chat and updates TASKS.md
  │
  ├── 2. Implementer (Feature Worker)
  │      └── Writes production code + automated tests for exactly ONE task
  │
  ├── 3. Reviewer (Adversarial Quality Auditor — Double-Check)
  │      └── Runs test suite independently, checks edge cases & CHECKPOINTS.md
  │
  └── 4. Security Reviewer (Extreme Cybersecurity & Exfiltration Gate)
         └── Audits secrets, network egress whitelist, PII, package hallucinations, git exposure
```

**Rule**: The Leader marks a task completed (`[x]`) ONLY after both the Reviewer (`APPROVED`) and Security Reviewer (`SECURE`) have passed.

---

## 3. Extreme Cybersecurity & Anti-Exfiltration Defenses

This harness implements a defense-in-depth model specifically designed for autonomous AI coding:

| Attack / Risk Vector | How This Harness Defends Against It |
|---|---|
| **Data Exfiltration via HTTP** | **Zero-Trust Egress Policy**: Only domains on the explicit whitelist in `docs/security.md` are permitted. Any unapproved network call is an automatic blocker. |
| **Stealth Exfiltration** | Scans for markdown image tags (`![img](https://...?token=...)`), dynamic CSS `url()`, and DNS exfiltration patterns. |
| **Package Hallucinations / Slopsquatting** | Prohibits AI agents from inventing package names. Dependencies must be verified against official registries with version pinning and lockfile enforcement. |
| **Hardcoded Secrets** | Scans regex patterns for API keys, tokens, bearer headers, and private keys across code, tests, and progress reports. |
| **Environment Variable Dumps** | Explicit ban on `process.env` / `os.environ` dumps in logs, console output, API responses, and error traces. |
| **Git Exposure** | Pre-commit hook blocks secret commits; `.gitignore` strictly excludes `.env*`, `.pem`, `.key`, `.db`, and SQLite files. |
| **Prompt Injection Defense** | **Quarantine External Data**: All web-scraped content and user files are treated as passive data without execution privileges. Agents are forbidden from reading `.env` while processing external text. |
| **Path Neutrality (Zero Host Leaks)** | Ban on absolute system paths (`/Users/...`, `/home/...`). All paths must be repository-relative to prevent leaking workstation usernames or internal infrastructure details. |
| **Offline Test Isolation** | Test suites must run cleanly without live internet access, eliminating test-time telemetry or socket exfiltration. |
| **Canary Tokens** | Recommends canary traps in test fixtures to instantly detect unauthorized token exfiltration. |

---

## 4. Tool Auto-Recognition

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

## 5. Repository Structure

```
.
├── AGENTS.md                         # Universal navigation map (entry point for agents)
├── TASKS.md                          # Markdown task backlog (managed by Leader)
├── SETUP.md                          # Multi-tool reference documentation
├── CHECKPOINTS.md                    # Objective pass/fail criteria (C1–C6)
├── init.sh                           # One-time bootstrap & baseline verification
├── .gitignore                        # Standard exclusions (secrets, DBs, node_modules)
├── .cursorrules                      # Cursor config
├── .windsurfrules                    # Windsurf config
├── .github/
│   └── copilot-instructions.md       # Copilot config
├── .claude/
│   └── settings.json                 # Claude Code hooks
├── CLAUDE.md                         # Claude Code config
├── agents/                           # Agent role definitions
│   ├── leader.md                     # Orchestrator & task planner
│   ├── implementer.md                # Code and test builder
│   ├── reviewer.md                   # Double-check quality auditor (read-only)
│   └── security-reviewer.md          # Security & git exposure auditor (read-only)
├── docs/                             # Progressive disclosure guides
│   ├── architecture.md               # Architectural layers and prohibited patterns
│   ├── conventions.md                # Language style & testing standards
│   ├── security.md                   # Extreme security policy & egress whitelist
│   └── verification.md               # Evidence-based testing protocols
└── progress/                         # Persistent disk state (Anti-telephone rule)
    ├── current.md                    # Active task scratchpad
    └── history.md                    # Completed task chronological log
```
