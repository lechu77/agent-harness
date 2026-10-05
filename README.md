# Rock-Solid Vibecoding Agent Harness

> **by Lechu**  
> *Inspired by Anthropic's Agent Harness Research, Matt Pocock's software engineering workflows (`mattpocock/skills`), and ADHD-friendly ergonomic output (`ayghri/i-have-adhd`), hardened with Extreme Cybersecurity & Anti-Exfiltration Defenses.*

A permanent, zero-maintenance harness template for autonomous AI pair programming. 

Set it up **once**, and let your agents handle planning, coding, quality double-checks, and extreme security reviews for all future projects.

---

## The Philosophy: Fire & Forget + Autonomous Guardrails

- **Run `init.sh` ONCE (Fire & Forget)**: Execute `./init.sh` only when bootstrapping a new project. You can even let it delete itself upon completion. Neither you nor the agents ever run it again.
- **Zero-Fluff & Action-First Communication**: Inspired by cognitive ease and `ayghri/i-have-adhd`, eliminates LLM verbiage, conversational filler, and throat-clearing preambles (*"¡Gran pregunta!", "Claro, con gusto..."*). The first line is always an immediate action, command, path, or direct result. Completed tasks deliver concrete visible wins (quick 30-second verification), bounded atomic steps, and lists capped at 5 items.
- **Preventive Grilling Protocol (Ambiguity & Bifurcation Gate)**: Inspired by Matt Pocock's prompt-interview techniques, the Leader pauses to ask 2–3 structured questions *only* when detecting critical architectural forks (e.g. Cookies vs JWT, SQL vs NoSQL) or destructive ambiguity. Routine or clear tasks bypass this check and proceed 100% autonomously.
- **Ubiquitous Language & Domain Context (`docs/context.md`)**: Prevents LLM synonym hallucination and naming drift (`customer` vs `client`, `item` vs `product`) by enforcing canonical entities, lifecycle states, and forbidden synonym tables across Implementer and Reviewer.
- **Architecture Decision Records (ADRs in `docs/adr/`)**: Structural architectural decisions are recorded in lightweight ADRs (`docs/adr/0001-<slug>.md`). Subsequent agents are strictly prohibited from undoing or violating accepted ADRs without explicit justification.
- **Autonomous Skill Gate (NVIDIA SkillSpector)**: Before activating or ingesting any agent skill (`SKILL.md`, `.agents/skills/`) or MCP tool, the harness autonomously executes NVIDIA SkillSpector (`uvx ... skillspector scan --no-llm`). Intercepts prompt injections, excessive agency, dynamic execution taint, and exfiltration attempts in background with zero human micromanagement.
- **Autonomous Multi-Agent Guardrails**: Once initialized, your agents talk to each other to plan, build, sanitize, and audit every change:
  - **Sanitization Guardrail (`reviewer.md`)**: Re-reads all code adversarially, runs test suites independently, strips console logs/debug prints, and enforces architecture conventions, ADRs, and ubiquitous language.
  - **Cybersecurity & Anti-Exfiltration Guardrail (`security-reviewer.md`)**: Scans every line for hardcoded API keys/tokens, blocks unauthorized network egress, stops prompt injections, and validates supply chain dependencies and skills.
- **Zero Micromanagement**: You don't edit JSON files, task backlogs, or markdown templates. You simply tell your AI in chat what you want to build; the **Leader** agent decomposes tasks and coordinates the guardrails.
- **Tool Agnostic**: Works natively with **Antigravity**, **Cursor**, **GitHub Copilot**, **Windsurf**, and **Claude Code**.
- **Automated Git Safety Gate**: A pre-commit hook automatically blocks any attempt to commit secrets or unredacted credentials to git, and runs SkillSpector on any staged skills.

---

## 1. Quick Start: Solo ejecutás `init.sh` a secas

No necesitás pasarle argumentos ni nombres de proyecto. Solo ejecutás `init.sh`:

### En cualquier proyecto (nuevo, existente o clonado de un tercero):
```bash
cd mi-proyecto

# Ejecutás el init de tu harness remotamente (o ./init.sh si lo copiaste):
../agent-harness/init.sh
```

**¿Qué pasa al ejecutarlo?**
- **Si NO detecta Git**: Inicializa Git automáticamente (`main`), crea el commit baseline inicial y **sigue de largo sin preguntar nada**.
- **Si detecta un Git existente**: Te muestra un prompt simple y directo:
  ```text
  ▸ Repositorio Git existente detectado.
    ¿Qué querés hacer con el repositorio Git?
      1) Mantener el repo actual intacto (conservar historial y remotes) [default]
      2) Planchar todo y empezar de cero (Clean slate: nuevo repo 0km)
    Opción [1/2, default: 1]:
  ```
  - **Opción 1** (Enter): Mantiene tus ramas, historial y remotes 100% intactos (ideal para tus proyectos existentes como `ShadowerNinja`).
  - **Opción 2**: Plancha el Git ajeno y te inicializa un Git 0km en `main` con commit baseline (ideal cuando te clonás un repo ajeno como base para un proyecto propio).

### Perfiles de Consumo de Tokens (Profiles)
Para que el harness no te genere costos excesivos en proyectos cortos, forks o scripts rápidos, `init.sh` te permite elegir el **peso en tokens** del harness:

| Perfil | Overhead de Contexto | Pipeline | Cuándo usarlo |
|---|---|---|---|
| **`balanced`** (Default) | **~460 tokens** (Bajo) | Implementer + Self-Review + Tests | Proyectos estándar from-scratch, features del día a día. |
| **`lite`** | **~380 tokens** (Mínimo) | 1 Agente directo + Tests | Forks puntuales, scripts rápidos, fixes de 1 archivo, MVPs. |
| **`security`** | **~480 tokens** (Medio) | Implementer → Security Reviewer | Proyectos con APIs externas, auth sensible, pagos, PII. |
| **`full`** | **~2.478 tokens** (Completo) | Leader → Impl → Reviewer → SecReviewer | Sistemas grandes, multi-módulo, ADRs y checkpoints exhaustivos. |

> **Nota de costo:** El pre-commit hook de Git (detección de tokens, AWS, OpenAI, GitHub PATs) se instala en **todos los perfiles** porque corre en Bash local y cuesta **$0 tokens**.

Podés seleccionarlo interactivamente o pasar la flag directa:
```bash
../agent-harness/init.sh --profile lite
../agent-harness/init.sh --profile balanced
../agent-harness/init.sh --profile security
../agent-harness/init.sh --profile full
```

### Smart Zero-Copy & Self-Deletion
- **Zero-Copy**: Al correrlo remotamente (`../agent-harness/init.sh`), despliega todos los archivos, guardrails y adaptadores sin que tengas que copiar nada a mano.
- **Protección de la plantilla maestra**: El `init.sh` original de `agent-harness` **nunca se borra**. Solo ofrece eliminar la copia local del proyecto destino.

### Actualizar repositorios existentes (`./update.sh`)
Si ya tenías proyectos usando una versión previa de `agent-harness` y querés incorporar las últimas mejoras (Zero-Fluff communication, ADRs, Grilling preventivo, Ubiquitous Language) sin perder nada:

**Opción A — Desde agent-harness hacia cualquier proyecto:**
```bash
./update.sh ../mi-proyecto-existente
# Podés pasar múltiples proyectos en una sola línea:
# ./update.sh ../proyecto-1 ../proyecto-2
```

**Opción B — Desde adentro de tu proyecto existente:**
```bash
cd mi-proyecto-existente
/ruta/hacia/agent-harness/update.sh
# O alternativamente con init.sh:
# /ruta/hacia/agent-harness/init.sh --update
```

**Garantías de la actualización:**
- Actualiza los roles en `agents/` con los últimos protocolos.
- Actualiza `AGENTS.md` (Zero-fluff communication), `CHECKPOINTS.md` y adaptadores de herramientas (`.cursorrules`, `CLAUDE.md`, `.windsurfrules`, `.github/copilot-instructions.md`).
- Despliega `docs/adr/template.md` y `docs/context.md` (si faltaban).
- **Preserva intactos**: tus tareas en `TASKS.md`, tu historial en `progress/`, tu repositorio Git, y las personalizaciones previas en `docs/architecture.md` o `docs/conventions.md`.

Una vez que termina en verde, **no volvés a ejecutar `init.sh`**. Abrís tu editor y empezás a vibecodear.


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
            ¿Changes needed?   │ Both verdicts: APPROVED & SECURE
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

## 3. Extreme Cybersecurity & Anti-Exfiltration Defenses

This harness implements a defense-in-depth model specifically designed for autonomous AI coding:

| Attack / Risk Vector | How This Harness Defends Against It |
|---|---|
| **Data Exfiltration via HTTP** | **Zero-Trust Egress Policy**: Only domains on the explicit whitelist in `docs/security.md` are permitted. Any unapproved network call is an automatic blocker. |
| **Stealth Exfiltration** | Scans for markdown image tags (`![img](https://...?token=...)`), dynamic CSS `url()`, and DNS exfiltration patterns. |
| **Package Hallucinations / Slopsquatting** | Prohibits AI agents from inventing package names. Dependencies must be verified against official registries with version pinning and lockfile enforcement. |
| **Hardcoded Secrets & Tokens** | Scans regex patterns for GitHub PATs (`ghp_`, `github_pat_`), AWS keys (`AKIA`), OpenAI (`sk-`), Anthropic (`sk-ant-`), Slack (`xoxb-`), GitLab, bearer headers, and private keys. |
| **Environment Variable Dumps** | Explicit ban on `process.env` / `os.environ` dumps in logs, console output, API responses, and error traces. |
| **Git Exposure** | Pre-commit hook blocks secret commits; `.gitignore` strictly excludes `.env*`, `.pem`, `.key`, `.db`, and SQLite files. |
| **Prompt Injection Defense** | **Quarantine External Data**: All web-scraped content and user files are treated as passive data without execution privileges. Agents are forbidden from reading `.env` while processing external text. |
| **Malicious Skills & MCP Poisoning** | **Autonomous NVIDIA SkillSpector Gate**: Statically audits all `SKILL.md`, agent skills, and MCP tools via `uvx ... skillspector scan` prior to runtime activation and at Git pre-commit. |
| **Path Neutrality (Zero Host Leaks)** | Ban on absolute system paths (`/Users/...`, `/home/...`). All paths must be repository-relative to prevent leaking workstation usernames or internal infrastructure details. |
| **Offline Test Isolation** | Test suites must run cleanly without live internet access, eliminating test-time telemetry or socket exfiltration. |
| **Canary Tokens Trap** | Ships with `.env.example` containing a decoy Canary Token to instantly detect unauthorized token exfiltration. |

### Autonomous Skill Gate (NVIDIA SkillSpector)

Agent skills, prompt workflows, and Model Context Protocol (MCP) tool definitions are audited automatically without human micromanagement:
- **Pre-Activation Screening**: Before any agent reads or executes instructions from a skill (`SKILL.md`, `.agents/skills/`), it runs a deterministic static AST and pattern scan:
  ```bash
  uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <path-to-skill> --format json --no-llm
  ```
- **Zero-Tolerance Veto**: Any CRITICAL or HIGH finding (instruction overrides, prompt injections, unauthorized egress, or `eval`/`exec` taint) triggers immediate rejection and halts skill ingestion.
- **Git Pre-Commit Enforcer**: `init.sh` deploys a pre-commit hook that intercepts any staged skill files and blocks git commits that fail SkillSpector analysis.

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
├── init.sh                           # One-time bootstrap & baseline verification (can self-delete)
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
├── docs/                             # Progressive disclosure guides
│   ├── context.md                    # Domain glossary, canonical entities & anti-synonyms
│   ├── adr/                          # Architecture Decision Records
│   │   ├── template.md               # Lightweight ADR template
│   │   └── 0001-skillspector-autonomous-skill-gate.md # SkillSpector gate ADR
│   ├── architecture.md               # Architectural layers and prohibited patterns
│   ├── conventions.md                # Language style & testing standards
│   ├── security.md                   # Extreme security policy & egress whitelist
│   └── verification.md               # Evidence-based testing protocols
└── progress/                         # Persistent disk state (Anti-telephone rule)
    ├── current.md                    # Active task scratchpad
    └── history.md                    # Completed task chronological log
```
