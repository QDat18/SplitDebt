# SplitDebt database alignment

This build is aligned with the supplied PostgreSQL/Supabase schema where:

- `users.id`, `groups.id`, `group_members.id/group_id/user_id` are `UUID`.
- Financial tables such as `expenses`, `debts`, `settlements`, `notifications`, `user_settings`, and `group_settings` keep `BIGINT` user/group references.
- `users` has no `phone` or `password_hash` columns.
- `groups` has no `invite_code` column.
- `group_members` has no `status` column.

## Compatibility model

The API keeps numeric IDs in its Flutter-facing REST contract so the existing frontend and ledger math do not need a breaking migration. Four non-destructive companion tables are created:

- `splitdebt_user_keys(id BIGINT, user_uuid UUID)` maps a UUID user to the BIGINT ledger/API id.
- `splitdebt_group_keys(id BIGINT, group_uuid UUID)` maps a UUID group to the BIGINT ledger/API id.
- `splitdebt_credentials(user_uuid UUID, phone, password_hash, ...)` stores local-email credentials that are not present in `public.users`.
- `splitdebt_group_invites(group_uuid UUID, invite_code, ...)` stores invitation codes because `public.groups` has no `invite_code` column.

The original public tables are kept intact. New financial rows write the bridge BIGINT values into `expenses.group_id`, `payer_id`, participant user IDs, debt IDs, settlement IDs, notification user IDs, and settings IDs.

## Group creation flow

1. Resolve the signed-in numeric API user id to `users.id` UUID.
2. Insert `groups` with a UUID `id`, UUID `created_by`, and BIGINT `owner_id` bridge key.
3. Create/resolve the numeric bridge key in `splitdebt_group_keys`.
4. Insert the UUID membership in `group_members`.
5. Store the invite code in `splitdebt_group_invites`.
6. Store group settings under the BIGINT group bridge key.

This fixes the previous UUID/BIGINT failures without casting UUID values to BIGINT.

## Existing mixed legacy data

The database already contains older VARCHAR/UUID/BIGINT models at the same time. The API does not try to reinterpret old numeric financial rows as UUID ownership because that association cannot be reconstructed safely from the supplied schema alone. New writes are consistent through the bridge tables. Existing UUID users/groups are seeded into the bridge tables automatically at startup.

## Quick verification

After backend startup, run in Supabase SQL Editor:

```sql
SELECT * FROM splitdebt_user_keys ORDER BY id;
SELECT * FROM splitdebt_group_keys ORDER BY id;
SELECT * FROM splitdebt_group_invites ORDER BY created_at DESC;
```

After creating a new group:

```sql
SELECT g.id, g.name, g.created_by, g.owner_id, k.id AS api_group_id
FROM groups g
JOIN splitdebt_group_keys k ON k.group_uuid = g.id
ORDER BY g.created_at DESC;
```

The API/Flutter group id is `splitdebt_group_keys.id`; the physical PostgreSQL group id remains UUID.
