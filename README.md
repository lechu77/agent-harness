# Rock-Solid Vibecoding Agent Harness

> **by Lechu**  
> *Inspired by Anthropic's Agent Harness Research and Hardened with Extreme Cybersecurity & Anti-Exfiltration Defenses.*

A permanent, zero-maintenance harness template for autonomous AI pair programming. 

Set it up **once**, and let your agents handle planning, coding, quality double-checks, and extreme security reviews for all future projects.

---

## The Philosophy: Zero Micromanagement

- **Run `init.sh` ONCE**: Execute `./init.sh [project-name]` only when bootstrapping a new project. You never have to touch it again.
- **No JSON Backlog Editing**: No manual editing of status fields or JSON syntax. You simply tell your AI in chat what you want to build. The **Leader** agent autonomously creates, tracks, and updates tasks in [`TASKS.md`](TASKS.md).
- **Tool Agnostic**: Works out-of-the-box with **Antigravity**, **Cursor**, **GitHub Copilot**, **Windsurf**, and **Claude Code**.
- **Extreme Cybersecurity & Anti-Exfiltration**: Hardened against credential leaks, supply chain poisoning (package hallucinations), stealth data exfiltration, and unauthorized network egress.
- **Automated Git Safety Gate**: A pre-commit hook automatically blocks any attempt to commit secrets or unredacted credentials to git.

---

## 1. Quick Start: Clone Once, Run Once

Whenever you start a new project:

```bash
# 1. Clone this template into your new project directory
git clone <your-template-repo-url> my-new-project
cd my-new-project

# 2. Run initial setup (ONCE)
./init.sh my-new-project

# 3. Open your favorite AI tool and start building!
```

### What `./init.sh` does during setup:
1. **Detaches template git history** (`rm -rf .git`), runs `git init -b main`, and creates a clean baseline commit with zero git conflicts.
2. **Resets progress files** (`progress/current.md` and `progress/history.md`).
3. **Installs automated pre-commit hook** (`.git/hooks/pre-commit`) to automatically block staged API keys, passwords, or tokens.
4. **Validates harness integrity** to ensure all agents and documentation are healthy.

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
