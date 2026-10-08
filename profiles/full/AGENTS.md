# AGENTS.md — Full Profile

> Profile: **Full** (~2,478 tokens context footprint). Complete multi-agent pipeline with Leader, Implementer, Reviewer, Security Reviewer, ADRs, and exhaustive checkpoints.
> Recommended for large multi-module architectures requiring formal review gates.

→ This profile activates the full `agents/` pipeline. See root `AGENTS.md` for the navigation map and role definitions.

## Active Pipeline

Leader → Implementer → Reviewer → Security Reviewer

All agents operate per their role prompts in `agents/`:
- `agents/leader.md` — Orchestration, ADRs, task decomposition
- `agents/implementer.md` — Production code + tests
- `agents/reviewer.md` — Adversarial code quality audit
- `agents/security-reviewer.md` — Secrets, egress, supply chain

All hard rules, Zero-Fluff communication protocol, and lifecycle protocol are defined in root `AGENTS.md`.
