# ComplianceKit — Discovery Summary

## Problem Statement
Seed-to-Series-B startups need SOC 2 Type II compliance to close enterprise deals, but the process is opaque, manual, and expensive ($20K-50K for consultants + 6-12 months). Founders waste 10-20 hours/week gathering evidence manually from Okta, AWS, GitHub, and Google Workspace. They copy-paste screenshots into spreadsheets, write security policies from scratch, and have no idea if they're actually ready for an audit until the auditor tells them they're not. The gap between "we need SOC 2" and "we passed our audit" is filled with busywork that a solo IT/compliance engineer could automate.

## Target User
**Primary:** Technical founders or first IT/security hire at seed-to-Series-B startups with <75 employees. They use Okta for identity, AWS for infrastructure, GitHub for code, and Google Workspace for email/docs. They're preparing for their first SOC 2 Type II audit (usually because an enterprise prospect or investor requires it). They interact with the product daily during active audit prep (8-12 weeks) and weekly for ongoing monitoring.

**Secondary:** Fractional CISOs or vCISOs managing compliance for 5-10 startup clients simultaneously. They need a dashboard to track multiple orgs.

## Success Metrics
- 5 paid Readiness Sprint clients ($12,500 total) by Day 30
- 3 SaaS subscribers at $199+/mo by Day 60
- $12,500/mo blended revenue (services + SaaS) within 90 days
- Dashboard loads in <2 seconds for an org with 200 users + 50 apps + 100 AWS resources
- AI policy generation produces auditor-acceptable output for 10/12 core SOC 2 policies (validated by 1 CPA review)
- Evidence collection runs automatically every 24 hours with <5% failure rate
- Sprint-to-SaaS conversion rate ≥70%

## Scope Boundaries
**In scope:**
- SOC 2 Type II readiness assessment and monitoring
- Automated evidence collection from Okta, AWS, GitHub, Google Workspace
- AI-generated security policies (12 core SOC 2 policies)
- Gap assessment with compliance score and AI narrative
- Audit-ready evidence package PDF export
- Self-serve onboarding with integration wizard
- Stripe billing (Starter $199/mo, Growth $499/mo)
- Readiness Sprint service delivery infrastructure (Calendly, Typeform, templates)

**Out of scope:**
- ISO 27001, HIPAA, PCI DSS, or any framework beyond SOC 2
- Acting as an auditor or providing audit guarantees
- Slack, Jira, Azure, Datadog, or other integrations beyond the core 4
- Mobile app
- White-label / multi-tenant reseller model
- Custom compliance framework builder
- Real-time alerting (daily collection is sufficient)

**Deferred to later phases:**
- Slack integration (Phase 4+, after $20K MRR)
- Jira integration (Phase 4+)
- Azure integration (Phase 4+)
- ISO 27001 framework support (after $20K MRR)
- HIPAA framework support (after $20K MRR)
- Schema-per-tenant isolation upgrade (if RLS proves insufficient)
- Part-time VA for Tier 1 support (at 20+ customers)
- vCISO multi-org dashboard (Phase 5+)

## Technical Constraints
- All customer data encrypted at rest (Supabase AES-256) and in transit (TLS 1.3)
- Zero customer credentials in DB — OAuth tokens in Supabase Vault only
- Read-only API access to all customer systems
- Row-level security (RLS) on every table via `org_id`
- GDPR-compliant: full data deletion on request (CASCADE from organizations table)
- Okta API rate limit: 100 req/min — requires pagination + exponential backoff
- AWS Config API: 20 req/sec — retry with jitter on ThrottlingException
- GitHub API: 5,000 req/hr — respect X-RateLimit-Reset header
- Google Workspace Admin SDK: 600 req/min — exponential backoff on 429
- Claude API: tier-dependent rate limits — retry after Retry-After header
- Solo builder: 15-25 hrs/week, ~2-3 hour Claude Code sessions
- M4 Pro 48GB development machine

## Key Integrations
| Service | API | Auth Method | Rate Limits | Purpose |
|---------|-----|-------------|-------------|---------|
| Okta Admin API | `https://{domain}.okta.com/api/v1/{resource}` | OAuth 2.0 Bearer | 100 req/min | Users, groups, apps, MFA status → evidence for CC6.1, CC6.2, CC6.3 |
| AWS Config | `config.{region}.amazonaws.com` | IAM STS AssumeRole | 20 req/sec | Config rules, IAM credential report, CloudTrail, S3 encryption → evidence for 10 controls |
| GitHub REST API | `https://api.github.com/{resource}` | OAuth 2.0 Bearer | 5,000 req/hr | Branch protection, dependabot, secrets scanning, collaborators → evidence for CC8.1, CC7.1, CC6.1 |
| Google Workspace Admin SDK | `https://admin.googleapis.com/admin/directory/v1/{resource}` | OAuth 2.0 Bearer | 600 req/min | Users, 2FA status, admin roles, groups → evidence for CC6.1, CC6.2, CC6.3 |
| Anthropic Claude API | `https://api.anthropic.com/v1/messages` | API key (x-api-key) | Tier-dependent | Policy generation (12 policies), gap assessment narrative |
| Stripe API | `https://api.stripe.com/v1/{resource}` | Bearer token | 100 req/sec | Subscription management, invoicing |
| Resend API | `https://api.resend.com/emails` | Bearer token | 100 req/sec | Transactional emails (welcome, integration connected, assessment complete) |
