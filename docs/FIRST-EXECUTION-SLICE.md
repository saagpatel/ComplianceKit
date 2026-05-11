# ComplianceKit — First Execution Proof Slice

Defines the minimum end-to-end slice that proves ComplianceKit is more
than a scaffold. If this slice runs cleanly on a deployed environment,
the product has a demonstrable foundation. If it does not, treat the
codebase as still-scaffolded and prioritize closing this slice over
any Phase 1+ work.

> **Audience:** anyone resuming ComplianceKit work, evaluating
> readiness for a demo, or scoping the next coding session.

---

## Why this exists

The current `README.md` describes ComplianceKit as a "scaffolded
application shell" and the `IMPLEMENTATION-ROADMAP.md` decomposes the
build into 10+ sessions. That decomposition is useful for execution
but does not answer the operator-level question: **what is the
smallest thing we can do that proves the product premise?** The
portfolio operating system flagged a "first governed execution slice"
packet specifically to force this answer.

A slice is a vertical cut through the stack (UI → auth → API →
database → back to UI) that delivers one observable user outcome. It
is the unit ComplianceKit's portfolio status should be measured
against, not roadmap-phase completion percentage.

---

## The slice (v0)

**One user can sign up, create an organization, and see the 45 SOC 2
controls scoped to that organization in a dashboard table.**

That's it. Nothing more in the v0 slice. No integrations, no
evidence, no audit packets — those are subsequent slices.

### Slice ingredients

| Layer | What must exist |
|---|---|
| Auth | Supabase email/password (Google OAuth is bonus, not required for v0) |
| DB | `organizations`, `users`, `controls`, `org_controls` tables with RLS |
| Seed | 45 SOC 2 controls inserted into `controls` |
| API | Server action or route that lists `controls` joined to `org_controls` for the current user's org |
| UI | `/dashboard` route renders a table of 45 rows after sign-up |
| Hosting | Deployed to Vercel with the Supabase env vars wired |

### Slice non-ingredients (defer to later slices)

- Okta or any other integration
- Evidence upload
- Gap assessments / scoring
- Multi-user invites
- Policy editor
- Auditor-facing exports
- Stripe / billing
- Background jobs / scheduled syncs

If any of the above feels essential, that is a sign the slice
ambition is wrong and should stay narrow.

---

## Definition of done — observable proof

The slice is "done" when an operator can reproduce every row below on
the deployed environment, in order, in under 5 minutes from a fresh
incognito session.

| # | Action | Proof artifact |
|---|---|---|
| 1 | Visit deployed Vercel URL | `/` renders without auth error, redirects to sign-up |
| 2 | Sign up with a new email | Email verification (if enabled) lands; redirect to org creation |
| 3 | Create org "Acme Test" | Row appears in Supabase `organizations`; `users.org_id` set |
| 4 | Land on `/dashboard` | Page renders without 500; sidebar shows org name |
| 5 | Open Controls table | Exactly 45 rows visible; each row shows control_id, name, category |
| 6 | RLS sanity check (SQL) | `SELECT count(*) FROM controls WHERE org_id = '<other-org-uuid>'` returns 0 when run as Acme's user |

Each row should produce a screenshot (or a SQL output) checked into
`docs/slice-v0-proof/`.

---

## Verification — local

Before declaring the slice done, run from a clean checkout:

```bash
pnpm install --frozen-lockfile --ignore-scripts
pnpm lint
pnpm typecheck
pnpm build
```

All four must pass. Beyond that:

```bash
pnpm dev
# In another terminal, run the supabase migration + seed:
pnpm supabase db reset      # or whatever the project's migration command becomes
# Manually walk through steps 1-5 from the table above against http://localhost:3000
```

If a piece is not yet implemented, the slice is not done. Do not
ship a partial slice to Vercel — partial slices waste the proof.

---

## Verification — deployed

Once deployed, re-run the table above against the live Vercel URL.
Reproducibility on the deployment is what matters. Local-only is
worth less than 50% of the slice.

---

## How this maps to existing roadmap sessions

| Slice ingredient | Roadmap home |
|---|---|
| Next.js + Supabase + RLS + Vercel deploy | Phase 0, Session 1 |
| 45 controls seed + org creation flow + dashboard shell | Phase 0, Session 2 |

The slice is essentially "Sessions 1 + 2 of Phase 0 — completed and
deployed, not just merged." The packet is a forcing function to
confirm those sessions actually shipped end-to-end, not just locally.

---

## What this slice does NOT prove

Listing these out explicitly so the slice is not over-claimed:

- It does NOT prove the product is differentiated (any SOC 2 SaaS
  has a controls table).
- It does NOT prove the data model scales (45 rows × 1 org is not a
  scale test).
- It does NOT prove the auth flow is secure (just functionally
  working — security review is a separate gate).
- It does NOT prove the multi-tenant isolation is bulletproof (only
  one cross-org RLS read is checked).

These are deliberate omissions, not gaps. They become later slices.

---

## Next slice candidates (informational, not committed)

In rough order of value once the v0 slice is green:

1. **Okta integration slice** — connect an Okta tenant, list users +
   MFA factors, store one evidence record. Proves the integration
   pattern.
2. **Gap dashboard slice** — given evidence from one integration,
   compute and render a gap score per control. Proves the
   value-prop calculation, not just the data movement.
3. **Evidence storage slice** — upload a PDF, store it encrypted,
   render a link in the controls table. Proves the storage path
   without integrations.
4. **Auditor export slice** — produce a static report of org
   controls + evidence pointers. Proves the deliverable shape.

Each of those is its own packet. Don't merge them.

---

## When to escalate / reframe

If the v0 slice cannot be closed in one focused session (≤3 hours
implementation, plus a Vercel deploy), the right move is to
**reframe**, not push harder. Likely reframes:

- Drop Google OAuth from the slice (already noted as bonus above).
- Drop email verification (use Supabase magic links or simple
  email/password without confirmation).
- Drop the `org_controls` table — start with `controls` only and add
  org scoping as a follow-up slice.
- Replace Vercel deploy with `pnpm dev` + Loom — slice still counts as
  "demonstrated" if reproducibility on a fresh laptop is verified.

The reframe is the point: ship a thinner slice that proves SOMETHING,
not a thicker one that proves nothing.
