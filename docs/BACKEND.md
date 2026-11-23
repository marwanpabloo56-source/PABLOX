# PABLOX Backend Foundation

This branch adds a **proposed** Supabase/PostgreSQL schema, not a live database connection.

## Architecture
- Frontend: React/Vite dashboard (existing demo).
- Auth: Supabase Auth with server-validated roles.
- Storage: PostgreSQL with restaurant-scoped rows and RLS.
- Order ingestion: trusted server endpoint; validate input, idempotency key and restaurant API credential; calculate totals from product records; insert order and items in one transaction.
- Printing: later local bridge with paired-device credentials and explicit printer selection.
- Existing POS: vendor-specific connectors, never assume universal compatibility.

## Security decisions
- No secret/service-role keys in Vite frontend or GitHub Pages.
- RLS allows authenticated members to read only their restaurant.
- Client write policies are intentionally absent until authorization and audit design is complete.
- Do not expose public order creation through direct database inserts.
- Tenant onboarding must use a privileged audited backend operation, never a public insert policy.
- Order status transitions require server-side authorization and validation.
- Use piasters (integer) for monetary amounts, not floating point.

## Setup later
1. Create a dedicated Supabase project and keep its service key server-side.
2. Review and run `supabase/schema.sql` in a controlled migration.
3. Add secure tenant onboarding, server order API, and authenticated dashboard integration.
4. Test isolation with two restaurants before enabling real orders.

No database has been provisioned and no production data is stored.
