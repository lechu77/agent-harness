# Setup Guide — Configure Your AI Coding Tool

This harness operates on a **zero-micromanagement, fire-and-forget** model:
1. You run `./init.sh` **EXACTLY ONCE** to initialize the repository and install security hooks.
2. You open your AI tool and describe what you want to build.
3. **The agents take over 100% of the workflow.** You do not edit task lists, fill template placeholders, or run `init.sh` again.

---

## Universal Setup (All Tools)

1. Clone or copy this template into your project root.
2. Run `./init.sh` (or `./init.sh [project_name]`) **once**.
3. Open your favorite AI tool and start chatting.
4. Tell your AI what you want to build. The **Leader** agent decomposes your request into `TASKS.md`, fills project architecture guidelines, and orchestrates the implementation.

---

## Claude Code

The template already includes `.claude/settings.json` and `CLAUDE.md`:

- `.claude/settings.json`: Configures execution permissions for test runners (`pytest`, `npm test`, `cargo test`, `git`). No recurring hooks needed.
- `CLAUDE.md`: Points Claude to `AGENTS.md` to act as the Leader agent.

To start working:
```bash
claude
# In chat: "I want to build a REST API for managing users..."
```

---

## Cursor

The template includes `.cursorrules` in the project root:
- Directs Cursor to `AGENTS.md`.
- Follows the single-agent sequential protocol: Leader (plan) → Implementer (code + test) → Reviewer (audit) → Security Reviewer (scan) → Git Commit.

Open the folder in Cursor and start coding in Cursor Chat (Composer / Cmd+I).

---

## GitHub Copilot

The template includes `.github/copilot-instructions.md`:
- Directs Copilot to `AGENTS.md`, `CHECKPOINTS.md`, and `docs/`.
- Tells Copilot to verify changes with the project test suite and commit cleanly.

---

## Windsurf

The template includes `.windsurfrules` in the project root:
- Instructs Windsurf to read `AGENTS.md`.
- Works through `TASKS.md` one feature at a time.

---

## Antigravity (AGY)

`AGENTS.md` is auto-loaded as a user rule if placed in the project root. No configuration required.

Antigravity natively launches subagents for Implementer, Reviewer, and Security Reviewer via `invoke_subagent`.

---

## Aider

Add to `.aider.conf.yml`:

```yaml
read: ["AGENTS.md", "docs/conventions.md", "docs/architecture.md"]
```

Or pass at startup: `aider --read AGENTS.md`

---

## Summary of Responsibilities

| Role | Who Does It | When |
|---|---|---|
| Run `./init.sh` | **Human** | **Only once**, at repository bootstrap |
| Describe what to build | **Human** | In chat when starting new features |
| Decompose into tasks | **Leader Agent** | Autonomously in `TASKS.md` |
| Fill architecture & convention docs | **Leader Agent** | Autonomously during first session |
| Write code & unit/integration tests | **Implementer Agent** | Exactly 1 task per session |
| Audit quality & edge cases | **Reviewer Agent** | Runs tests independently |
| Scan for secrets, PII & exfiltration | **Security Reviewer Agent** | Pre-commit security gate |
| Git commit completed features | **Implementer / Leader** | After test suite passes |
| Run test suite (`npm test`, `pytest`) | **Agents** | Continuous during development |
