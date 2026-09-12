# Backend BIGINT schema fix - 2026-09-12

## Root cause

The live PostgreSQL database uses BIGINT identifiers for `users.id` (and the original SplitDebt schema uses BIGINT for groups/members/financial tables). A compatibility rewrite had introduced UUID bridge tables and attempted:

```sql
INSERT INTO splitdebt_user_keys(user_uuid)
SELECT u.id FROM users u
WHERE NOT EXISTS (SELECT 1 FROM splitdebt_user_keys k WHERE k.user_uuid=u.id);
```

PostgreSQL correctly rejected `UUID = BIGINT`.

## Fix

- Restored the API to the project's native BIGINT identity model.
- Removed runtime use of `splitdebt_user_keys`, `splitdebt_group_keys`, and `splitdebt_credentials`.
- Registration/login/profile now read and write `users.id` directly.
- Group and membership operations use `groups.id`, `group_members.group_id`, and `group_members.user_id` directly.
- Google identities and password reset tokens reference the native BIGINT `users.id`.
- Preserved UX/API improvements: notification read-all, settlement direction fields, effective balances, pending payment totals, member phone, and statistics DAY/MONTH/YEAR with `mySpent`.
- Added non-destructive compatibility columns for `phone`, `password_hash`, `updated_at`, group-member `status`, and group-settings fields when missing.

## Run after replacing the project

On Windows:

```bat
cd D:\AndroidProject\SplitDebt\api
mvnw.cmd clean spring-boot:run
```

Do not start with an old `target/classes` directory without running `clean` because it can still contain the previous UUID `schema.sql`.

The old `splitdebt_*` bridge tables can remain in PostgreSQL; the fixed runtime does not query them. Do not drop them unless you have separately confirmed they contain no needed data.
