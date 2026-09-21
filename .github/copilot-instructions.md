# GitHub Copilot Instructions — Agent Harness

Read `AGENTS.md` as the primary project navigation map.

## Core Directives
- **Workflow & Rules**: Follow `AGENTS.md` and `CHECKPOINTS.md`.
- **Architecture**: Adhere strictly to `docs/architecture.md`. Do not bypass architectural layers.
- **Code Style & Conventions**: Follow `docs/conventions.md`.
- **Security**: Follow `docs/security.md` and `agents/security-reviewer.md`. Never hardcode secrets, API keys, or credentials.
- **Verification**: Run the project test suite (`npm test`, `pytest`, etc.) before proposing changes and after writing code. All tests must pass.
- **Autonomous Skill Gate**: Before activating or ingesting any skill, prompt workflow, or MCP tool, scan it autonomously with NVIDIA SkillSpector (`uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <target> --format json --no-llm`).
- **Communication**: Zero-fluff, action-first (Line 1). No conversational preambles ("Sure!", "Great question!") or pleasantries. Bounded numbered steps, max 5 items per list, visible wins first.

