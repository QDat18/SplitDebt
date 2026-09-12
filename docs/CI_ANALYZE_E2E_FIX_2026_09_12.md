# CI Analyze + API E2E fix — 2026-09-12

## API E2E

The statistics contract is now DAY / MONTH / YEAR. `tools/e2e_api.py` was updated to:

- request DAY and validate `totalExpense` and `mySpent`;
- smoke-test MONTH and YEAR as valid ranges;
- keep ALL only as a negative test expecting HTTP 400.

## Flutter analyzer cleanup

The analyzer warnings reported by CI were cleaned up without weakening the workflow:

- removed unused local variables/imports;
- added braces around for/if bodies;
- guarded BuildContext usage across async gaps;
- migrated settlement payment options to `RadioGroup`;
- replaced deprecated Matrix4 `translate` / `scale` calls with typed methods;
- reordered child arguments where required by lint;
- removed an unnecessary test import.

CI continues to run `flutter analyze --no-fatal-infos`; warnings remain fatal, while informational lints are non-fatal.
