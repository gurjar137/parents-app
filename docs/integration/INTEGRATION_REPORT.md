# School OS ↔ Parents App — integration repair report (21 Oct 2026)

Replaces the interim summary of 20 Oct. Deployment steps: `DEPLOYMENT_GUIDE.md`. Per-feature status:
`FEATURE_AUDIT_MATRIX.md`. File list: `CHANGELOG.md`.

## Where the work is

| Repository | Path | Branch / base | State |
|---|---|---|---|
| Parents App | `E:\parents app` | `main` @ `8f03a53` | uncommitted. Also contains your own earlier uncommitted UI redesign (home widgets, `test/home_responsive_overflow_test.dart`), which was kept. |
| School OS | `E:\school app` | `repair/school-os-security-persistence` @ `2a1b58b` | uncommitted: 3 Dart files + 3 SQL files + 1 test. `RUN_NOW_02b_07_04.sql` was already there and was not touched. The `claude/relaxed-tesla-a3078c` worktree was not touched. |

Supabase project for both apps: `hnvjenkeimzkdgkuwbeb`.
**The live database was not changed.** Live checks were read-only: column existence probes with
`limit=0`, row *counts* as anonymous (`HEAD`, all 0), and RPC calls with a non-existent code and
random UUIDs.

## Live deployment and verification (20 Oct 2026, project hnvjenkeimzkdgkuwbeb)
Applied by the school owner in the SQL editor: `08`, `07b` (after a fix, commit `c64bb35`) and `08a`
(claim reason fix, commit `5523bd1`).
- `07b` verification query: `anon_can_execute = false` for every listed function. The original
  `get_parent_student_published_results` is in `school_os_repair` with no client access; the public
  wrapper is `authenticated` only.
- `08a` check: `anon_can_execute = false`, `fix_applied = true`.
- External re-probe with the publishable key: `lookup_student_by_parent_access_code` and
  `get_parent_student_attendance` no longer exist; `get_parent_student_published_results`,
  `get_student_attendance_for_parent`, `parent_*` and `record_fee_payment` return 42501 to anonymous
  callers. **The anonymous exposure is closed.**
- `09` (rolled back): **31 / 31 PASS**. Covers claim flow, single claim, rate limit, cross-school
  refusal, staff refusal, payment + server receipt + notification, idempotent retry, overpayment,
  role checks, receipt/fee isolation, direct-read limits, parent notices, notifications and per-user
  read state, absence/homework/results notifications, unlinking, deactivation, anonymous refusal,
  payroll/leave/profile isolation.
- Earlier runs failed only on test fixtures (live CHECK values for `notices.priority` and
  `homework.status`) and revealed one real bug (first claim reported `ALREADY_LINKED`), fixed by `08a`
  and in the app (`d2daa66`).

Still not verified: the end-to-end check with real test accounts in both apps (DEPLOYMENT_GUIDE §6)
and the store releases.

## Production blocker (resolved 20 Oct 2026, see above)
Live on 21 Oct 2026, anonymous callers can execute:
- `lookup_student_by_parent_access_code(p_code)`: returns a student row for a valid code.
- `get_parent_student_attendance(p_student_id)`: attendance for a student id.
- `get_parent_student_published_results(p_access_code, p_student_id)`: results for code + id.

The released Parents App used the first one as its login, so a code alone acted as a password.
The fix is **`07b_EMERGENCY_parent_rpc_lockdown.sql`**, separate from 08 so it can go first. It is
**not applied**. Until it is, do not issue or show Parent Access Codes.

The live bodies of the second and third functions are not in any repository. 07b therefore:
- works from `pg_proc` by name, for every overload, and backs up each definition;
- revokes the first two from `PUBLIC`/`anon`/`authenticated`;
- moves the third to `school_os_repair` and puts a same-signature wrapper in `public`. The wrapper
  requires a signed-in staff member of the student's school, a platform admin, or a linked parent.

## Root causes (Parents App ↔ School OS)
1. **Bearer-code login.** `AuthService.signInWithParentCode` called the anonymous lookup RPC and
   built a "parent" (`P-<student id>`) on the device. There was no Auth session, so RLS never applied.
2. **Wrong tables and columns, errors swallowed.**
   - The app read `parent_notifications`, `parent_devices`, `notice_reads`, `exam_results` and
     `timetable` (none exist live).
   - It read `notices.date`, `notices.class_name`, `notices.student_id` and `homework.student_id`,
     and its fee RPC used `fee_payments.transaction_reference` (none exist).
   - `get_parent_student_fees` is not deployed.
   - Every service caught the error and returned `[]` / a ₹0 ledger, so "no data" and "failed" looked
     the same.
3. **Identity mismatch.** The app compared `parent_students.parent_id` (a `parents.id`) with
   `auth.uid()`. It also upserted into `parents` with columns that don't exist (`name`,
   `relationship`, `avatar_url`).
4. **Invented data.**
   - A demo data file (St. Xavier, "Rajesh Sharma") and Unsplash photos.
   - Defaults: house "Ruby House", class teacher "Mrs. Sunita Sharma", class strength 34, grade "A",
     "Good performance.", PASS/FAIL at 40%.
   - A hardcoded session list, and attendance shown as 100% when nothing was recorded.
   - Fake receipt numbers (`REC-<now>`), plus fake "Downloading…/Sharing…/Printing…" toasts.
5. **Local-only actions shown as saved.** Homework "Mark as completed", correction requests,
   notification preferences, "Mark all read", and a fake FCM token written to a non-existent table.
6. **School OS fee collection was not atomic.**
   - The receipt number came from a client timestamp and the payment insert had no idempotency key.
   - The balance check ran on the client, and the status update was a separate request.
   - No parent was notified.
   - "Paid" counted the student's payments from all sessions.
7. **Parent RLS gaps for tables without `student_id`.** A parent-role account could read staff-only
   notices, every notification broadcast, other profiles and payroll rows through the school-wide
   policies (06 only covered student-scoped tables).

## What was changed
**Database (pending deployment)**
- **`07b`**: emergency lockdown, described above.
- **`08`**:
  - **Child linking:** `parent_claim_child` adopts the school-created `parents` row (single claim per
    code, rate limited) and never reactivates a disabled record.
  - **Read RPCs:** `parent_get_session/school/fees/receipt/homework/timetable/exam_schedule/results/notices/notifications`,
    plus `parent_mark_notifications_read`, `parent_mark_notice_read` and `parent_update_contact`.
    Every one checks `is_linked_parent_of` (06) on the server.
  - **Payments:** `record_fee_payment` locks the fee account, checks idempotency and balance, issues
    the receipt number per school and year, updates the status and notifies parents, all in one
    transaction.
  - **Notifications:** triggers for absence, homework and published results; deduplicated through
    `notifications.dedupe_key`.
  - **Parent-role lockdown:** restrictive policies on 22 staff/school tables, plus own-row-only on
    `profiles` and `parents`.
  - **Constraints:** unique indexes, created only when no duplicates exist (otherwise a NOTICE).
  - **Cleanup:** removes the legacy anonymous functions and Parents App policies, with backups.
- **`09`**: 31 rolled-back live checks (T1–T30) (two schools, three parents, admin, teacher, anonymous).
- **Parents App** `supabase/migrations/*` moved to `supabase/legacy_do_not_run/` with a README: they
  are unsafe (anonymous attendance policy, anonymous lookup, invented defaults).

**School OS**
- `FeeService.recordPayment` calls `record_fee_payment`. It falls back to the old path only when the
  function is missing, so the School OS can ship before 08.
- `receiptFromRecordPaymentResult` refuses to build a receipt without a persisted payment id and
  receipt number.
- Each payment dialog creates one idempotency key while it's open (`admin_fee_management_screen`,
  `student_profile_screen`).
- "Paid" counts only that fee account (plus legacy rows from the same session).

**Parents App**
- **Data access:** `ParentApi` is a single RPC gateway with typed errors; database text never reaches
  the screen. All 10 services were rewritten on top of it.
- **Session:** comes from the server. Children can't be selected unless the server returned them,
  late responses are discarded per child, and a 42501 re-reads the session.
- **Screens:** loading, error and empty states are separate; empty image URLs no longer crash.
- **Unsupported features:** marked "not available yet" instead of fake content.
- **Receipts:** loaded from the server, with Copy instead of fake PDF actions.

## Fee and receipt chain (what is enforced where)
School OS dialog (one idempotency key) → `record_fee_payment` (school role check; the fee account row
is locked; same key returns the stored payment, a different amount with the same key is refused;
amount > 0, ≤ balance, date not in the future) → one `fee_payments` row with server receipt
`RCT-YYYY-NNNNNN` (counter per school/year; collision loop; unique index) → `student_fee_accounts.status`
→ notification per linked active parent (`dedupe_key fee_payment:<id>:<student>:<user>`) → Parents App
`parent_get_fees` (server totals) and `parent_get_receipt` (built from stored rows; other families get
42501).
A failed insert rolls back the counter and the notification, so no receipt can exist for a failed
payment. If only the notification fails, the payment is kept and `parents_notified = 0` /
`notify_error` is returned to the caller.
There are no payment-allocation or ledger tables live (probed: `PGRST205`), and `fee_payments` has no
status column, so there are no pending/failed/refunded states: every row is a recorded collection.
**Not live verified.** 09 T11–T17 cover this chain once 08 is deployed.

## Test evidence (this machine, Flutter 3.38.9, 21 Oct 2026)
| What | Result |
|---|---|
| Parents App `flutter analyze` | 0 errors, 0 warnings, 6 info (`unnecessary_underscores`) |
| Parents App `flutter test` (all 10 files) | **69 passed, 0 failed** |
| Parents App `flutter build web` | built |
| Parents App `flutter build apk --debug` | built (`build/app/outputs/flutter-apk/app-debug.apk`) |
| School OS `flutter analyze lib` | 0 errors, 0 warnings |
| School OS offline tests (49 files: the 48 that never initialise Supabase + new `record_fee_payment_receipt_test.dart`) | **404 passed, 1 skipped, 0 failed** |
| School OS live-database tests (27 files) | **not run**: they sign in with real credentials, and `seed_10k_dataset_test` writes data |
| School OS `flutter build web` | built |
| SQL 07b / 08 / 09 | parsed by libpg_query 18: every statement, every PL/pgSQL body and DO block (a broken control was detected). **Not executed**: no PostgreSQL or database credentials here |
| Live `09` run, end-to-end with test accounts | **not done** |

Old Parents App tests that were rewritten because the behaviour they asserted was removed on purpose:
- `widget_test.dart` and `parent_identity_security_regression_test.dart`: code-only login, swallowed
  errors.
- `parent_attendance_live_test.dart`: anonymous network reads.
- `parent_fee_live_test.dart` (deleted): `FeeSummaryModel.fromData` and anonymous reads. Replaced by
  `fees_and_receipts_test.dart`.

## Status summary
- **Fixed in code:**
  - removed the bearer-code login, invented data and fake actions;
  - the authenticated session and child-linking client;
  - error/empty separation and per-child isolation;
  - School OS idempotent fee recording and paid-sum consistency;
  - parent-safe RPCs and RLS (as SQL).
- **Locally tested:** the Parents App (69 tests) and School OS offline tests (404 passed, 1 skipped),
  web builds of both apps, the Parents App debug APK, SQL parse checks.
- **Pending migration:** 07b (urgent), then 08 and the 09 run. Also still pending from before: 02b, 07.
- **Live verified:** only the read-only facts above (06 deployed; anonymous RPC exposure; missing
  tables and columns). Nothing integration-related.
- **Pending external configuration:** Firebase/FCM project and server key, payment gateway, Auth Site
  URL for reset emails, test accounts for 09 and the end-to-end check, App Store/Play release.
- **Not implemented:** push notifications, PDF receipts, gateway/refunds, parent meetings,
  messaging, transport, calendar, documents, correction requests, homework submissions, grades.
- **Blocked:** guardians with children in two schools (one profile = one school; needs a product
  decision and an identity-model change).
