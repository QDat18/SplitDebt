#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
API="$ROOT/api"
FRONTEND="$ROOT/frontend"
RESULTS="$ROOT/test-results"
mkdir -p "$RESULTS"

section(){ printf '\n============================================================\n %s\n============================================================\n' "$1"; }
command -v java >/dev/null
command -v javac >/dev/null
command -v flutter >/dev/null
command -v python3 >/dev/null
command -v curl >/dev/null

section "LedgerMath invariant checks"
rm -rf "$RESULTS/ledger-math-classes" && mkdir -p "$RESULTS/ledger-math-classes"
javac -d "$RESULTS/ledger-math-classes" \
  "$API/src/main/java/com/splitdebt/api/ledger/LedgerMath.java" \
  "$API/tools/LedgerMathCheck.java"
java -cp "$RESULTS/ledger-math-classes" com.splitdebt.api.ledger.LedgerMathCheck

section "Backend tests + JaCoCo"
(cd "$API" && bash ./mvnw --batch-mode clean verify)

section "Flutter analyze + tests"
(cd "$FRONTEND" && flutter pub get && flutter analyze --no-fatal-infos && flutter test --coverage)

section "Flutter build smoke tests"
(cd "$FRONTEND" && flutter build web --debug && flutter build apk --debug)

section "REST API E2E"
rm -f "$API"/data/splitdebt-e2e* || true
mkdir -p "$API/data"
(
  cd "$API"
  SPRING_PROFILES_ACTIVE=e2e bash ./mvnw spring-boot:run >"$RESULTS/backend-e2e.out.log" 2>"$RESULTS/backend-e2e.err.log"
) &
PID=$!
trap 'kill "$PID" 2>/dev/null || true' EXIT
for _ in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:18080/api/health >/dev/null 2>&1; then break; fi
  if ! kill -0 "$PID" 2>/dev/null; then echo "Backend E2E exited"; exit 1; fi
  sleep 1
done
curl -fsS http://127.0.0.1:18080/api/health >/dev/null
SPLITDEBT_E2E_URL=http://127.0.0.1:18080/api python3 "$ROOT/tools/e2e_api.py"

section "Performance smoke"
SPLITDEBT_E2E_URL=http://127.0.0.1:18080/api python3 "$ROOT/tools/performance_smoke.py" --requests 30 --concurrency 5 --max-p95-ms 3000

section "Coverage summary"
python3 "$ROOT/tools/coverage_summary.py"

echo "PASS: full SplitDebt test suite completed."
