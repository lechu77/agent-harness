# AGENTS.md — Agent Harness (Balanced Profile)

> Profile: **Balanced** (~800 tokens context footprint). Optimized for standard projects from scratch.
> Low token overhead, fast delivery, self-review loop, and local zero-cost security gate.

---

## 1. Core Workflow

1. **Task Selection**: Read `TASKS.md`. If tasks do not exist, decompose user request into atomic tasks. Select highest-priority pending task and mark `[/]`.
2. **Implementation**:
   - Implement production code adhering to `docs/architecture.md` and `docs/conventions.md`.
   - Write unit/integration tests alongside the code.
   - Run tests frequently via terminal until all tests pass.
3. **Adversarial Self-Review**:
   - Review your own git diff (`git diff`).
   - Check edge cases: empty inputs, network errors, boundary conditions.
   - Remove all debug logs (`console.log`, `print`), temporary files, or commented code.
4. **Task Closure & Git Commit**:
   - Stage and commit: `git commit -m "feat(<task>): <description>"`.
   - Mark task completed (`[x]`) in `TASKS.md`.
   - Append 2-line summary to `progress/history.md` and reset `progress/current.md`.

---

## 2. Hard Rules (Non-Negotiable)

- **The human does NOT manage tasks manually.** The agent maintains `TASKS.md`.
- **One task at a time.** Exactly ONE task marked in progress (`[/]`) at any time.
- **No done without evidence.** Every assertion of correctness must be backed by passing terminal test output.
- **Never hardcode secrets.** API keys, tokens, or passwords are an immediate blocker (enforced by pre-commit hook).
- **Path neutrality.** All paths must be relative to the repository root. Never commit absolute paths.
- **Leave the repo clean.** All tests pass, no uncommitted files, no orphaned TODOs.
- **Zero-fluff communication.** Line 1 is always the action, path, or direct result. No conversational filler.
