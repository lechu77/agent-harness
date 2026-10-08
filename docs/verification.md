# Verification Protocol

## Principle
No claim without evidence. Every assertion of correctness must be backed by test output.

## Verification Levels
- **Unit Tests**: Every public function. Both success and failure paths. Assert specific values.
- **Integration Tests**: Module interactions. Real I/O with temp directories. Test CLI/API interface.
- **Smoke Tests**: End-to-end in temp environment. Verify user-facing behavior.
- **Offline Execution**: Tests run without external internet. No live network calls.

## Anti-Patterns
- Testing that no exception was thrown without checking output.
- Mocking the filesystem when testing filesystem operations.
- Tests that pass regardless of input.
- Happy-path-only tests.
- Asserting implementation details instead of behavior.

## Final Gate
Run the test suite. If tests are not green, the work is not done. See `CHECKPOINTS.md §C4` for verification criteria.
