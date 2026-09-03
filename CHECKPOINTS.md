# CHECKPOINTS.md — Objective Pass/Fail Criteria

> These checkpoints evaluate the **destination**, not the path.
> Every checkpoint is binary: PASS or FAIL. No partial credit.

---

## C1: Harness Integrity

- [ ] `AGENTS.md` exists and is non-empty
- [ ] `SETUP.md` exists and is non-empty
- [ ] `CHECKPOINTS.md` exists and is non-empty
- [ ] `TASKS.md` exists and is non-empty
- [ ] `progress/current.md` exists
- [ ] `progress/history.md` exists
- [ ] `docs/architecture.md` exists
- [ ] `docs/conventions.md` exists
- [ ] `docs/verification.md` exists
- [ ] `docs/security.md` exists
- [ ] `agents/leader.md` exists
- [ ] `agents/implementer.md` exists
- [ ] `agents/reviewer.md` exists
- [ ] `agents/security-reviewer.md` exists

## C2: State Coherence

- [ ] At most 1 task marked in progress (`[/]`) in `TASKS.md`
- [ ] Every task marked done (`[x]`) has passing tests
- [ ] `progress/current.md` contains only the active session OR the empty template
- [ ] No task marked done (`[x]`) without an entry in `progress/history.md`

## C3: Architecture Compliance

- [ ] Code directories contain only files planned in `docs/architecture.md`
- [ ] No unauthorized external dependencies
- [ ] No dangling debug statements (`print()`, `console.log()`, `debugger`)
- [ ] No TODOs without actionable context
- [ ] No commented-out code blocks

## C4: Test Verification

- [ ] Every code module has a corresponding test file
- [ ] Tests use real I/O with temp directories (no filesystem mocking)
- [ ] Test runner discovers and runs > 0 tests
- [ ] All tests pass
- [ ] Both happy-path and error-path tests exist for each public function

## C5: Security Compliance

- [ ] No hardcoded secrets, tokens, API keys, or passwords in any file
- [ ] `.gitignore` covers: `*.env`, `.env.*`, `*.pem`, `*.key`, `*.db`, `*.sqlite*`, `node_modules/`, `__pycache__/`, `.DS_Store`
- [ ] No PII in test fixtures or seed data
- [ ] All external HTTP calls are intentional and documented
- [ ] No `eval()`, `exec()`, or dynamic code execution with external input
- [ ] No SQL string concatenation (parameterized queries only)

## C6: Clean Session Closure

- [ ] No untracked temporary files or caches
- [ ] `progress/history.md` has an entry for the latest completed session
- [ ] Task status in `TASKS.md` is accurate
- [ ] `progress/current.md` is reset to the empty template (if session complete)
- [ ] Test suite and linters exit 0 with all passing tests
