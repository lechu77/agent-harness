# Checkpoints — Pass/Fail Criteria

> Objective evaluation gates. Every checkpoint is binary: PASS or FAIL.

## C1: Harness Integrity
- [ ] `AGENTS.md`, `TASKS.md`, `CHECKPOINTS.md`, `docs/`, `agents/`, `progress/` exist and are non-empty

## C2: State Coherence
- [ ] At most 1 task in progress (`[/]`) in `TASKS.md`
- [ ] Every completed task (`[x]`) has passing tests and an entry in `progress/history.md`

## C3: Architecture & Naming Compliance
- [ ] Code adheres to accepted ADRs in `docs/adr/`
- [ ] Entity names and states match `docs/context.md` exactly (no forbidden synonyms)
- [ ] No debug statements (`console.log`, `print`, `debugger`), orphaned TODOs, or commented code

## C4: Test Verification
- [ ] Every code module has a corresponding test file
- [ ] Tests use real I/O (temp directories, not filesystem mocks)
- [ ] All tests pass; both happy-path and error-path coverage exists

## C5: Security Compliance
- [ ] No hardcoded secrets, tokens, or API keys in any file
- [ ] `.gitignore` covers `*.env`, `.env.*`, `*.pem`, `*.key`, `*.db`, `*.sqlite*`, caches
- [ ] No unauthorized external HTTP calls (domain whitelist enforced)
- [ ] No `eval()`, `exec()`, SQL string concatenation, or dynamic code execution with external input

## C6: Clean Closure
- [ ] Test suite exits 0 with all tests passing
- [ ] `progress/history.md` has an entry for the completed session
- [ ] Task status in `TASKS.md` is accurate
- [ ] `progress/current.md` is reset (if session complete)
- [ ] Chat output adheres to Zero-Fluff: action-first, visible win, no pleasantries
