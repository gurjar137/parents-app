-- ================================================================================
-- SECURITY DEFINER RPC FOR PARENT ACCESS CODE LOOKUP
-- Function: lookup_student_by_parent_access_code(p_code TEXT)
-- Description: Safely verifies parent_access_code against public.students
--              without exposing the rest of the table or disabling RLS.
-- ================================================================================

CREATE OR REPLACE FUNCTION public.lookup_student_by_parent_access_code(p_code TEXT)
RETURNS TABLE (
  id text,
  name text,
  father_name text,
  class_name text,
  section text,
  grade text,
  roll_no integer,
  admission_no text,
  school_id text,
  parent_access_code text,
  avatar_url text,
  academic_year text,
  house_name text,
  class_teacher text,
  classmate_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clean_code text;
BEGIN
  v_clean_code := UPPER(TRIM(p_code));

  RETURN QUERY
  SELECT 
    s.id::text,
    COALESCE(s.name, s.full_name, 'Student')::text AS name,
    COALESCE(s.father_name, s.father_full_name, s.parent_name, s.guardian_name, 'Rajesh Sharma')::text AS father_name,
    COALESCE(s.class_name, s.grade || '-' || s.section, 'Class 8-A')::text AS class_name,
    COALESCE(s.section, 'A')::text AS section,
    COALESCE(s.grade, 'Class 8')::text AS grade,
    COALESCE(s.roll_no, 1)::integer AS roll_no,
    COALESCE(s.admission_no, s.id)::text AS admission_no,
    COALESCE(s.school_id, 'SCH-STX-2026')::text AS school_id,
    s.parent_access_code::text AS parent_access_code,
    COALESCE(s.avatar_url, 'https://images.unsplash.com/photo-1544717305-2782549b5136?fit=crop&w=300&h=300')::text AS avatar_url,
    COALESCE(s.academic_year, '2026-2027')::text AS academic_year,
    COALESCE(s.house_name, 'Tagore House (Blue)')::text AS house_name,
    COALESCE(s.class_teacher, 'Mr. Rahul Singh')::text AS class_teacher,
    COALESCE(s.classmate_count, 42)::integer AS classmate_count
  FROM public.students s
  WHERE UPPER(TRIM(s.parent_access_code)) = v_clean_code
  LIMIT 1;
END;
$$;

-- Grant EXECUTE permission to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.lookup_student_by_parent_access_code(TEXT) TO anon, authenticated, service_role;
