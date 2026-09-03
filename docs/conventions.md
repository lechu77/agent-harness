# Code Conventions

## Why Conventions Matter for AI Agents

Consistent patterns reduce LLM prediction errors. Deviations from established patterns cause cascading style drift across generated code. These rules exist to keep AI-generated code predictable and maintainable.

## Universal Rules (all languages)

- One module = one responsibility.
- Max file length: 300 lines. Split if exceeded.
- Max function length: 50 lines. Extract if exceeded.
- Every public function/method has a docstring or JSDoc.
- Import order: stdlib/builtins first, then third-party, then local. Separated by blank lines.
- No wildcard imports (`from x import *`, `import * from`).
- No magic numbers — use named constants.
- No nested ternaries.
- No single-letter variable names except loop counters (`i`, `j`, `k`).

## Python Conventions

- Follow PEP 8. Max 100 characters per line.
- Add `from __future__ import annotations` at the top of every module.
- Use double quotes for strings.
- Use f-strings only. No `.format()`, no `%` formatting.
- Naming: `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants.
- Type hints on all function signatures.
- Use `pathlib.Path` over `os.path` for file operations.
- Use `dataclasses` or `pydantic` for structured data. No raw dicts for domain objects.

## JavaScript/TypeScript Conventions

- Prefer TypeScript over JavaScript.
- Enable strict mode always (`"strict": true` in tsconfig).
- Naming: `camelCase` for functions/variables, `PascalCase` for classes/components/types, `UPPER_SNAKE_CASE` for constants.
- Prefer `const` over `let`. Never use `var`.
- Prefer arrow functions for callbacks.
- Use `async/await` over `.then()` chains.
- Use template literals over string concatenation.
- Prefer `===` over `==`.

## Test Conventions

- Test file naming: `test_<module>.py` or `<module>.test.ts`.
- Use real temp directories for filesystem tests — no mocking the filesystem.
- Each test tests one behavior.
- Test names describe the behavior: `test_<action>_<condition>_<expected_result>`.
- Both happy-path and error-path tests required for every public function.
- Test data uses realistic but fake values. No production data.
- Clean up after tests. Use `setUp`/`tearDown` or `beforeEach`/`afterEach`.

## Error Handling

- Use domain-specific exception classes. No bare `Exception` or `Error`.
- CLI/API layer catches domain exceptions, writes to stderr, and exits with code 1.
- Never suppress exceptions silently (empty catch/except blocks).
- Log errors with context: what failed, what the input was, what was expected.

## Project-Specific Conventions

{{ADD PROJECT-SPECIFIC CONVENTIONS HERE}}
