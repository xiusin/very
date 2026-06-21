# Extend Validator Type Support Spec

## Why
The `very` V-language web framework's validator module (`/workspace/validator/`) was extended to support additional primitive types (int, i64, u64, f64, bool) across `Required`, `Min`, `Max`, and `Number` validators. The bulk of the implementation is complete, but the test suite is not yet green: `test_validate` fails because the test URL `'go1ogle.123'` is actually parseable by `net.urllib.parse`, and debug `eprintln` statements remain in `validate_test.v`. This spec finalizes Task 7 so the verification commands (`v fmt`, `v build-module`, `v test`) all pass cleanly.

## What Changes
- Fix `test_validate` in `/workspace/validator/validate_test.v` so the expected error count matches actual behavior. The URL `'go1ogle.123'` parses successfully, so either:
  - change the test URL to a value that `net.urllib.parse` rejects (e.g. a string with illegal control characters or an empty string), OR
  - change the expected error count from `4` to `3` and update the explanatory comment.
- Remove debug `eprintln` statements from `test_validate` and `test_required_int` functions in `/workspace/validator/validate_test.v`.
- Run the verification commands to confirm everything passes:
  - `cd /workspace && v fmt -w validator/`
  - `cd /workspace && v build-module validator/`
  - `cd /workspace && v test validator/`

## Impact
- Affected specs: none (no prior spec existed for this work).
- Affected code:
  - `/workspace/validator/validate_test.v` (test-only changes: remove debug output, fix expected count or test data).
- No changes to `required.v`, `min.v`, `max.v`, `number.v`, `validate.v`, `regexp.v`, or `url.v` are required by this spec — those files already contain the completed Task 7 implementation and must not be regressed.

## ADDED Requirements
### Requirement: Clean test suite for validator module
The validator module's test file SHALL NOT contain debug `eprintln` statements in test functions.

#### Scenario: Running tests produces no debug output
- **WHEN** `v test validator/` is executed
- **THEN** no `eprintln` output from `test_validate` or `test_required_int` appears in the test stream

### Requirement: test_validate assertion matches actual validator behavior
The `test_validate` test SHALL assert an error count that reflects the real behavior of the `url` validator against the test data.

#### Scenario: URL test data is genuinely invalid
- **WHEN** the test URL is set to a value that `net.urllib.parse` rejects
- **THEN** the test asserts `errs.len == 4` (username regexp, age max, number, url)

#### Scenario: URL test data is actually valid (alternative)
- **WHEN** the test URL remains `'go1ogle.123'` (which parses successfully)
- **THEN** the test asserts `errs.len == 3` (username regexp, age max, number) and the comment is corrected

## MODIFIED Requirements
### Requirement: Validator test suite
The test suite in `/workspace/validator/validate_test.v` SHALL pass when run with `v test validator/`, with no failing assertions and no leftover debug output. The existing test structs (`Test`, `TestRequired`, `TestNumber`, `TestMinMax`, `TestUnknown`) and their associated test functions SHALL remain intact.

## REMOVED Requirements
None. No functionality is being removed.
