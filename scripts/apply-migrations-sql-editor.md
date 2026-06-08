# Apply migrations without the CLI

Use this if you prefer the Supabase Dashboard SQL Editor (no `supabase login` required).

## Order

Run each file **once**, in order, in [SQL Editor](https://supabase.com/dashboard/project/ygirplpbgxwvstnqxnrz/sql/new):

| # | File | Skip if… |
|---|------|----------|
| 1 | `supabase/migrations/prayer_circles_phase2.sql` | Prayer circles already work in the app |
| 2 | `supabase/migrations/20260607040000_profiles_account_management.sql` | Account edit / username / avatar already work |

Copy the **entire file contents** into a new query → **Run**.

`initial_schema` is not in this repo (applied manually when the project was created). If tables like `profiles` or `devotion_sessions` are missing, that schema must exist first.

## Deploy `delete-account` without CLI

1. Dashboard → **Edge Functions** → **Deploy a new function** (or update existing)
2. Name: `delete-account`
3. Paste code from `supabase/functions/delete-account/index.ts`
4. Deploy

Or use the CLI after login (see `scripts/deploy-supabase.sh`).

## Demo data (optional)

After migrations: paste `supabase/seed/egj3502_demo_data.sql` in SQL Editor.
