# Neon and Vercel setup

WHENCE uses Neon Serverless PostgreSQL as its only database. Prisma Client is used only in server-side Next.js code; credentials never enter client bundles.

## Create the Neon database

1. Create a project in [Neon](https://console.neon.tech/) and choose the production branch.
2. Open **Connect** and copy the pooled connection string. Its host contains `-pooler`; set it as `DATABASE_URL`.
3. Copy the direct connection string from the same dialog; set it as `DIRECT_URL`.
4. Keep `sslmode=require` in both URLs.

## Configure local development

1. Copy `.env.example` to `.env`.
2. Set `DATABASE_URL` to the pooled URL and `DIRECT_URL` to the direct URL. `.env` is gitignored.
3. Set a long random `CRON_SECRET`.
4. Run `npm install`, `npm run db:generate`, and `npm run db:migrate`.
5. Run `npm run db:seed` for optional demonstration data.

`DATABASE_URL` handles application queries. Prisma uses `DIRECT_URL` when it applies migrations.

## Configure Vercel and deploy

1. Import the repository into Vercel or run `vercel` from this directory.
2. In **Project Settings → Environment Variables**, add `DATABASE_URL`, `DIRECT_URL`, and `CRON_SECRET` for Production, Preview, and Development as needed.
3. Run `npx prisma migrate deploy` with the production variables before the production deployment.
4. Deploy the application. The build runs `prisma generate` before `next build`.
5. Open `/` on the production URL. A working dashboard with database counts confirms the server-side Neon connection.

## Daily notifications

`vercel.json` schedules `GET /api/cron/notifications` every day at 06:00 UTC. Vercel supplies `Authorization: Bearer <CRON_SECRET>` for the production cron invocation. Set the same value in Vercel and never expose it to the browser.

The cron route marks due notifications as sent. Connect a chosen SMS or email provider inside that server route when a delivery provider is selected.
