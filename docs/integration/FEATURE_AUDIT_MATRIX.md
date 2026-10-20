# Parents App ↔ School OS — feature integration matrix (21 Oct 2026)

Statuses: **CODE TESTED** = covered by offline unit/widget tests (fake RPC gateway, no database) ·
**PENDING MIGRATION** = needs `07b`/`08` deployed · **NOT VERIFIED (LIVE)** = never exercised against the
live database with signed-in users · **NOT IMPLEMENTED** · **PENDING CONFIG** · **BLOCKED**.

No feature is LIVE VERIFIED: `07b`, `08` and `09` have not been run on the database (no database
credentials in this environment). The SQL was checked by the PostgreSQL parser (libpg_query 18) only,
which does not prove the column names or semantics against the live schema.

| # | Feature | School OS side | Parents App side | Authoritative data / RPC | Authorization (server) | Status |
|---|---|---|---|---|---|---|
| 1 | Parent sign-up / sign-in | — | `ParentLoginScreen`, `ParentSignupScreen` → Supabase Auth email/password | `auth.users` | Auth; no metadata grants anything (01) | CODE TESTED (validation) · NOT VERIFIED (LIVE) |
| 2 | Code-only "login" | — | **removed** | — | — | FIXED (was a bearer-code hole) |
| 3 | Anonymous student lookup by code / attendance / results | — | no longer called | `lookup_student_by_parent_access_code`, `get_parent_student_attendance`, `get_parent_student_published_results` | 07b revokes / wraps | **BLOCKER until 07b is applied** (live probe: still anon-callable) |
| 4 | Issue / regenerate / revoke access code | Parent Access screens (`AccessService`, `ParentService.enableParentAccessForStudent`) | — | `students.parent_access_code`, school-created `parents` + `parent_students` | admin RLS (01/02) | existing · NOT VERIFIED (LIVE) |
| 5 | Link child with code | — | `LinkChildScreen` → `parent_claim_child` | adopts the school-created `parents` row; `parent_students`; `school_os_repair.parent_code_claims` | signed in; code valid & unique; one claim per code; same school; not staff; active; 5 failures/15 min per account, 300 global | CODE TESTED · PENDING MIGRATION (08) · 09 T1–T10 |
| 6 | Session / child list / restart | — | `ParentAppProvider` → `parent_get_session` | profiles + parents + parent_students | `parent_student_ids()` (active parent, same school) | CODE TESTED · PENDING MIGRATION |
| 7 | Multiple children, switching | — | child selector; per-child load token | — | per RPC | CODE TESTED (stale response discarded) |
| 8 | Revoke link / deactivate parent | unlink in Parents module; Disable access sets parent INACTIVE | session re-read on 42501 | `parent_students`, `parents.status` | `is_linked_parent_of` (06) | CODE TESTED · 09 T24, T27 |
| 9 | Fee ledger | Fee management | `FeesScreen` → `parent_get_fees` | `student_fee_accounts` + `fee_payments` (no allocation/ledger tables exist live) | linked parent | CODE TESTED · PENDING MIGRATION · 09 T16 |
| 10 | Record payment | `FeeService.recordPayment` → `record_fee_payment` with per-dialog idempotency key | — | `fee_payments` (server receipt `RCT-YYYY-NNNNNN`), account status | owner/admin/principal/accountant of the student's school | CODE TESTED (receipt mapping) · PENDING MIGRATION · 09 T11–T15 |
| 11 | Receipt | receipt dialog from RPC result | `ReceiptDetailScreen` → `parent_get_receipt`; Copy details | persisted payment + student + school rows | linked parent only | CODE TESTED · 09 T16–T17 |
| 12 | Receipt PDF download / print | — | button removed; text explains | — | — | NOT IMPLEMENTED (needs `pdf`/`printing` packages — dependency decision) |
| 13 | Payment gateway / refunds | — | — | `fee_payments` has no status column | — | NOT IMPLEMENTED (needs provider credentials + webhook design) |
| 14 | Attendance month / today | Mark attendance | `AttendanceScreen` → `get_student_attendance_for_parent` (06, deployed) | `attendance` | linked parent / staff | CODE TESTED · 06 deployed · NOT VERIFIED (LIVE) |
| 15 | Absence notification | trigger on `attendance` | Notifications | `notifications` (dedupe_key) | trigger, linked active parents only | PENDING MIGRATION · 09 T21 |
| 16 | Homework (read-only) | Create homework | `HomeworkScreen` → `parent_get_homework` | `homework` (class/section/session match, not draft) | linked parent | CODE TESTED · PENDING MIGRATION · 09 T22 |
| 17 | Homework attachments | none stored (no column) | link copy only when a URL exists | — | — | NOT IMPLEMENTED in School OS |
| 18 | Homework completion / submission | — | "Mark as completed" removed | no submissions table | — | NOT IMPLEMENTED (product decision) |
| 19 | Timetable | Timetable management (PUBLISHED) | `TimetableScreen` → `parent_get_timetable` | `timetable_entries` via `classes`/`sections` names | linked parent | CODE TESTED (model) · PENDING MIGRATION |
| 20 | Exam schedule | Create exam | `ExamsScreen` → `parent_get_exam_schedule` | `exams`, `exam_classes`, `exam_subjects` | linked parent | CODE TESTED (model) · PENDING MIGRATION |
| 21 | Published results / marks summary | Enter marks, publish (`result_status`) | `ResultsScreen`, `ReportCardScreen` → `parent_get_results` | `marks` + `exam_subjects`; only `result_status = PUBLISHED` | linked parent | CODE TESTED · PENDING MIGRATION · 09 T23 |
| 22 | Grades / overall remarks / official report card | — | invented "Grade A" / "Good performance" removed | not stored | — | NOT IMPLEMENTED (no grade scale stored) |
| 23 | Notices for parents | Notices (audience Parents/Everyone, Published) | `NoticesScreen` → `parent_get_notices`; read via `parent_mark_notice_read` | `notices` | linked parent; staff-only notices excluded; direct table read denied (08 restrictive) | CODE TESTED · PENDING MIGRATION · 09 T18–T19 |
| 24 | Notification center, read / mark all read | broadcasts on notice publish; RPC/trigger rows | `NotificationsScreen` → `parent_get_notifications`, `parent_mark_notifications_read` | `notifications`, `notification_reads` (per user) | own rows + parent-audience broadcasts of own school; child rows need a current link | CODE TESTED · PENDING MIGRATION · 09 T20, T30 |
| 25 | Results notification | trigger on `exams.result_status` | Notifications | `notifications` | trigger | PENDING MIGRATION · 09 T23 |
| 26 | Homework notification | trigger on `homework` insert | Notifications | `notifications` | trigger | PENDING MIGRATION · 09 T22 |
| 27 | Phone push (FCM) | — | fake token registration removed; info sheet says in-app only | — | — | PENDING CONFIG / NOT IMPLEMENTED (no Firebase project files, no sender) |
| 28 | Notification preferences | — | inert switches removed | — | — | NOT IMPLEMENTED |
| 29 | School info / branding | School configuration | `parent_get_school` | `schools` (+ current session) | linked parent | CODE TESTED · PENDING MIGRATION |
| 30 | Parent profile edit | — | `parent_update_contact` | `profiles`, `parents` (own rows) | parent role, own rows | PENDING MIGRATION · 09 T26 |
| 31 | Password change / reset | — | Supabase Auth | `auth.users` | Auth | CODE TESTED (validation) · reset email needs Site URL |
| 32 | Parent meetings / PTM | Meetings audience is staff-only | screen says not available | `events` (staff) | — | NOT IMPLEMENTED (needs parent audience in School OS) |
| 33 | Messaging | — | screen says not available | — | — | NOT IMPLEMENTED (product decision) |
| 34 | Transport | `transport_routes` only | screen says not available | no student↔route link | — | NOT IMPLEMENTED (data model) |
| 35 | Calendar / holidays | none | screen says not available | no table | — | NOT IMPLEMENTED |
| 36 | Documents | none | screen says not available | no table | — | NOT IMPLEMENTED |
| 37 | Correction requests | none | dialog says it cannot be sent | no table | — | NOT IMPLEMENTED |
| 38 | Assistant (rule-based) | — | answers only from loaded school data | — | — | CODE TESTED (indirectly) |
| 39 | Guardian with children in two schools | — | one account per school (message `OTHER_SCHOOL`) | a profile has one school (01) | — | BLOCKED by identity model (product decision) |
| 40 | Parent direct table access | — | not used | — | 08 restrictive: no staff tables, own profile/parent row only | PENDING MIGRATION · 09 T18, T25, T29 |
| 41 | Unauthenticated access to parent RPCs | — | — | — | all parent RPCs `authenticated` only | PENDING MIGRATION · 09 T28 |
