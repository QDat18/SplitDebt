# Backend statistics test fix - 2026-09-12

The statistics API now intentionally supports only `DAY`, `MONTH`, and `YEAR`.
Legacy tests still expected `ALL` and `WEEK`, which caused the Maven test suite to fail even though the runtime API matched the new product requirement.

Updated tests:
- `RestApiEndToEndTests`: uses `DAY` instead of `ALL`.
- `SettingsNotificationStatisticsTests`: validates `DAY`, `MONTH`, `YEAR`, validates `mySpent`, and expects `ALL`/`WEEK` to return `400 BAD_REQUEST`.

No production statistics behavior was reverted.
