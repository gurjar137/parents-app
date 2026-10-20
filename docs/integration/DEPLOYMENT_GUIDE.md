# Deployment guide — School OS ↔ Parents App integration

Target project: **`hnvjenkeimzkdgkuwbeb`** (the only project in both apps' configuration:
`E:\parents app\lib\core\config\supabase_config.dart` and `E:\school app\dart_define.json`).
Run SQL only in the SQL editor of that project. Stop if the dashboard shows any other reference.

> **Production blocker (live, 20 Oct 2026):** anonymous callers can still run
> `lookup_student_by_parent_access_code`, `get_parent_student_attendance` and
> `get_parent_student_published_results`. Until step 2 is applied and verified, **do not hand out or
> display Parent Access Codes**, and treat any code already issued as exposing that student's details.

## 1. Backup and target check
1. Dashboard → Database → Backups: take/confirm a backup (or `pg_dump` with the project's connection
   string, kept off the repository).
2. In the SQL editor run `select current_database(), now();` and confirm the browser URL contains
   `hnvjenkeimzkdgkuwbeb`.
3. Confirm the prerequisites are deployed (read-only):
   ```sql
   select to_regprocedure('public.current_profile_row()')        is not null as has_01,
          to_regprocedure('public.is_linked_parent_of(uuid)')     is not null as has_06,
          to_regclass('public.notification_reads')                is not null as has_02_reads,
          to_regclass('public.teacher_assignments')               is not null as has_07;
   ```
   `has_01`, `has_06`, `has_02_reads` must be true. `has_07` false means 02b/07 are still pending
   (they are independent of the parent work, see `REPAIR_REPORT.md`).

## 2. Emergency fix — `database_repair/07b_EMERGENCY_parent_rpc_lockdown.sql`
- Run the whole file. It is one transaction and ends with a verification query.
- Expected verification: every row `anon_can_execute = false`.
  `get_parent_student_published_results` shows `authenticated_can_execute = true` (it is now a wrapper
  that requires staff of the student's school or a linked parent).
- Re-check from outside with the publishable key (no rows can be returned):
  ```bash
  curl -s -X POST -H "apikey: <publishable key>" -H "Content-Type: application/json" -d '{"p_code":"ZZZ-NOT-A-CODE"}' https://hnvjenkeimzkdgkuwbeb.supabase.co/rest/v1/rpc/lookup_student_by_parent_access_code
  ```
  Expected: `permission denied for function ...` (42501), not `[]`.
- Effect: the **currently released** Parents App (code-only login) stops working. Intended.
- Rollback: each original definition is in `school_os_repair.function_backup` (script `07b`);
  `get_parent_student_published_results` original is in schema `school_os_repair`.

## 3. Integration migration — `database_repair/08_parents_app_integration.sql`
Run after 07b (08 alone also removes the anonymous functions, but deploy 07b first so the exposure is
closed even if 08 has to be postponed). One transaction; stops with a clear message if 01/02/06 are
missing. NOTICES about duplicate receipt numbers / links / access codes mean the corresponding unique
index was **not** created — resolve those rows (see `05_READ_ONLY_data_integrity_report.sql`) and rerun.

## 4. Verification — `database_repair/09_parents_integration_tests_rolled_back.sql`
Run the whole file. All fixtures (two `ZZ Parent Test School` schools, `@example.invalid` users,
payments, notices …) are created inside a block that ends with a forced rollback; nothing persists.
Every row must be `PASS`. A `HARNESS ERROR` row means a fixture insert failed on this schema (usually a
NOT NULL column the script does not know) — fix the fixture, never the assertion.
Afterwards confirm nothing remained:
```sql
select count(*) from public.schools where name like 'ZZ Parent Test School%';   -- 0
select count(*) from auth.users where email like 'zz-pi-%@example.invalid';      -- 0
```

## 5. Tests and builds (local)
```bash
cd "E:/parents app" && flutter analyze && flutter test && flutter build web && flutter build apk --release
```
```bash
cd "E:/school app" && flutter analyze lib && flutter build web
```
School OS tests: run the offline files only (the live ones write to the database); see the list in
`INTEGRATION_REPORT.md` §Test evidence.

## 6. End-to-end check with test accounts (not real families)
1. School OS (admin of a test school): Students → a test student → Parent Access → enable; note the code.
2. Parents App: Create account (email/password) → verify email if required → sign in → Link child with
   the code. Expect the child and school name.
3. School OS: record a fee payment for that student (Fees → Record payment). Note the `RCT-…` number.
   Press the button twice / retry after a timeout: one payment only.
4. Parents App: pull to refresh on Fees → the payment and balance; open the receipt → same number,
   amount, date. Notifications → "Fee payment recorded". Sign out / in → still there.
5. Mark the student absent today in School OS → parent notification. Publish homework for the class,
   publish results of an exam with marks → both visible and notified.
6. Second parent account in another test school: cannot link the code (`ALREADY_CLAIMED`/`OTHER_SCHOOL`),
   sees none of the first child's data.
7. School OS: unlink the parent (Parents → student link → remove). Parents App refresh → child gone.

## 7. Release order
1. 07b (now). 2. 08 + 09 PASS. 3. School OS build with the `record_fee_payment` change (works before
and after 08: it falls back to the old path only when the function is missing). 4. Parents App build
(requires 08; before 08 every screen shows "not yet enabled on your school's server").
5. Remove the old Parents App build from stores / devices.

## 8. Follow-up checks (read-only, a day after release)
```sql
-- no anon execution on parent functions
select p.oid::regprocedure, has_function_privilege('anon', p.oid, 'EXECUTE')
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and (p.proname like 'parent_%' or p.proname like 'get_%parent%' or p.proname = 'record_fee_payment');
-- payments recorded through the RPC have a server receipt number and no duplicate keys
select count(*) filter (where receipt_number like 'RCT-%') as rpc_payments,
       count(*) - count(distinct (school_id, idempotency_key)) filter (where idempotency_key is not null) as dup_keys
from public.fee_payments;
-- claims and failed attempts
select success, count(*) from school_os_repair.parent_link_attempts where attempted_at > now() - interval '1 day' group by 1;
```

## Secrets / configuration
- Flutter apps contain only the publishable key. No service-role key is needed for any of this.
- Supabase Auth: email sign-up must stay **enabled** for parents (accounts get no access until a code is
  redeemed). Set the Site URL / redirect URL for password-reset emails to a page you control.
- Not configured (and not required for the in-app flow): Firebase/FCM, payment gateway.
