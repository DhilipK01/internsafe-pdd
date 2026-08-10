# INTERNSAFE D1 migrations

## Apply (local dev)

```bash
cd api
npm run db:migrate:local
```

## Apply (production remote)

```bash
npm run db:migrate
```

## Rollback indexes only

```bash
npm run db:rollback:local
```

## Full schema rollback (destructive)

```bash
npm run db:rollback:schema:local
```

## Tables

`users`, `user_settings`, `uploaded_files`, `companies`, `blacklist_reports`, `report_evidence`, `verification_results`, `fraud_patterns`, `resumes`, `offer_checks`, `scans`, `scan_findings`, `company_searches`, `notifications`, `activity_logs`, `saved_reports`, `data_safety_checks`

Danger/trust scores on `companies` are updated by SQL triggers when reports are inserted.
