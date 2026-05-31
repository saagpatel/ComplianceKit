# ComplianceKit

SOC 2 Type II audit readiness platform for seed-to-Series-B startups: a $2,500 human-led "Readiness Sprint" (gap assessment, remediation plan, policy templates) paired with a Next.js + Supabase SaaS ($199–499/mo) that automates evidence collection, generates AI-drafted security policies via Claude API, tracks remediation, and produces audit-ready evidence packages. Service sells first (Week 1), SaaS second (Week 7+).

## Stack

- **Frontend:** Next.js 14.2+ App Router + TypeScript
- **UI:** shadcn/ui + Tailwind CSS
- **Backend:** Next.js API Routes + Server Actions (no separate backend service)
- **Database:** Supabase Postgres 15+ (Auth + RLS + Vault + Storage)
- **AI:** Anthropic Claude API — `claude-sonnet-4-6` for policy gen + gap narrative
- **Email:** Resend (transactional)
- **Payments:** Stripe Checkout + Billing Portal
- **PDF:** @react-pdf/renderer (Phase 3+)
- **Cron:** Vercel Cron Jobs — daily evidence collection at 2:00 AM UTC
- **Deployment:** Vercel (auto-deploy from GitHub)

## Architecture

```
Customer Systems (Okta/AWS/GitHub/Google WS)
  → OAuth/API Keys →
Next.js App on Vercel (Dashboard, Gap Assessment, Policy Generator, Evidence Tracker, Audit Package)
  → Supabase (Postgres w/ RLS, Auth, Vault for secrets, Storage for files)
  → Claude API (policy generation, gap narrative — anonymized, no PII)
  → Resend (transactional email)
  → Stripe (billing)
Vercel Cron (daily) → Evidence Collector Worker → pulls from all connected integrations
```

## Build / Run

No standalone build command beyond `next dev` / `next build`. Env vars via Vercel only — never committed to git.

## Conventions

- TypeScript strict mode — type with `unknown` + narrowing, no `any`
- File naming: kebab-case for files, PascalCase for components
- API routes in `app/api/` following Next.js App Router conventions
- Supabase client: use `createServerClient` from `@supabase/ssr` in Server Components and API routes (see `lib/supabase/`)
- Every database table carries `org_id` with an RLS policy — implement in the first migration, not retrofitted later
- Verify RLS with 2 different orgs before merging any DB-related changes
- Git commits: `type(scope): description` (e.g., `feat(okta): add OAuth callback handler`)

## Constraints

- **Credentials:** OAuth tokens go in Supabase Vault only, referenced by `vault_secret_id` — never stored directly in the database or exposed to the frontend
- **PII gate:** Anonymize org context (company name, stack, team size only) before sending to Claude API — no PII
- **Session scope:** One integration per session (Okta, AWS, GitHub, Google WS are separate sessions); Phase 0 scaffolding is its own session
- **Okta integration:** Use raw HTTP with `fetch` — not the official Okta SDK — for fewer dependencies and full control
- **PDF export:** Build in Phase 3 after the gap assessment page renders without it
- **Scope:** SOC 2 Type II only until $20K MRR — ISO 27001, HIPAA, Slack/Jira/Azure integrations deferred

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| SaaS framework | Next.js 14+ App Router | Server components + Vercel deployment |
| Database | Supabase (Postgres + Auth + RLS + Vault) | Built-in auth, RLS for multi-tenancy, Vault for secrets |
| Evidence frequency | Every 24 hours via Vercel Cron | Balances API rate limits with freshness; auditors check quarterly |
| Multi-tenancy | Postgres RLS with org_id on every table | Supabase-native, no schema-per-tenant complexity for MVP |
| OAuth token storage | Supabase Vault (referenced by vault_secret_id) | Encrypted at rest, never exposed to frontend |
| MVP integrations | Okta + AWS + GitHub + Google Workspace | Covers 80%+ of seed-stage startup stacks |

<!-- portfolio-context:start -->
# Portfolio Context

## What This Project Is

ComplianceKit is an active local project in the /Users/d/Projects portfolio.

## Current State

**Phase 0: Service Infrastructure + Project Scaffolding** (target: Week 0-1)
- [ ] Initialize Next.js 14 project with App Router, TypeScript, Tailwind CSS, shadcn/ui
- [ ] Configure Supabase project: Auth (email + Google OAuth), full database schema
- [ ] Implement RLS policies on every table
- [ ] Seed SOC 2 controls table (45 controls mapped to Trust Services Criteria)
- [ ] Create auth flow: sign up → create org → invite members
- [ ] Deploy to Vercel with Supabase environment variables

## Stack

- Frontend: Next.js 14.2+ (App Router) with TypeScript
- UI: shadcn/ui + Tailwind CSS
- Backend: Next.js API Routes + Server Actions (no separate backend)
- Database: Supabase Postgres 15+ (Auth + RLS + Vault + Storage)
- AI: Anthropic Claude API — Sonnet 4.6 (`claude-sonnet-4-6`) for policy gen + gap narrative
- Email: Resend (transactional)
- Payments: Stripe (Checkout + Billing Portal)
- PDF: @react-pdf/renderer
- Cron: Vercel Cron Jobs (daily evidence collection at 2:00 AM UTC)
- Deployment: Vercel (auto-deploy from GitHub)

## How To Run

- TypeScript strict mode everywhere — no `any` types
- File naming: kebab-case for files, PascalCase for components
- API routes in `app/api/` following Next.js App Router conventions
- Supabase client: use `createServerComponentClient` in Server Components, `createRouteHandlerClient` in API routes
- Every database table must have `org_id` column with RLS policy
- Git commits: `type(scope): description` (e.g., `feat(okta): add OAuth callback handler`)
- Test RLS with 2 orgs before merging any DB-related changes
- Environment variables: Vercel env vars only, never committed to git

## Known Risks

- Do NOT scaffold the entire project in one session — break into phases, Phase 0 only in Session 1
- Do NOT implement multiple integrations in a single session — each integration (Okta, AWS, GitHub, Google WS) is its own session
- Do NOT use Okta's official SDK — use raw HTTP with `fetch` for fewer dependencies and full control
- Do NOT store any credentials in the database — OAuth tokens go in Supabase Vault only, referenced by `vault_secret_id`
- Do NOT skip RLS testing — test every table with 2 different orgs before moving on
- Do NOT use class components — functional components with hooks only
- Do NOT send PII to Claude API — anonymize org context (company name, stack, team size only) for policy generation
- Do NOT build the PDF export until Phase 3 — gap assessment page can render without export button first
- Do NOT create a separate backend service — all backend logic goes through Next.js API routes and Server Actions
- Do NOT defer RLS policy implementation — it must be in the first migration, not retrofitted later

## Next Recommended Move

Use this context plus the README and supporting docs to resume the next active task, then promote the repo beyond minimum-viable by capturing a dedicated handoff, roadmap, or discovery artifact.

<!-- portfolio-context:end -->
