/// Supabase Configuration for School Parent Mobile App.
///
/// SECURITY INSTRUCTIONS:
/// - Only use the Supabase Project URL and Public Anon / Publishable Key here.
/// - NEVER place the Supabase Service Role / Secret Key in this Flutter application.
class SupabaseConfig {
  /// Raw Supabase Project URL from environment or fallback
  static const String _rawUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hnvjenkeimzkdgkuwbeb.supabase.co',
  );

  /// Clean normalized Supabase Base URL (strips `/rest/v1/` suffix if provided)
  static String get url {
    var cleanUrl = _rawUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (cleanUrl.endsWith('/rest/v1')) {
      cleanUrl = cleanUrl.replaceAll('/rest/v1', '');
    }
    return cleanUrl;
  }

  /// Supabase Public Anon / Publishable Key
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_19M-FirlFuK29VbdO1d87g_bNOysJwZ',
  );

  /// Helper to check if valid credentials are present (non-placeholder)
  static bool get isConfigured {
    return url.isNotEmpty &&
        !url.contains('SUPABASE_URL') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('SUPABASE_PUBLISHABLE_KEY');
  }

  /// Extract project reference safely for project comparison (without exposing keys)
  static String get projectRef {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      final parts = uri.host.split('.');
      if (parts.isNotEmpty) return parts.first;
    }
    return 'unknown';
  }
}
