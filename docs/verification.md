# Verification Protocol

## Principle
No claim without evidence. Every assertion of correctness must be backed by test output, not agent confidence.

## Verification Levels
- **Level 1 — Unit Tests**: Cover every public function. Test both success and failure paths. Assert specific values, not just 'no exception thrown.'
- **Level 2 — Integration Tests**: Test module interactions. Use real I/O with isolated temp directories. Test the actual CLI/API interface, not internal functions.
- **Level 3 — Smoke Tests**: Run the application end-to-end in a temp environment. Verify the user-facing behavior matches the feature spec.
- **Isolated / Offline Test Execution**: All tests must execute cleanly without requiring external internet connectivity. Tests that make live external network calls are prohibited (use local test servers or isolated fixtures).

## Anti-Patterns
- Testing that no exception was thrown, without checking the actual output.
- Mocking the filesystem when testing filesystem operations.
- Tests that pass regardless of input.
- Tests that only test the happy path.
- Asserting implementation details instead of behavior.

## Verification Checklist
- [ ] Test suite exits 0 with all tests passing.
- [ ] All new code paths have corresponding tests.
- [ ] Tests use real I/O where applicable (`tempfile.TemporaryDirectory`, `mkdtemp`, etc.).
- [ ] Error paths are tested with specific error assertions.
- [ ] Pre-existing tests still pass (no regressions).
- [ ] Test output is captured and included in the implementation report.

## Final Gate
Run the test suite. If tests are not green, the work is not done. No exceptions.
