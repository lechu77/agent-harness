# ADR-0001: NVIDIA SkillSpector Autonomous Skill & MCP Tool Security Gate

- **Status**: Accepted
- **Date**: 2026-09-21
- **Deciders**: Leader Agent / User

---

## Context & Problem Statement
AI coding agents are increasingly reliant on dynamic skills, tool sets, and Model Context Protocol (MCP) integrations (e.g. `SKILL.md`, `.agents/skills/`, community prompt workflows). These capabilities introduce severe attack vectors:
1. **Indirect Prompt Injection**: Hidden text steering the agent to bypass system instructions.
2. **Data Exfiltration**: Stealth network requests via embedded queries, webhooks, or dynamic CSS/images.
3. **Privilege Escalation & Taint**: Unsanitized commands routed into `eval()`, `exec()`, or subshells.
4. **Supply-Chain / Slopsquatting**: Compromised or malicious community skills.

Allowing agents to ingest or execute skills without deterministic verification violates the harness's zero-trust security model. Manual scanning by the developer violates the "Zero Micromanagement / Fire & Forget" core philosophy.

---

## Decision Outcome
**Chosen Option**: Autonomous Dual-Layer SkillSpector Gate (`uvx` CLI + Git Pre-Commit Hook + Agent Protocol).

### Rationale
NVIDIA SkillSpector (`https://github.com/NVIDIA/SkillSpector`) provides comprehensive AST, regex, and taint security analysis tailored for agent skills. By integrating it into `agent-harness`:
- **100% Autonomous**: Executed automatically by agents via terminal tools using `uvx` (zero residual dependencies on the host).
- **Zero Micromanagement**: The user simply instructs the agent in chat. The agent verifies the skill before ingesting it into context.
- **Defense in Depth**: Even if an agent fails to scan a skill during conversation, the Git pre-commit hook intercepts and scans staged skills before any commit can occur.

### Implementation Details
1. **Deterministic Static Execution**:
   - Commands run with `--no-llm --format json` to ensure fast, reproducible, offline-safe checks without external API token costs.
   - Command pattern:
     ```bash
     uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <path-to-skill> --format json --no-llm
     ```
2. **Blocking Thresholds**:
   - Any finding classified as **CRITICAL** or **HIGH** (e.g. prompt injection, unauthorized outbound calls, command injection, path traversal) results in immediate rejection.
   - The agent records the rejection in `progress/current.md` and halts skill ingestion.
3. **Environment Setup (`init.sh`)**:
   - Deploys pre-commit hook logic that scans any staged files under `skills/`, `.agents/skills/`, `.claude/skills/`, or matching `*skill*.md`.
   - Pre-authorizes `Bash(uvx *skillspector*)` in `.claude/settings.json` to prevent interactive approval interruptions.
   - Configures `.cursorrules`, `.windsurfrules`, and `.github/copilot-instructions.md` with explicit skill gate directives.

---

## Considered Alternatives

### Alternative 1: Manual User Verification via Wrapper Script
- **Description**: Provide `./scripts/activate-skill.sh` requiring the human to manually scan skills before giving them to the AI.
- **Why discarded**: Directly breaks the harness core philosophy of "Zero Micromanagement" and "Fire & Forget".

### Alternative 2: Semantic-Only LLM Scan
- **Description**: Rely on the model to read the skill code and judge whether it looks safe.
- **Why discarded**: Susceptible to LLM jailbreaks and indirect prompt injection embedded within the skill itself. Static AST/regex scanning by SkillSpector is deterministic and un-jailbreakable.

---

## Consequences

### Positive (Benefits)
- Automated immunity against malicious skills, prompt injection traps, and supply-chain exploits.
- Zero manual burden on the human developer.
- Offline and local-safe when run with `--no-llm`.
- Zero permanent installation footprint via ephemeral `uvx` execution.

### Negative (Trade-offs / Compromises)
- Requires `uv` / `uvx` available in the host environment for active execution. (If `uvx` is absent, the pre-commit hook emits a warning, and agents must fall back to manual regex audit).
