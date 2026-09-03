# AGENTS.md — Universal Agent Navigation Map

> This file is the primary entry point for any AI agent working in this repository.
> It is a **map**, not an exhaustive manual. Read only what you need, when you need it.

---

## 1. Core Workflow

1. **User Prompt**: The user tells the AI in chat what they want to build.
2. **Leader Planning**: The **Leader** agent interprets the request, defines or updates tasks in `TASKS.md`, and sets the active task in `progress/current.md`.
3. **Execution**: The Leader delegates to:
   - **Implementer**: Builds exactly 1 task, writes production code and tests.
   - **Reviewer**: Audits code quality, checks test coverage, and verifies against `CHECKPOINTS.md`.
   - **Security Reviewer**: Scans for hardcoded secrets, PII leaks, exfiltration risks, and git safety.
4. **Task Completion**: Only after both Reviewer (`APPROVED`) and Security Reviewer (`SECURE`) pass, the Leader marks the task as `[x]` in `TASKS.md` and appends a summary to `progress/history.md`.

---

## 2. Repository Map

| File / Directory               | Contains                                                  | When to Read           |
|--------------------------------|-----------------------------------------------------------|------------------------|
| `TASKS.md`                     | Task backlog (`[ ]` pending, `[/]` active, `[x]` done)    | Always, at startup     |
| `progress/current.md`          | Active task scratchpad and live logs                      | Always, at startup     |
| `progress/history.md`          | Append-only log of completed tasks                        | For historical context |
| `docs/architecture.md`         | System design standards and prohibited patterns           | Before implementing    |
| `docs/conventions.md`          | Code style, typing, and testing rules                     | Before writing code    |
| `docs/security.md`             | Security policy and vulnerability checklists              | Before security review |
| `docs/verification.md`         | Evidence-based verification standards                     | Before declaring done  |
| `CHECKPOINTS.md`               | Objective pass/fail criteria (C1–C6)                      | For self-evaluation    |
| `agents/`                      | Role prompts (`leader`, `implementer`, `reviewer`, etc.)  | When orchestrating     |

---

## 3. Hard Rules (Non-Negotiable)

- **The human does NOT manage tasks manually.** The Leader autonomously maintains `TASKS.md` based on user prompts.
- **One task at a time.** Exactly ONE task may be marked in progress (`[/]`) at any time.
- **No `done` without evidence.** The Implementer and Reviewer run tests via terminal tools. Every assertion of correctness must be backed by real test output.
- **Never hardcode secrets.** Any API key, token, or password committed to code is a blocker.
- **Leave the repo clean.** No temp files, no debug prints (`console.log`, `print()`), no orphaned TODOs.
- **Anti-telephone rule.** Subagents write full reports into `progress/*.md` files on disk and return ONLY a 1-line reference in chat (e.g., `done -> progress/impl_task.md`). Never paste diffs in chat.

---

## 4. Task Lifecycle Protocol

```
1. Leader reads user request & TASKS.md.
2. If tasks are needed, Leader adds them to TASKS.md.
3. Leader selects the highest-priority pending task ([ ]).
4. Marks it in progress: [/] in TASKS.md.
5. Logs task and brief plan in progress/current.md.
6. Delegates to Implementer -> Reviewer -> Security Reviewer.
7. Upon full approval, marks task completed: [x] in TASKS.md.
8. Moves summary from progress/current.md into progress/history.md.
```

---

## 5. If You Get Stuck

- Re-read the relevant section of `docs/`.
- If a tool fails unexpectedly, **do not invent workarounds**.
- Document the issue in `progress/current.md`, mark the task as blocked (`[-]` in `TASKS.md`), and ask the user for guidance.
