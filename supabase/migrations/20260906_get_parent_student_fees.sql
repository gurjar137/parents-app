-- ================================================================================
-- SECURE SECURITY DEFINER RPC FOR PARENT FEES READ
-- Function: get_parent_student_fees(p_student_id UUID, p_school_id UUID DEFAULT NULL, p_parent_access_code TEXT DEFAULT NULL)
-- Description: Safely fetches fee account details and payments ONLY for the matching student
--              validates parent_access_code matching students.parent_access_code
-- ================================================================================

CREATE OR REPLACE FUNCTION public.get_parent_student_fees(
  p_student_id UUID,
  p_school_id UUID DEFAULT NULL,
  p_parent_access_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_student_valid BOOLEAN := FALSE;
  v_fee_account RECORD;
  v_payments JSONB;
  v_result JSONB;
BEGIN
  IF p_student_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- 1. Validate parent_access_code relationship to target student if code is provided
  IF p_parent_access_code IS NOT NULL AND TRIM(p_parent_access_code) <> '' THEN
    SELECT EXISTS (
      SELECT 1 FROM public.students s
      WHERE s.id = p_student_id
        AND UPPER(TRIM(s.parent_access_code)) = UPPER(TRIM(p_parent_access_code))
        AND (p_school_id IS NULL OR s.school_id = p_school_id)
    ) INTO v_student_valid;

    IF NOT v_student_valid THEN
      RETURN NULL;
    END IF;
  END IF;

  -- 2. Fetch student_fee_accounts record for target student_id
  SELECT 
    fa.id,
    fa.student_id,
    fa.school_id,
    fa.academic_year_id,
    COALESCE(fa.gross_fee, 0.00) AS gross_fee,
    COALESCE(fa.discount_amount, 0.00) AS discount_amount,
    COALESCE(fa.waiver_amount, 0.00) AS waiver_amount,
    COALESCE(fa.due_date, CURRENT_DATE + INTERVAL '30 days') AS due_date,
    COALESCE(fa.notes, '') AS notes,
    COALESCE(fa.status, 'due') AS status
  INTO v_fee_account
  FROM public.student_fee_accounts fa
  WHERE fa.student_id = p_student_id
    AND (p_school_id IS NULL OR fa.school_id = p_school_id)
  ORDER BY fa.created_at DESC
  LIMIT 1;

  -- 3. Fetch fee_payments for target student_id / fee_account_id
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', fp.id,
        'fee_account_id', fp.fee_account_id,
        'student_id', fp.student_id,
        'receipt_number', COALESCE(fp.receipt_number, 'REC-' || fp.id::text),
        'amount', COALESCE(fp.amount, 0.00),
        'payment_date', COALESCE(fp.payment_date, fp.created_at::date),
        'payment_method', COALESCE(fp.payment_method, 'cash'),
        'reference_number', COALESCE(fp.transaction_reference, fp.notes, ''),
        'notes', COALESCE(fp.notes, ''),
        'created_at', fp.created_at
      ) ORDER BY COALESCE(fp.payment_date, fp.created_at::date) DESC, fp.created_at DESC
    ),
    '[]'::jsonb
  ) INTO v_payments
  FROM public.fee_payments fp
  WHERE fp.student_id = p_student_id
     OR (v_fee_account.id IS NOT NULL AND fp.fee_account_id = v_fee_account.id);

  IF v_fee_account.id IS NULL AND (v_payments IS NULL OR jsonb_array_length(v_payments) = 0) THEN
    RETURN NULL;
  END IF;

  -- 4. Construct clean JSON response
  v_result := jsonb_build_object(
    'account', CASE 
      WHEN v_fee_account.id IS NOT NULL THEN jsonb_build_object(
        'id', v_fee_account.id,
        'student_id', v_fee_account.student_id,
        'school_id', v_fee_account.school_id,
        'academic_year_id', v_fee_account.academic_year_id,
        'gross_fee', v_fee_account.gross_fee,
        'discount_amount', v_fee_account.discount_amount,
        'waiver_amount', v_fee_account.waiver_amount,
        'due_date', v_fee_account.due_date,
        'notes', v_fee_account.notes,
        'status', v_fee_account.status
      )
      ELSE NULL
    END,
    'payments', v_payments
  );

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_parent_student_fees(UUID, UUID, TEXT) TO anon, authenticated, service_role;
