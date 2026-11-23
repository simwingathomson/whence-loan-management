# WHENCE Loan Management System

WHENCE is a no-login loan operations dashboard for clients, loans, installment repayments, collections, notifications, and audit records.

## Technology

- Next.js server-side routes and dashboard
- Neon Serverless PostgreSQL
- Prisma ORM and Prisma Client
- `@neondatabase/serverless` for Neon-specific server-side access where Prisma is not suitable

Supabase is not used for authentication, data, storage, or any other feature.

## Development

1. Copy `.env.example` to `.env` and add your Neon URLs.
2. Run `npm install`.
3. Run `npm run db:migrate` and optionally `npm run db:seed`.
4. Run `npm run dev`.

See [DATABASE_SETUP.md](./DATABASE_SETUP.md) for Neon provisioning, migrations, Vercel variables, deployment, production connection checks, and daily Vercel Cron notifications.

## Payment APIs

- `POST /api/payments` records a payment and allocates it across outstanding installments.
- `PUT /api/payments/:id` edits a posted payment and fully recalculates allocations and balances.
- `POST /api/payments/:id/reverse` reverses a payment and recalculates balances.

Each operation is one database transaction, uses decimal amounts, enforces unique payment references, excludes reversed payments from collections, and writes an audit record.
