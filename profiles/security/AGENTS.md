# AGENTS.md — Agent Harness (Security-Hardened Profile)

> Profile: **Security-Hardened** (~1,500 tokens context footprint). Optimized for projects with sensitive data, APIs, auth, or payments.
> Dual-agent pipeline: Implementer → Security Reviewer, with mandatory zero-trust verification.

---

## 1. Core Workflow

1. **Task Selection**: Read `TASKS.md`, select next pending task, mark `[/]` in progress, log in `progress/current.md`.
2. **Implementation**:
   - Follow `docs/architecture.md`, `docs/conventions.md`, and `docs/security.md`.
   - Write production code and comprehensive tests.
   - Run tests via terminal tool; all tests must pass 100% green.
3. **Security Gate**:
   - Audit all staged changes against `docs/security.md`:
     1. Zero hardcoded secrets, tokens, keys, passwords.
     2. Zero unauthorized external network egress / endpoints.
     3. Verify Canary Token in `.env.example` has not leaked into code or logs.
     4. Dependency vetting: verify third-party packages exist in official registries (prevent slopsquatting).
     5. Scan skills/MCP tools using SkillSpector if applicable (`uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <target> --format json --no-llm`).
4. **Closure & Commit**:
   - Commit: `git commit -m "feat(<task>): <description>"`.
   - Mark `[x]` in `TASKS.md`, update `progress/history.md`.

---

## 2. Hard Rules (Non-Negotiable)

- **Zero-trust egress.** No background outbound HTTP/WebSocket requests without explicit authorization.
- **Never commit secrets or canary tokens.** Any detected credential blocks the task immediately.
- **One task at a time.** Exactly ONE task active in `TASKS.md`.
- **No done without evidence.** All tests and security verifications must have terminal proof.
- **Path neutrality.** Always use relative paths from project root.
- **Zero-fluff communication.** Line 1 is the next action, file path, or direct result.
