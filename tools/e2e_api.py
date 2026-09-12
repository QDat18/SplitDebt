#!/usr/bin/env python3
"""End-to-end REST contract check for a locally running SplitDebt backend.

Run the backend with the e2e profile first:
  cd api
  ./mvnw spring-boot:run -Dspring-boot.run.profiles=e2e

Then:
  python tools/e2e_api.py

Only Python's standard library is used.
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request

BASE = os.environ.get("SPLITDEBT_E2E_URL", "http://127.0.0.1:18080/api").rstrip("/")


def request(method: str, path: str, body=None, token: str | None = None, expected=(200,)):
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            status = response.status
            raw = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        status = exc.code
        raw = exc.read().decode("utf-8")
    if status not in expected:
        raise AssertionError(f"{method} {path}: expected {expected}, got {status}: {raw}")
    if not raw.strip():
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise AssertionError(f"{method} {path}: invalid JSON: {raw[:300]}") from exc


def check(condition: bool, message: str):
    if not condition:
        raise AssertionError(message)


def register(name: str, email: str):
    return request("POST", "/auth/register", {
        "fullName": name,
        "email": email,
        "password": "password123",
        "acceptedTerms": True,
    })


def login(email: str):
    return request("POST", "/auth/login", {
        "email": email,
        "password": "password123",
    })


def main() -> int:
    print(f"[E2E] SplitDebt API: {BASE}")
    with urllib.request.urlopen(BASE + "/health", timeout=8) as response:
        health = response.read().decode("utf-8")
    check("SplitDebt API is running" in health, "health endpoint returned unexpected content")

    stamp = f"{int(time.time())}-{os.getpid()}"
    owner_email = f"owner.{stamp}@example.com"
    member_email = f"member.{stamp}@example.com"
    outsider_email = f"outsider.{stamp}@example.com"
    register("E2E Owner", owner_email)
    register("E2E Member", member_email)
    register("E2E Outsider", outsider_email)

    # Duplicate registration and invalid credentials are deliberate negative-path checks.
    request("POST", "/auth/register", {
        "fullName": "Duplicate",
        "email": owner_email,
        "password": "password123",
        "acceptedTerms": True,
    }, expected=(409,))
    request("POST", "/auth/login", {"email": owner_email, "password": "wrong-password"}, expected=(401,))
    request("GET", "/groups", expected=(401,))

    owner_login = login(owner_email)
    member_login = login(member_email)
    outsider_login = login(outsider_email)
    owner_token = owner_login["token"]
    member_token = member_login["token"]
    outsider_token = outsider_login["token"]
    owner_id = owner_login["user"]["id"]
    member_id = member_login["user"]["id"]

    group = request("POST", "/groups", {
        "name": "E2E Trip",
        "description": "Automated end-to-end API test",
        "currency": "VND",
    }, owner_token)
    group_id = group["id"]
    code = group["inviteCode"]
    check(group["ownerId"] == owner_id, "group owner mismatch")

    request("POST", "/groups/join", {"inviteCode": code.lower()}, member_token)
    request("GET", f"/groups/{group_id}", token=outsider_token, expected=(404,))

    detail = request("GET", f"/groups/{group_id}", token=owner_token)
    check(len(detail["members"]) == 2, "group should contain owner and joined member")

    expense = request("POST", f"/groups/{group_id}/expenses", {
        "title": "E2E Dinner",
        "description": "Dinner shared equally",
        "totalAmount": 10000,
        "payerId": owner_id,
        "expenseDate": time.strftime("%Y-%m-%d"),
        "splitType": "EQUAL",
        "participants": [{"userId": owner_id}, {"userId": member_id}],
        "items": [],
    }, owner_token)
    check(sum(s["amount"] for s in expense["shares"]) == 10000, "expense shares do not conserve total")

    # Invalid amount split must not be persisted.
    request("POST", f"/groups/{group_id}/expenses", {
        "title": "Invalid split",
        "totalAmount": 10000,
        "payerId": owner_id,
        "expenseDate": time.strftime("%Y-%m-%d"),
        "splitType": "AMOUNT",
        "participants": [
            {"userId": owner_id, "amount": 4000},
            {"userId": member_id, "amount": 4000},
        ],
        "items": [],
    }, owner_token, expected=(400,))

    before = request("GET", f"/groups/{group_id}", token=member_token)
    check(int(before["balances"][str(member_id)]) == -5000, "member balance should be -5000")
    check(int(before["balances"][str(owner_id)]) == 5000, "owner balance should be +5000")
    check(len(before["suggestions"]) == 1, "smart settlement should suggest one payment")

    paid = request("POST", f"/groups/{group_id}/settlements", {
        "creditorId": owner_id,
        "amount": 5000,
        "paymentMethod": "BANK_TRANSFER",
    }, member_token)
    check(paid["status"] == "PAID", "settlement should wait for recipient confirmation")
    settlement_id = paid["id"]

    pending = request("GET", f"/groups/{group_id}", token=member_token)
    check(len(pending["suggestions"]) == 0, "pending settlement should not be suggested twice")
    request("POST", f"/settlements/{settlement_id}/confirm", token=member_token, expected=(400,))
    confirmed = request("POST", f"/settlements/{settlement_id}/confirm", token=owner_token)
    check(confirmed["status"] == "CONFIRMED", "recipient confirmation failed")

    after = request("GET", f"/groups/{group_id}", token=owner_token)
    check(all(int(v) == 0 for v in after["balances"].values()), "balances should be zero after confirmation")

    stats = request("GET", f"/groups/{group_id}/statistics?range=DAY", token=owner_token)
    check(stats["totalExpense"] == 10000, "statistics total mismatch")
    check(stats["mySpent"] == 10000, "statistics mySpent mismatch")
    request("GET", f"/groups/{group_id}/statistics?range=MONTH", token=owner_token)
    request("GET", f"/groups/{group_id}/statistics?range=YEAR", token=owner_token)
    request("GET", f"/groups/{group_id}/statistics?range=ALL", token=owner_token, expected=(400,))

    member_notifications = request("GET", "/notifications?limit=100", token=member_token)
    check(any(n["type"] == "NEW_EXPENSE" for n in member_notifications), "member did not receive expense notification")
    check(any(n["type"] == "SETTLEMENT_CONFIRMED" for n in member_notifications), "debtor did not receive confirmation notification")

    activity = request("GET", "/activity?limit=10&offset=0", token=owner_token)
    check(len(activity["items"]) >= 2, "activity should contain expense and settlement")

    request("PATCH", "/me/settings", {
        "theme": "DARK",
        "notifyOnDebtReminder": False,
    }, owner_token)
    settings = request("GET", "/me/settings", token=owner_token)
    check(settings["theme"] == "DARK", "user settings update failed")

    print("PASS: auth, JWT, group join, access control, expense split, debt, Smart Settlement, two-sided payment, notifications, statistics, settings and activity.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise
