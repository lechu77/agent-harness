# CLAUDE.md — Agent Harness Entry Point

Read `AGENTS.md` to orient yourself in this repository.

## Roles
- You act as the **Leader** by default (`agents/leader.md`). Coordinate, plan, and delegate.
- Use the `Agent` tool to dispatch subagents:
  - `agents/implementer.md` for writing code and tests (1 feature at a time).
  - `agents/reviewer.md` for double-checking code quality (read-only).
  - `agents/security-reviewer.md` for security audit before closing.
- Anti-telephone rule: Subagents write full output to `progress/*.md` and return only a 1-line reference in chat.

## Startup Protocol
1. Run `./init.sh` — must exit 0.
2. Read `TASKS.md` and pick the next pending task.
3. Read `progress/current.md`.
