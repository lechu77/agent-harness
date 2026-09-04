# Setup Guide — Configure Your AI Coding Tool

This harness works with any AI coding tool that can read files. Below are tool-specific setup instructions.

---

## Universal Setup (all tools)

1. Copy this template into your project root.
2. Run `chmod +x init.sh && ./init.sh` — must exit 0.
3. Edit `TASKS.md` with your features.
4. Search for `{{` in `docs/*.md` and fill in project-specific values.
5. Point your AI tool to `AGENTS.md` as the system instructions entry point.

---

## Claude Code

Create `.claude/settings.json` in your project root:

```json
{
  "permissions": {
    "allow": [
      "Bash(./init.sh)",
      "Bash(python3 -m unittest*)",
      "Bash(npm test*)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{"type": "command", "command": "./init.sh 2>&1 | tail -5"}]
      }
    ],
    "Stop": [
      {"hooks": [{"type": "command", "command": "./init.sh"}]}
    ]
  }
}
```

Create `CLAUDE.md` in your project root:

```markdown
Read AGENTS.md. You are the Leader. Read agents/leader.md for your full role.
Run ./init.sh before starting. Use the Agent tool to delegate to implementer, reviewer, and security-reviewer.
Tell every subagent: "Write your output to progress/*.md. Return only the file path."
```

Use subagents via Claude Code's `Agent` tool with the role files in `agents/`.

---

## Cursor

Create `.cursorrules` in your project root:

```
Read AGENTS.md for full instructions. You are the Leader agent.
Read agents/leader.md for your role definition.
Run ./init.sh before starting work.
One feature at a time. Read TASKS.md for the task backlog.
Before writing code, read docs/architecture.md and docs/conventions.md.
After implementation, review against CHECKPOINTS.md criteria C1-C6.
Run security checks from agents/security-reviewer.md before marking done.
```

---

## GitHub Copilot

Create `.github/copilot-instructions.md` in your project:

```markdown
Read AGENTS.md for the project workflow.
Follow docs/conventions.md for all code style decisions.
Follow docs/architecture.md for structural decisions.
Run ./init.sh to verify the project state before and after changes.
Check docs/security.md before committing — no hardcoded secrets.
```

---

## Windsurf

Create `.windsurfrules` in your project root:

```
Read AGENTS.md for full project instructions and agent workflow.
You are the Leader. Read agents/leader.md for your role.
Run ./init.sh before starting. Follow TASKS.md for task selection.
Delegate implementation to the implementer role (agents/implementer.md).
Review work using the reviewer checklist (agents/reviewer.md).
Run security review using agents/security-reviewer.md before closing.
```

---

## Antigravity (AGY)

`AGENTS.md` is auto-loaded as a user rule if placed in the project root. No additional config needed.

For subagent delegation, Antigravity's `invoke_subagent` tool works natively. Instruct each subagent to read its role file from `agents/`.

---

## Aider

Add to `.aider.conf.yml`:

```yaml
read: ["AGENTS.md", "docs/conventions.md", "docs/architecture.md"]
```

Or pass at startup: `aider --read AGENTS.md`

---

## OpenCode / Other Tools

Any tool that can read markdown files works. Point it to `AGENTS.md` as the entry point. The key files are:

| What the tool needs | File to read |
|---------------------|-------------|
| Project workflow | `AGENTS.md` |
| Architecture rules | `docs/architecture.md` |
| Code style | `docs/conventions.md` |
| Verification | `docs/verification.md` |
| Security policy | `docs/security.md` |
| Task backlog | `TASKS.md` |
| Quality criteria | `CHECKPOINTS.md` |

---

## Automated Hooks (Optional)

If your tool supports hooks or pre/post commands, configure verification at session boundaries:

| Event | Command | Purpose |
|-------|---------|--------|
| Before session start | `git log --oneline -5` | Review recent progress |
| Before session end | Run test suite (`npm test`, `pytest`, etc.) | Verify clean state |
| Before git commit | Pre-commit hook (auto-installed by `init.sh`) | Block secrets |

> **Note:** `init.sh` is a one-time setup script. Do NOT configure it as a recurring hook. After initial setup, use your project's test suite for ongoing verification.
