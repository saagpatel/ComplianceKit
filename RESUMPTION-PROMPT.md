# Resumption Prompt

[Paste this into Claude Code to resume the project]

---

You are resuming work on ComplianceKit — a SOC 2 Type II compliance readiness platform for seed-to-Series-B startups. It's a hybrid productized-service + SaaS: $2,500 one-time Readiness Sprint (human-led gap assessment) that converts to $199-499/mo SaaS (automated evidence collection, AI policy generation, audit-ready evidence packages).

## Project Context
ComplianceKit is a Next.js 14 (App Router) + Supabase (Postgres, Auth, RLS, Vault) web app deployed on Vercel. It integrates with Okta, AWS, GitHub, and Google Workspace to collect SOC 2 compliance evidence automatically. Claude Sonnet 4.5 generates security policies and gap assessment narratives. Stripe handles billing. Resend handles transactional email.

## Current State
- **Last completed phase:** Phase 0
- **Current phase:** Phase 1 — Okta Integration + Gap Dashboard
- **Last completed task:** Next.js scaffolded, Supabase schema deployed with RLS on all tables, 45 SOC 2 controls seeded, auth flow working (sign up → create org → dashboard), deployed to Vercel
- **Next task:** Session 3 — Build Okta OAuth flow (PKCE) + callback handler + token storage in Supabase Vault

## What's Already Built
- `app/layout.tsx` — Root layout with sidebar nav and header
- `app/(auth)/` — Sign up, sign in, org creation flows
- `app/(dashboard)/` — Dashboard shell with placeholder content
- `supabase/migrations/` — Full schema: organizations, users, integrations, controls, org_controls, evidence, policies, gap_assessments, sync_logs
- `supabase/seed.sql` — 45 SOC 2 controls mapped to Trust Services Criteria (CC1-CC9)
- RLS policies on every table using `org_id = auth.jwt() ->> 'org_id'`

## What's NOT Built Yet
- Okta OAuth flow + data collector (Session 3-4)
- Dashboard with real data (score, controls list, evidence) (Session 5)
- Gap assessment engine + AI narrative (Session 6)
- AI policy generator + editor (Session 7)
- AWS integration (Session 8)
- GitHub integration (Session 9)
- Google Workspace integration (Session 10)
- Audit package PDF export (Session 11)
- Onboarding flow + landing page + Stripe billing (Session 12)

## Immediate Next Steps
1. Build Okta OAuth redirect handler with PKCE — redirect user to Okta consent screen
2. Build callback handler at `/api/auth/callback/okta` — exchange authorization code for tokens
3. Store access token + refresh token in Supabase Vault, create integration record with `vault_secret_id`
4. Build "Connect Okta" button on `/dashboard/settings/integrations`
5. Handle token refresh (auto-refresh on 401 using stored refresh token)

## Key Files to Read First
- `CLAUDE.md` — Project config, tech stack, conventions, anti-patterns
- `package.json` — Dependencies and scripts
- `supabase/migrations/` — Database schema (especially `integrations` table with `vault_secret_id`)
- `lib/integrations/` — Integration module directory (create `okta.ts` here)
- `app/api/auth/callback/` — OAuth callback handlers directory

## Decisions Already Made (Do Not Revisit)
- Next.js 14 App Router with TypeScript strict mode
- Supabase for DB + Auth + RLS + Vault + Storage
- Claude Sonnet 4.5 for AI policy gen and gap narrative
- shadcn/ui + Tailwind CSS for UI
- OAuth tokens stored in Supabase Vault only (never in DB columns)
- RLS on every table via `org_id`
- Raw `fetch` for Okta API calls (no Okta SDK)
- One integration per Claude Code session
- Daily evidence collection via Vercel Cron at 2:00 AM UTC
- SOC 2 Type II only — no ISO 27001, HIPAA until $20K MRR
- Stripe for billing (Starter $199/mo, Growth $499/mo)
- Resend for transactional email
- @react-pdf/renderer for audit package PDF
