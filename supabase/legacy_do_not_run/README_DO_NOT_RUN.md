# Do not run these SQL files

They are kept only as a record. Each one is unsafe on the shared School OS database
(project `hnvjenkeimzkdgkuwbeb`):

| File | Problem |
|---|---|
| `20260901_parent_security_audit_hardening.sql` | Redefines `get_user_school_id()` / `get_user_role()` (overwrites the School OS identity helpers from `01`), compares `parent_students.parent_id` (a `parents.id`) with `auth.uid()`, and targets tables that do not exist. |
| `20260903_lookup_student_by_parent_access_code.sql` | Lets **anonymous** callers read a student by access code, and fills missing values with invented names ("Rajesh Sharma", "Mr. Rahul Singh", school `SCH-STX-2026`). |
| `20260904_parent_attendance_rpc.sql` | Adds an attendance policy `TO anon` that exposes every student's attendance, and an anonymous attendance RPC. |
| `20260906_get_parent_student_fees.sql` | Returns any student's fees to anonymous callers when no code is passed, and reads a column (`transaction_reference`) that does not exist. |

The Parents App now uses only the authenticated RPCs defined in the School OS
repository: `database_repair/07b_EMERGENCY_parent_rpc_lockdown.sql`,
`06_parent_linked_access.sql` and `08_parents_app_integration.sql`.
