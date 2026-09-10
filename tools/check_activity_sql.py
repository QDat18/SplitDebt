"""Exercise the activity SELECT against a minimal SQLite fixture.

This is intentionally a lightweight SQL-shape/access-control check that does not
pretend to replace the H2/PostgreSQL integration tests in Maven.
"""
from pathlib import Path
import re
import sqlite3

root = Path(__file__).resolve().parents[1]
source = (root / 'api/src/main/java/com/splitdebt/api/ledger/LedgerService.java').read_text(encoding='utf-8')
match = re.search(r'String\s+sql\s*=\s*"""(.*?)"""\s*;', source, re.S)
if not match:
    raise AssertionError('Could not locate LedgerService.activity SQL text block.')
query = match.group(1)

db = sqlite3.connect(':memory:')
db.executescript('''
CREATE TABLE users(id INTEGER PRIMARY KEY, full_name TEXT NOT NULL);
CREATE TABLE groups(id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE group_members(group_id INTEGER NOT NULL, user_id INTEGER NOT NULL, status TEXT NOT NULL);
CREATE TABLE group_settings(group_id INTEGER PRIMARY KEY, currency_code TEXT, decimal_scale INTEGER);
CREATE TABLE expenses(
    id INTEGER PRIMARY KEY, group_id INTEGER NOT NULL, payer_id INTEGER NOT NULL,
    title TEXT NOT NULL, total_amount NUMERIC NOT NULL, created_at TEXT NOT NULL
);
CREATE TABLE settlements(
    id INTEGER PRIMARY KEY, group_id INTEGER NOT NULL, debtor_id INTEGER NOT NULL,
    creditor_id INTEGER NOT NULL, amount NUMERIC NOT NULL, status TEXT NOT NULL,
    requested_at TEXT, paid_at TEXT
);
''')

db.executemany('INSERT INTO users(id,full_name) VALUES(?,?)', [(1, 'Alex'), (2, 'Sam'), (3, 'Outsider')])
db.executemany('INSERT INTO groups(id,name) VALUES(?,?)', [(10, 'Shared'), (20, 'Private')])
db.executemany('INSERT INTO group_members(group_id,user_id,status) VALUES(?,?,?)', [
    (10, 1, 'ACTIVE'), (10, 2, 'ACTIVE'), (20, 2, 'ACTIVE')
])
db.executemany('INSERT INTO group_settings(group_id,currency_code,decimal_scale) VALUES(?,?,?)', [
    (10, 'VND', 0), (20, 'USD', 2)
])
db.executemany('INSERT INTO expenses(id,group_id,payer_id,title,total_amount,created_at) VALUES(?,?,?,?,?,?)', [
    (100, 10, 1, 'Dinner', 16000, '2026-09-06 01:00:00'),
    (200, 20, 2, 'Private meal', 50.00, '2026-09-06 02:00:00'),
])
db.execute('INSERT INTO settlements(id,group_id,debtor_id,creditor_id,amount,status,requested_at,paid_at) VALUES(?,?,?,?,?,?,?,?)',
           (300, 10, 2, 1, 4000, 'PAID', '2026-09-06 03:00:00', '2026-09-06 03:00:00'))

rows = db.execute(query, (1, 1, 31, 0)).fetchall()
assert [row[0] for row in rows] == [300, 100], rows
assert db.execute(query, (1, 1, 1, 1)).fetchone()[0] == 100
assert [row[0] for row in db.execute(query, (2, 2, 31, 0)).fetchall()] == [300, 200, 100]
assert db.execute(query, (3, 3, 31, 0)).fetchall() == []
print('PASS: activity SQL respects membership, ordering and pagination in the lightweight fixture.')
