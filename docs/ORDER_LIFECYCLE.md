# PABLOX — order lifecycle

A proposed server-enforced order status transition function is in `supabase/order_status.sql`.

- new → accepted → preparing → ready → completed
- Owners and managers may cancel new, accepted, or preparing orders.
- Staff can progress orders but cannot cancel them.
- The function verifies authenticated membership in the specified restaurant and locks the row before updating.
- It rejects transitions for a different restaurant even when the order UUID is known.
- No anonymous writes or browser-side service keys are used.

**Not deployed:** SQL needs a dedicated Supabase project, migrations and integration tests. The current GitHub Pages UI still uses demo data.

Before production: add status history/audit records, refund handling, server-side order intake, payment and tax rules, notification delivery, and test all role/tenant boundaries.
