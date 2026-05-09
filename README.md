# ComplianceKit

ComplianceKit is a hybrid productized-service plus SaaS workflow for SOC 2 audit readiness. The current repo state is an early scaffold for the web app layer built with Next.js and Supabase.

## Current stage

- Stage: scaffolded application shell
- Product focus: auth, org setup, controls seeding, and first integration flows
- Deployment target: Vercel

## Commands

Use `pnpm` in this repo.

```bash
pnpm install
pnpm dev
pnpm lint
pnpm typecheck
pnpm build
```

## Verification

The current minimal quality gate is intentionally small for the scaffold stage:

- `pnpm install --frozen-lockfile --ignore-scripts`
- `pnpm lint`
- `pnpm typecheck`
- `pnpm build`

The repo-level verify list lives in `.codex/verify.commands`.

## Key docs

- `CLAUDE.md`
- `DISCOVERY-SUMMARY.md`
- `IMPLEMENTATION-ROADMAP.md`
- `RESUMPTION-PROMPT.md`

## Near-term focus

1. Finalize auth and org bootstrap flow.
2. Replace placeholder UI with the first app shell and dashboard skeleton.
3. Add the first automated product tests once the auth and org flows stabilize.
