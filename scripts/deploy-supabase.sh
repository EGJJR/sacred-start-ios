#!/usr/bin/env bash
# Deploy Supabase migrations + edge functions for DevotionLock.
#
# Prerequisites (one time):
#   1. npx supabase login          # opens browser
#   2. npx supabase link --project-ref ygirplpbgxwvstnqxnrz
#
# Then run:
#   ./scripts/deploy-supabase.sh
#
# No Supabase CLI install needed — uses npx.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "→ Pushing database migrations…"
npx supabase db push --yes

echo "→ Deploying edge functions…"
npx supabase functions deploy chaplain-chat --no-verify-jwt
npx supabase functions deploy generate-insight --no-verify-jwt
npx supabase functions deploy delete-account --no-verify-jwt

echo "✓ Done. Migrations applied and functions deployed."
