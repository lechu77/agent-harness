# Verification Protocol

## Principle
No claim without evidence. Every assertion of correctness must be backed by test output, not agent confidence.

## Verification Levels
- **Level 1 — Unit Tests**: Cover every public function. Test both success and failure paths. Assert specific values, not just 'no exception thrown.'
- **Level 2 — Integration Tests**: Test module interactions. Use real I/O with isolated temp directories. Test the actual CLI/API interface, not internal functions.
- **Level 3 — Smoke Tests**: Run the application end-to-end in a temp environment. Verify the user-facing behavior matches the feature spec.

## Anti-Patterns
- Testing that no exception was thrown, without checking the actual output.
- Mocking the filesystem when testing filesystem operations.
- Tests that pass regardless of input.
- Tests that only test the happy path.
- Asserting implementation details instead of behavior.

## Verification Checklist
- [ ] `./init.sh` exits 0.
- [ ] All new code paths have corresponding tests.
- [ ] Tests use real I/O where applicable (`tempfile.TemporaryDirectory`, `mkdtemp`, etc.).
- [ ] Error paths are tested with specific error assertions.
- [ ] Pre-existing tests still pass (no regressions).
- [ ] Test output is captured and included in the implementation report.

## Final Gate
Run `./init.sh`. If it's not green, the work is not done. No exceptions.
