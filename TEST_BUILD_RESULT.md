# SplitDebt - Test build integration result

This project was built from the uploaded `SplitDebt-test.zip` and merged with the full testing package.

## Test coverage added

- Backend: 53 JUnit test cases across 13 Java test files.
- Flutter: 28 unit/widget/integration test calls across 7 Dart files.
- LedgerMath randomized invariant verification: 10,000 settlement cases.
- REST API end-to-end script.
- Performance smoke test for `/overview` with configurable p95 threshold.
- JaCoCo backend coverage and Flutter LCOV coverage.
- GitHub Actions verification workflow.
- One-command runners: `test-all.ps1` (Windows) and `test-all.sh` (Linux/macOS).

## Checks completed in the packaging environment

PASS:
- LedgerMath compile + invariant checks.
- 10,000 randomized settlement checks.
- Activity SQL lightweight fixture check.
- Python test helper scripts compile.
- `pom.xml` parses as XML.
- Test/application/workflow YAML files parse successfully.

Not executable in the packaging environment:
- Full Maven `clean verify`: Maven wrapper distribution cannot be downloaded from the sandbox network.
- Flutter analyze/test/build: Flutter SDK is not installed in the sandbox.

## Run on Windows

Full suite:

```powershell
.\test-all.ps1
```

Fast suite:

```powershell
.\test-all.ps1 -Fast
```

Skip Android APK build:

```powershell
.\test-all.ps1 -SkipAndroid
```

Skip E2E:

```powershell
.\test-all.ps1 -SkipE2E
```
