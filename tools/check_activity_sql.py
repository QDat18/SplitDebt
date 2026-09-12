"""Exercise the activity SELECT against a minimal SQLite fixture.

This is intentionally a lightweight SQL-shape/access-control check that mirrors
SplitDebt's UUID identity tables plus BIGINT ledger bridge tables. It does not
replace the H2/PostgreSQL integration tests in Maven.
"""
from pathlib import Path
import re
import sqlite3

root = Path(__file__).resolve().parents[1]
source = (root / 'api/src/main/java/com/splitdebt/api/ledger/LedgerService.java').read_text(encoding='utf-8')
match = re.search(r'public\s+ActivityPage\s+activity\(.*?String\s+sql\s*=\s*"""(.*?)"""\s*;', source, re.S)
if not match:
    raise AssertionError('Could not locate LedgerService.activity SQL text block.')
query = match.group(1)

db = sqlite3.connect(':memory:')
db.executescript('''
CREATE TABLE users(id TEXT PRIMARY KEY, full_name TEXT NOT NULL);
CREATE TABLE groups(id TEXT PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE splitdebt_user_keys(id INTEGER PRIMARY KEY, user_uuid TEXT NOT NULL UNIQUE);
CREATE TABLE splitdebt_group_keys(id INTEGER PRIMARY KEY, group_uuid TEXT NOT NULL UNIQUE);
CREATE TABLE group_members(group_id TEXT NOT NULL, user_id TEXT NOT NULL, role TEXT NOT NULL);
CREATE TABLE group_settings(group_id INTEGER PRIMARY KEY, currency_code TEXT, decimal_scale INTEGER);
CREATE TABLE expenses(
    id INTEGER PRIMARY KEY, group_id INTEGER NOT NULL, payer_id INTEGER NOT NULL,
    title TEXT NOT NULL, total_amount NUMERIC NOT NULL, created_at TEXT NOT NULL
);
CREATE TABLE settlements(
    id INTEGER PRIMARY KEY, group_id INTEGER NOT NULL, debtor_id INTEGER NOT NULL,
    creditor_id INTEGER NOT NULL, amount NUMERIC NOT NULL, status TEXT NOT NULL,
    requested_at TEXT, paid_at TEXT, confirmed_at TEXT
);
''')

users = [
    ('u1', 'Alex'),
    ('u2', 'Sam'),
    ('u3', 'Outsider'),
]
groups = [('g10', 'Shared'), ('g20', 'Private')]
db.executemany('INSERT INTO users(id,full_name) VALUES(?,?)', users)
db.executemany('INSERT INTO groups(id,name) VALUES(?,?)', groups)
db.executemany('INSERT INTO splitdebt_user_keys(id,user_uuid) VALUES(?,?)', [(1, 'u1'), (2, 'u2'), (3, 'u3')])
db.executemany('INSERT INTO splitdebt_group_keys(id,group_uuid) VALUES(?,?)', [(10, 'g10'), (20, 'g20')])
db.executemany('INSERT INTO group_members(group_id,user_id,role) VALUES(?,?,?)', [
    ('g10', 'u1', 'OWNER'), ('g10', 'u2', 'MEMBER'), ('g20', 'u2', 'OWNER')
])
db.executemany('INSERT INTO group_settings(group_id,currency_code,decimal_scale) VALUES(?,?,?)', [
    (10, 'VND', 0), (20, 'USD', 2)
])
db.executemany('INSERT INTO expenses(id,group_id,payer_id,title,total_amount,created_at) VALUES(?,?,?,?,?,?)', [
    (100, 10, 1, 'Dinner', 16000, '2026-09-06 01:00:00'),
    (200, 20, 2, 'Private meal', 50.00, '2026-09-06 02:00:00'),
])
db.execute('INSERT INTO settlements(id,group_id,debtor_id,creditor_id,amount,status,requested_at,paid_at,confirmed_at) VALUES(?,?,?,?,?,?,?,?,?)',
           (300, 10, 2, 1, 4000, 'PAID', '2026-09-06 03:00:00', '2026-09-06 03:00:00', None))

rows = db.execute(query, (1, 1, 31, 0)).fetchall()
assert [row[0] for row in rows] == [300, 100], rows
assert db.execute(query, (1, 1, 1, 1)).fetchone()[0] == 100
assert [row[0] for row in db.execute(query, (2, 2, 31, 0)).fetchall()] == [300, 200, 100]
assert db.execute(query, (3, 3, 31, 0)).fetchall() == []
print('PASS: activity SQL respects UUID membership, ledger bridges, ordering and pagination.')
