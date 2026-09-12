#!/usr/bin/env python3
"""Local response-time smoke test for SplitDebt's authenticated overview endpoint.

The SRS proposes that primary screens should load in about 3 seconds on a stable
network. This script is intentionally a smoke test, not a production load test.
It creates one temporary user, authenticates, then measures repeated GET /overview
requests against an already-running E2E backend.

Examples:
  SPLITDEBT_E2E_URL=http://127.0.0.1:18080/api python tools/performance_smoke.py
  python tools/performance_smoke.py --requests 50 --concurrency 5 --max-p95-ms 3000
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import statistics
import time
import urllib.error
import urllib.request

BASE = os.environ.get("SPLITDEBT_E2E_URL", "http://127.0.0.1:18080/api").rstrip("/")


def call(method: str, path: str, body=None, token: str | None = None, timeout: float = 8.0):
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            raw = response.read().decode("utf-8")
            status = response.status
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8")
        status = exc.code
    if status < 200 or status >= 300:
        raise RuntimeError(f"{method} {path} -> HTTP {status}: {raw[:240]}")
    return json.loads(raw) if raw.strip().startswith(("{", "[")) else raw


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    if not ordered:
        return 0.0
    index = max(0, min(len(ordered) - 1, int((len(ordered) - 1) * fraction + 0.999999)))
    return ordered[index]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--requests", type=int, default=30)
    parser.add_argument("--concurrency", type=int, default=5)
    parser.add_argument("--max-p95-ms", type=float, default=3000.0)
    args = parser.parse_args()
    if args.requests < 1 or args.concurrency < 1:
        parser.error("--requests and --concurrency must be positive")

    stamp = f"{time.time_ns()}-{os.getpid()}"
    email = f"perf.{stamp}@example.com"
    password = "password123"
    call("POST", "/auth/register", {
        "fullName": "Performance Smoke User",
        "email": email,
        "password": password,
        "acceptedTerms": True,
    })
    login = call("POST", "/auth/login", {"email": email, "password": password})
    token = login["token"]

    # Warm up class loading/JDBC paths before measuring.
    call("GET", "/overview", token=token)

    def measured_request(_: int) -> float:
        started = time.perf_counter()
        payload = call("GET", "/overview", token=token)
        if "groups" not in payload or "balances" not in payload:
            raise RuntimeError("/overview returned an unexpected response shape")
        return (time.perf_counter() - started) * 1000.0

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.concurrency) as pool:
        durations = list(pool.map(measured_request, range(args.requests)))

    p50 = statistics.median(durations)
    p95 = percentile(durations, 0.95)
    maximum = max(durations)
    print(
        f"Performance smoke: requests={args.requests}, concurrency={args.concurrency}, "
        f"p50={p50:.1f} ms, p95={p95:.1f} ms, max={maximum:.1f} ms"
    )
    if p95 > args.max_p95_ms:
        raise AssertionError(
            f"p95 {p95:.1f} ms exceeds the configured smoke threshold {args.max_p95_ms:.1f} ms"
        )
    print(f"PASS: p95 <= {args.max_p95_ms:.0f} ms on this local test environment.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
