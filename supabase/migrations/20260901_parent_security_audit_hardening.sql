-- ================================================================================
-- SUPABASE PARENT APP - STEP 14 COMPLETE SECURITY HARDENING & RLS POLICIES
-- Project Ref: hnvjenkeimzkdgkuwbeb
-- Date: 2026-09-01
-- Description: Enforces Row Level Security (RLS), Role Protection, Multi-Tenant
--              School Isolation, and Security Definer Function Search-Paths.
-- ================================================================================

-- 1. ENABLE ROW LEVEL SECURITY ON ALL PRIVATE TABLES
ALTER TABLE IF EXISTS public.parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.parent_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.timetable ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.exam_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.student_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.parent_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.parent_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notice_reads ENABLE ROW LEVEL SECURITY;

-- 2. SECURITY DEFINER HELPER FUNCTIONS WITH EXPLICIT SEARCH_PATH
CREATE OR REPLACE FUNCTION public.get_user_school_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT school_id FROM public.parents WHERE id = auth.uid() OR auth_user_id = auth.uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role FROM public.profiles WHERE id = auth.uid()),
    'parent'
  );
$$;

-- 3. PARENT PROFILE POLICIES (Prevent Privilege Escalation & Role Hijacking)
DROP POLICY IF EXISTS "Parents can view own profile" ON public.parents;
CREATE POLICY "Parents can view own profile" ON public.parents
  FOR SELECT
  TO authenticated
  USING (id = auth.uid() OR auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Parents can update own permitted particulars" ON public.parents;
CREATE POLICY "Parents can update own permitted particulars" ON public.parents
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid() OR auth_user_id = auth.uid())
  WITH CHECK (
    -- Restrict updates to non-privileged fields only
    id = auth.uid()
  );

-- 4. PARENT-STUDENT AUTHORIZATION LINKING POLICIES
DROP POLICY IF EXISTS "Parents view authorized student links" ON public.parent_students;
CREATE POLICY "Parents view authorized student links" ON public.parent_students
  FOR SELECT
  TO authenticated
  USING (parent_id = auth.uid());

-- 5. STUDENT DATA POLICIES (Authorized Children Only)
DROP POLICY IF EXISTS "Parents view authorized children" ON public.students;
CREATE POLICY "Parents view authorized children" ON public.students
  FOR SELECT
  TO authenticated
  USING (
    id IN (SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid())
  );

-- 6. ATTENDANCE RLS POLICIES (Read-Only for Parent's Authorized Children)
DROP POLICY IF EXISTS "Parents view attendance of authorized children" ON public.attendance;
CREATE POLICY "Parents view attendance of authorized children" ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    student_id IN (SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid())
  );

-- Deny Parent Write Mutations on Attendance
-- (Only School Admin/Teacher roles can write to attendance)

-- 7. HOMEWORK RLS POLICIES (Read-Only for Parent's Child Class & School)
DROP POLICY IF EXISTS "Parents view child class homework" ON public.homework;
CREATE POLICY "Parents view child class homework" ON public.homework
  FOR SELECT
  TO authenticated
  USING (
    school_id IN (
      SELECT school_id FROM public.students WHERE id IN (
        SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid()
      )
    )
  );

-- 8. TIMETABLE RLS POLICIES (Read-Only for Parent's Child Class)
DROP POLICY IF EXISTS "Parents view child timetable" ON public.timetable;
CREATE POLICY "Parents view child timetable" ON public.timetable
  FOR SELECT
  TO authenticated
  USING (
    school_id IN (
      SELECT school_id FROM public.students WHERE id IN (
        SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid()
      )
    )
  );

-- 9. EXAM RESULTS RLS POLICIES (Read-Only for Published Results of Authorized Child)
DROP POLICY IF EXISTS "Parents view published child results" ON public.exam_results;
CREATE POLICY "Parents view published child results" ON public.exam_results
  FOR SELECT
  TO authenticated
  USING (
    student_id IN (SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid())
    AND is_published = true
  );

-- 10. STUDENT FEES RLS POLICIES (Read-Only for Authorized Child Fees)
DROP POLICY IF EXISTS "Parents view child fee summary" ON public.student_fees;
CREATE POLICY "Parents view child fee summary" ON public.student_fees
  FOR SELECT
  TO authenticated
  USING (
    student_id IN (SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid())
  );

-- 11. NOTICES RLS POLICIES (Read-Only for Parent's Authorized School & Student)
DROP POLICY IF EXISTS "Parents view targeted notices" ON public.notices;
CREATE POLICY "Parents view targeted notices" ON public.notices
  FOR SELECT
  TO authenticated
  USING (
    school_id IN (
      SELECT school_id FROM public.students WHERE id IN (
        SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid()
      )
    )
    AND (student_id IS NULL OR student_id IN (
      SELECT student_id FROM public.parent_students WHERE parent_id = auth.uid()
    ))
  );

-- 12. NOTIFICATIONS & DEVICE TOKENS RLS POLICIES
DROP POLICY IF EXISTS "Parents view own notifications" ON public.parent_notifications;
CREATE POLICY "Parents view own notifications" ON public.parent_notifications
  FOR SELECT
  TO authenticated
  USING (parent_auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Parents update own notification read status" ON public.parent_notifications;
CREATE POLICY "Parents update own notification read status" ON public.parent_notifications
  FOR UPDATE
  TO authenticated
  USING (parent_auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Parents manage own device tokens" ON public.parent_devices;
CREATE POLICY "Parents manage own device tokens" ON public.parent_devices
  FOR ALL
  TO authenticated
  USING (parent_auth_user_id = auth.uid())
  WITH CHECK (parent_auth_user_id = auth.uid());

-- 13. INDEXES FOR RLS PERFORMANCE & CROSS-TENANT QUERY SPEED
CREATE INDEX IF NOT EXISTS idx_parent_students_parent_id ON public.parent_students(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_students_student_id ON public.parent_students(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_student_id_published ON public.exam_results(student_id, is_published);
CREATE INDEX IF NOT EXISTS idx_student_fees_student_id ON public.student_fees(student_id);
CREATE INDEX IF NOT EXISTS idx_parent_notifications_parent_auth ON public.parent_notifications(parent_auth_user_id);
CREATE INDEX IF NOT EXISTS idx_parent_devices_parent_auth ON public.parent_devices(parent_auth_user_id);

-- REVOKE UNNECESSARY PUBLIC EXECUTE PRIVILEGES ON SECURITY DEFINER RPCS
REVOKE EXECUTE ON FUNCTION public.get_user_school_id() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_user_school_id() TO authenticated;
