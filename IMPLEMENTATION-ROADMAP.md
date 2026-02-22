# Implementation Roadmap

## Session Strategy
Each Claude Code session should tackle ONE phase or sub-phase. Do not attempt multiple phases in a single session. Sessions are scoped to ~2-3 hours of work. After each session, update CLAUDE.md's "Current Phase" section with completed/remaining tasks.

---

## Phase 0: Service Infrastructure + Project Scaffolding (Week 0-1)

### Session 1 scope: Next.js scaffold + Supabase + Auth + RLS
**Time estimate:** 2-3 hours
**Tasks:**
1. Initialize Next.js 14 project: App Router, TypeScript strict mode, Tailwind CSS, shadcn/ui
2. Configure Supabase project: connect to Next.js, set up environment variables
3. Create full database schema (all 8 tables from spec: organizations, users, integrations, controls, org_controls, evidence, policies, gap_assessments, sync_logs)
4. Implement RLS policies on every table (`WHERE org_id = auth.jwt() ->> 'org_id'`)
5. Test RLS: create 2 test orgs, verify cross-tenant isolation
6. Deploy to Vercel with Supabase env vars

**Deliverables:**
- Working Next.js app on Vercel
- Full database schema with RLS
- Auth flow (email + Google OAuth)

**Verification:**
- `npm run dev` starts without errors
- Vercel deployment loads auth page
- RLS test: query as Org A returns 0 Org B rows

**Context files:** `CLAUDE.md`, `package.json`

### Session 2 scope: Controls seed data + org creation flow + auth UX
**Time estimate:** 1-2 hours
**Tasks:**
1. Create seed SQL file with 45 SOC 2 controls mapped to Trust Services Criteria (CC1-CC9 Security category)
2. Build org creation flow: sign up → create org → set org name/slug → land on dashboard
3. Build invite flow: owner generates invite link → new user joins org
4. Build basic app shell: sidebar nav, header with org name, placeholder dashboard

**Deliverables:**
- 45 controls seeded in database
- Working auth → org creation → dashboard flow
- App shell with navigation

**Verification:**
- `SELECT count(*) FROM controls` returns 45
- New user can sign up, create org, see empty dashboard
- Second user can join via invite link

**Context files:** `CLAUDE.md`, `package.json`, `supabase/migrations/`, `app/layout.tsx`

---

## Phase 1: Okta Integration + Gap Dashboard (Weeks 2-4)

### Session 3 scope: Okta OAuth flow + token storage
**Time estimate:** 2-3 hours
**Tasks:**
1. Build Okta OAuth app registration guide (documented in-app)
2. Build OAuth redirect handler: redirect to Okta consent screen with PKCE
3. Build callback handler at `/api/auth/callback/okta`: exchange code for tokens, store in Supabase Vault, create integration record with `vault_secret_id`
4. Build integration settings page (`/dashboard/settings/integrations`) with "Connect Okta" button
5. Handle token refresh (refresh token stored in Vault, auto-refresh on 401)

**Deliverables:**
- End-to-end Okta OAuth flow
- Tokens stored securely in Supabase Vault
- Integration record with status tracking

**Verification:**
- Click "Connect Okta" → redirects to Okta consent → callback stores token → integration status = 'active'
- Token refresh works on simulated 401

**Context files:** `CLAUDE.md`, `package.json`, `lib/integrations/okta.ts`, `app/api/auth/callback/okta/`

### Session 4 scope: Okta data collector + evidence storage
**Time estimate:** 2-3 hours
**Tasks:**
1. Build Okta data collector module (`lib/collectors/okta.ts`): fetch users, groups, apps, MFA factors
2. Handle Okta pagination (Link header) and rate limiting (429 → exponential backoff: 1s, 2s, 4s, max 30s)
3. Map Okta data to evidence records: CC6.1 (MFA), CC6.2 (inactive accounts), CC6.3 (admin access)
4. Build sync trigger API route (`/api/integrations/{id}/sync`)
5. Store evidence as structured JSON in evidence table

**Deliverables:**
- Okta collector pulls users, groups, apps, MFA status
- Evidence records created for 3 SOC 2 controls
- Manual sync trigger works

**Verification:**
- Connect Okta test org (50 users) → sync → evidence appears in DB for CC6.1, CC6.2, CC6.3
- 500+ user org syncs without rate limit errors
- Evidence data is structured JSON (not raw API dump)

**Context files:** `CLAUDE.md`, `lib/integrations/okta.ts`, `lib/collectors/okta.ts`, `app/api/integrations/`

### Session 5 scope: Dashboard UI (score, controls list, detail)
**Time estimate:** 2-3 hours
**Tasks:**
1. Build dashboard page (`/dashboard`): compliance score %, controls by status pie chart, recent evidence log
2. Build controls list page (`/dashboard/controls`): 45 controls with status badges, filterable by category and status
3. Build control detail page (`/dashboard/controls/{id}`): description, evidence items, remediation notes, assigned user
4. Wire up real data from Supabase (org_controls + evidence tables)

**Deliverables:**
- Dashboard with compliance score and visualizations
- Controls list with filtering
- Control detail with evidence display

**Verification:**
- Dashboard renders with seeded data in <2 seconds
- Okta evidence from Session 4 appears on control detail pages
- Filters work correctly

**Context files:** `CLAUDE.md`, `app/(dashboard)/`, `components/controls/`, `lib/supabase/`

### Session 6 scope: Gap assessment engine + AI narrative
**Time estimate:** 2 hours
**Tasks:**
1. Build gap assessment logic: iterate org_controls, compute score (compliant / total × 100), identify top 5 gaps
2. Build Claude API integration for narrative: send control statuses → receive 500-word gap summary + prioritized recommendations
3. Build gap assessment results page with score, AI narrative, recommendations list
4. Set up Vercel Cron Job: daily evidence collection at 2:00 AM UTC
5. Store assessment results in gap_assessments table

**Deliverables:**
- Gap assessment computes score and identifies gaps
- AI narrative generation via Claude Sonnet 4.5
- Daily cron job for evidence collection

**Verification:**
- Gap score matches manual count of compliant/total controls
- AI narrative is accurate and actionable for test data
- Cron triggers and evidence refreshes daily

**Context files:** `CLAUDE.md`, `lib/assessment.ts`, `app/api/gap-assessment/`, `vercel.json`

---

## Phase 2: AI Policies + AWS/GitHub Integration (Weeks 5-7)

### Session 7 scope: AI policy generator + editor UI
**Time estimate:** 2-3 hours
**Tasks:**
1. Build policy generation prompt system: 12 policy types, each with structured prompt including company context (name, stack, team size, industry) and 2-shot examples
2. Build policy generation API route (`/api/policies/generate`): accepts policy type + org context → returns Markdown
3. Build policy editor UI (`/dashboard/policies/{id}/edit`): Markdown editor with preview, version history, approval workflow (draft → review → approved)
4. Build policy list page (`/dashboard/policies`): all 12 policies with status, "Generate All" button
5. Map policies to controls via `control_ids` array

**Deliverables:**
- AI generates 12 SOC 2 policies with company context
- Policy editor with versioning and approval
- Policies linked to controls

**Verification:**
- Each generated policy is 2,000-4,000 words, matches SOC 2 requirements
- Single policy generates in <15 seconds
- All 12 policies generate in <3 minutes
- Edit → save → approve workflow works

**Context files:** `CLAUDE.md`, `lib/policies/`, `app/(dashboard)/policies/`, `app/api/policies/`

### Session 8 scope: AWS integration (role setup + collector)
**Time estimate:** 2-3 hours
**Tasks:**
1. Build AWS integration via cross-account IAM Role with external ID
2. Build AWS setup wizard UI: step-by-step guide with downloadable CloudFormation template
3. Build AWS evidence collector (`lib/collectors/aws.ts`): Config rules compliance, IAM credential report, CloudTrail status, S3 encryption
4. Handle AWS pagination (NextToken) and throttling (retry with jitter)
5. Map AWS data to ~10 SOC 2 controls

**Deliverables:**
- AWS cross-account role setup wizard
- Evidence collection for 10 controls
- CloudFormation template for customer setup

**Verification:**
- Customer can create role via CloudFormation in <5 minutes
- 50+ Config rules sync without errors
- Evidence appears on relevant control detail pages

**Context files:** `CLAUDE.md`, `lib/integrations/aws.ts`, `lib/collectors/aws.ts`, `app/api/integrations/`

### Session 9 scope: GitHub integration (OAuth + collector)
**Time estimate:** 2 hours
**Tasks:**
1. Build GitHub OAuth App flow (Authorization Code, scopes: `read:org`, `repo`)
2. Build GitHub evidence collector (`lib/collectors/github.ts`): branch protection rules, dependabot alerts, secrets scanning alerts, collaborators
3. Map GitHub data to controls: CC8.1 (change management), CC7.1 (vulnerability management), CC6.1 (access control)
4. Wire into daily cron job

**Deliverables:**
- GitHub OAuth flow with token storage
- Evidence for 5 controls
- Integrated into daily evidence collection

**Verification:**
- OAuth flow works end-to-end
- Evidence from branch protection, dependabot, secrets scanning appears on control pages
- Daily cron includes GitHub sync

**Context files:** `CLAUDE.md`, `lib/integrations/github.ts`, `lib/collectors/github.ts`, `app/api/auth/callback/github/`

---

## Phase 3: Google Workspace + Audit Package + Polish (Weeks 8-10)

### Session 10 scope: Google Workspace integration
**Time estimate:** 2 hours
**Tasks:**
1. Build Google OAuth flow (Admin SDK scopes: `admin.directory.user.readonly`, `admin.directory.group.readonly`)
2. Build Google Workspace collector (`lib/collectors/google.ts`): users + 2FA status, admin roles, groups
3. Map to controls: CC6.1 (MFA), CC6.2 (access reviews), CC6.3 (admin access)
4. Wire into daily cron job
5. Verify total evidence coverage: ~30 of 45 controls automated

**Deliverables:**
- Google Workspace OAuth + evidence collection
- Evidence for 5 controls
- 30+ controls with automated evidence

**Verification:**
- OAuth works, evidence appears on control detail pages
- Daily cron includes Google WS sync
- Dashboard shows 30+ controls with evidence

**Context files:** `CLAUDE.md`, `lib/integrations/google.ts`, `lib/collectors/google.ts`, `app/api/auth/callback/google/`

### Session 11 scope: Audit package PDF export
**Time estimate:** 2-3 hours
**Tasks:**
1. Build evidence package generator (`lib/pdf/`): compile all evidence for date range → structured JSON → @react-pdf/renderer PDF
2. PDF structure: cover page, executive summary (AI-generated), control-by-control evidence with timestamps, policy documents, gap summary
3. Build "Export Audit Package" button on dashboard
4. Build manual evidence upload UI (`/dashboard/evidence/upload`): upload files (PDF, PNG, CSV), attach to control

**Deliverables:**
- Audit-ready PDF export
- Manual evidence upload for non-automated controls

**Verification:**
- PDF is <50 pages, renders in <30 seconds
- PDF includes evidence from all 4 integrations + policies + gap summary
- Manual upload attaches to correct control

**Context files:** `CLAUDE.md`, `lib/pdf/`, `app/api/audit-package/`, `app/(dashboard)/evidence/`

### Session 12 scope: Onboarding flow + landing page + Stripe
**Time estimate:** 2-3 hours
**Tasks:**
1. Build self-serve onboarding wizard: sign up → create org → connect integrations → run gap assessment → see results
2. Build landing page (`/`): hero, problem statement, features, pricing, FAQ, CTA
3. Build pricing page with Stripe Checkout (Starter $199/mo, Growth $499/mo)
4. Build Stripe webhook handler for subscription lifecycle (created, updated, cancelled, payment_failed)
5. Set up Resend transactional emails: welcome, integration connected, gap assessment complete, subscription created

**Deliverables:**
- Self-serve onboarding (<10 minutes)
- Marketing landing page + pricing
- Stripe subscriptions working
- Transactional emails

**Verification:**
- New user completes onboarding in <10 minutes
- Landing page loads in <2 seconds, mobile responsive
- Stripe subscription lifecycle works in test mode
- Emails deliver with <5 second latency

**Context files:** `CLAUDE.md`, `app/(marketing)/`, `app/api/stripe/`, `app/(auth)/`, `lib/email/`

---

## Context Management

- **Always include in every session:** `CLAUDE.md`, `package.json`
- **For database work:** add `supabase/migrations/` folder
- **For API routes:** add the route file + corresponding `lib/` module + relevant types
- **For integration work:** add `lib/integrations/{provider}.ts` + `lib/collectors/{provider}.ts`
- **For UI work:** add `app/(dashboard)/` relevant pages + `components/` relevant components
- **Maximum 5-7 files per session context**
- **After each session:** update CLAUDE.md "Current Phase" with completed tasks, add any new decisions to the table
