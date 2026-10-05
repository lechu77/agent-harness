# AGENTS.md — Agent Harness (Lite Profile)

> Profile: **Lite** (~400 tokens context footprint). Optimized for forks, scripts, and rapid MVPs.
> Fast-track single agent execution with zero token waste and local pre-commit security gates.

---

## 1. Core Workflow

1. **User Prompt**: The human describes the feature, bugfix, or change in chat.
2. **Build & Verify**:
   - Make the minimal required changes to code and write/update automated tests.
   - Run the project test suite via terminal (`npm test`, `pytest`, `cargo test`, `python3 -m unittest`, etc.).
   - All tests must pass 100% green with real execution evidence.
3. **Commit**:
   - Stage changes: `git add -A`.
   - Commit with a descriptive message (`feat:`, `fix:`, `refactor:`).
   - If git pre-commit hook blocks with a detected secret, remediate immediately.
4. **Report**: Report completion with Line 1 action/command to verify the win.

---

## 2. Hard Rules (Non-Negotiable)

- **No done without evidence.** Always execute the test suite or verify behavior via terminal before reporting completion.
- **Never hardcode secrets.** Any API key, token, or password committed to code is a blocker.
- **Path neutrality.** Never write or commit absolute system paths (`/Users/...`, `/home/...`). All paths must be relative to project root.
- **Leave repo clean.** No debug prints (`console.log`, `print()`), no temporary scratch files, no broken tests.
- **Zero-fluff communication.** Line 1 is always the direct action, command, or answer. No pleasantries ("Sure!", "Great question!").
