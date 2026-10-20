# Changelog — Parents App integration (20–21 Oct 2026)

Nothing is committed. Bases: Parents App `main` @ `8f03a53`, School OS
`repair/school-os-security-persistence` @ `2a1b58b`.

## School OS (`E:\school app`)
| File | Change |
|---|---|
| `database_repair/07b_EMERGENCY_parent_rpc_lockdown.sql` | **new.** Revokes the anonymous student lookup and attendance functions; wraps `get_parent_student_published_results` with a staff-or-linked-parent check; ends with a verification query. |
| `database_repair/08_parents_app_integration.sql` | **new.** Parent claim flow, parent read RPCs, `record_fee_payment`, notification triggers, parent-role restrictive policies, guarded unique indexes, legacy cleanup with backups. |
| `database_repair/09_parents_integration_tests_rolled_back.sql` | **new.** 31 rolled-back checks (T1–T30) on two throw-away schools. |
| `lib/data/services/fee_service.dart` | `recordPayment(idempotencyKey:)` calls `record_fee_payment`, with a legacy fallback only for PGRST202/42883. New `receiptFromRecordPaymentResult`. `getStudentFeeAccount` paid sum = this account plus same-session legacy rows. |
| `lib/features/fees/admin_fee_management_screen.dart` | One `paymentRequestKey` per payment dialog, passed to `recordPayment`. |
| `lib/features/students/student_profile_screen.dart` | Same. |
| `test/record_fee_payment_receipt_test.dart` | **new.** The receipt comes only from the persisted RPC result; a retried request returns the same receipt; there is no receipt without a payment id or receipt number. |

Database objects added by 07b/08 (pending deployment):
- **Functions:**
  - parent reads and actions: `parent_student_ids`, `parent_claim_child`, `parent_get_session`,
    `parent_get_school`, `parent_get_fees`, `parent_get_receipt`, `parent_get_homework`,
    `parent_get_timetable`, `parent_get_exam_schedule`, `parent_get_results`, `parent_get_notices`,
    `parent_get_notifications`, `parent_mark_notifications_read`, `parent_mark_notice_read`,
    `parent_update_contact`;
  - staff: `record_fee_payment`;
  - triggers: `parent_notify_attendance_trg`, `parent_notify_homework_trg`, `parent_notify_results_trg`;
  - internal helpers in `school_os_repair.*`: `norm_class`, `student_name`, `assert_linked_parent`,
    `assert_may_read_student`, `notify_parents_of_student`, `fee_account_paid`, `fee_account_json`,
    `fee_receipt_json`, `parent_visible_notification_ids`.
- **Tables:** `school_os_repair.parent_link_attempts`, `parent_code_claims`, `fee_receipt_counters`.
- **Columns:** `notifications.student_id`, `notifications.dedupe_key`, `fee_payments.idempotency_key`.
- **Indexes:** `uq_notifications_dedupe_key`, `uq_fee_payments_idempotency`, `uq_fee_payments_receipt`*,
  `uq_parent_students_pair`*, `uq_students_parent_access_code`* (* only when no duplicates exist).
- **Triggers:** `trg_parent_notify_attendance`, `trg_parent_notify_homework`, `trg_parent_notify_results`.
- **Policies:** `<table>_parent_role_restrict` on 22 tables, `profiles_parent_role_restrict`,
  `parents_parent_role_restrict`.
- **Removed (backed up):** `lookup_student_by_parent_access_code`, `get_parent_student_attendance`,
  `get_parent_student_fees`, and the policies from the Parents App's own migrations.

## Parent Code sign-in (21 Oct 2026)
- School OS: `database_repair/10_parent_code_login.sql`, `11_parent_code_login_tests_rolled_back.sql`,
  `supabase/functions/parent-code-login/{index.ts,login.ts,login_test.ts,README.md}` (new).
- Parents App: `AuthService.signInWithParentCode` (Edge Function + `verifyOTP`),
  `ParentAppProvider.loginWithParentCode`, code-only `ParentLoginScreen`; parent profile hides password,
  synthetic email and the inert biometric switch; `parent_signup_screen.dart` and
  `forgot_password_screen.dart` deleted (unreachable); tests in `auth_and_linking_test.dart` and
  `parent_identity_security_regression_test.dart`.

## Parents App (`E:\parents app`)
**New**
- `lib/core/services/parent_api.dart`: RPC gateway, `ParentDataException`, error mapping.
- `lib/presentation/widgets/load_state_view.dart`: loading, error or content.
- `test/support/fake_parent_api.dart`, `test/parent_api_test.dart`, `test/auth_and_linking_test.dart`,
  `test/fees_and_receipts_test.dart`, `test/provider_isolation_test.dart`.
- `supabase/legacy_do_not_run/README_DO_NOT_RUN.md`.
- `docs/integration/*`: this changelog, the report, the matrix and the deployment guide.

**Rewritten**
- **Services:** `auth_service.dart` (email/password plus `ParentSession`; no code login),
  `link_child_service.dart` (`parent_claim_child`), `fee_service.dart`, `attendance_service.dart`,
  `homework_service.dart`, `timetable_service.dart`, `result_service.dart` (adds the exam schedule),
  `notice_service.dart`, `notification_service.dart` (no fake FCM token), `school_service.dart`.
- **Provider:** `lib/providers/parent_app_provider.dart`. The session comes from the server; loads
  are guarded per child; errors are kept apart from empty lists; marking read is server-first; real
  refresh; no mock data.
- **Models:** `fee_model.dart` (server totals, `FeeReceiptModel`), `student_model.dart`
  (`fromSession`, no invented fields), `homework_model.dart`, `result_model.dart` (no grades or
  remarks invented), `exam_model.dart` (schedule), `timetable_model.dart`, `notice_model.dart`,
  `notification_model.dart`. Edited: `attendance_model.dart` (0% plus `hasRecords` when nothing is
  marked), `school_brand_model.dart`, `parent_model.dart`.
- **Screens:**
  - **Auth:** login (email only, root decides navigation), signup, link child (sign out on first
    setup).
  - **Fees and receipts:** loading/error states and nullable fields on the fees screen; the receipt
    screen loads from the server.
  - **Results:** results (real sessions, marks only) and report card (no invented grade, remark or
    stamp).
  - **Other data screens:** exams (load states, nullable dates); attendance, homework, timetable,
    notices (gating; attendance shows no fake %); notifications (Mark all read, honest info sheet,
    no navigation for general messages); homework detail (read-only; attachment link copied); notice
    detail (attachment link copied).
  - **Not-available features:** documents, messages, calendar, PTM and transport screens now say
    "not available yet".
  - **Profiles and home:** child profile, parent profile (save reports failure), class info, more,
    home (no grade text, no fake pending count).
  - **Widgets:** `pdf_preview_modal.dart` (only wired actions), `correction_request_dialog.dart` (no
    false "submitted"), `child_selector_sheet.dart`.
- **Tests:** `widget_test.dart`, `parent_identity_security_regression_test.dart` and
  `parent_attendance_live_test.dart` rewritten for the authenticated flow;
  `home_responsive_overflow_test.dart` seeds a verified session.

**Removed or moved**
- `lib/data/mock/mock_data.dart`: deleted.
- `test/parent_fee_live_test.dart`: deleted (superseded).
- `supabase/migrations/*.sql` → `supabase/legacy_do_not_run/`.

**Your earlier uncommitted work, preserved and not authored here:**
- `lib/core/theme/app_colors.dart`, `lib/presentation/main_navigation_screen.dart`,
  `lib/presentation/widgets/animated_card.dart`, `offline_banner.dart`, `custom_app_bar.dart`.
- The untracked widgets `child_profile_hero_card.dart`, `custom_bottom_nav_bar.dart`,
  `quick_access_grid.dart`, `staggered_entrance.dart`, `todays_academic_overview.dart`.
- The original version of `test/home_responsive_overflow_test.dart`.
- Most of `home_screen.dart` (three small integration edits on top).

These are committed separately as `697650a Redesign Parents App home dashboard`; the integration
commit follows it. The Parents App patch (`parents_app_vs_8f03a53.patch`) covers both commits.
