# Architecture Standards

## Principles
- Separate concerns: data layer, domain/business logic, presentation/interface.
- Keep business logic strictly out of the presentation layer.
- Use typed interfaces: use type hints (Python), TypeScript types, or equivalent.
- Handle errors explicitly: define and use domain-specific exceptions, never use bare except/catch.
- Favor immutable data.
- Ensure atomic writes for persistence (use a temporary file and rename).
- Add no external dependencies unless explicitly approved in TASKS.md.

## Prohibited Patterns
- No print()/console.log() for error reporting. Use proper logging or stderr.
- No I/O inside domain/business logic.
- No file reads/writes inside loops without batching.
- No global mutable state.
- No hardcoded paths, URLs, or credentials.
- No suppressing exceptions silently (do not use empty catch blocks).

## Project-Specific Architecture
{{DESCRIBE YOUR ARCHITECTURE HERE: layers, modules, data flow}}

Update this section when the project's architecture crystallizes.
