import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

enum DatabaseReadStatus {
  success,
  blockedByRls,
  failed,
  uninitialized,
}

/// Reusable Supabase Service managing initialization, client access, and connection verification.
class SupabaseService {
  static bool _isInitialized = false;
  static DatabaseReadStatus _lastReadStatus = DatabaseReadStatus.uninitialized;
  static String? _lastReadMessage;

  /// Returns true if Supabase SDK has been initialized successfully.
  static bool get isInitialized => _isInitialized;

  /// Returns true if valid credentials are configured (non-placeholder).
  static bool get isConfigured => SupabaseConfig.isConfigured;

  /// Returns last database read test status.
  static DatabaseReadStatus get lastReadStatus => _lastReadStatus;
  static String? get lastReadMessage => _lastReadMessage;

  /// Global access point to the initialized Supabase client.
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase is not initialized. Please ensure SupabaseService.initialize() was called.',
      );
    }
    return Supabase.instance.client;
  }

  /// Initializes the Supabase Flutter SDK safely during app startup.
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Notice: Supabase credentials unconfigured.');
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('[SupabaseService] Supabase initialized successfully for project ${SupabaseConfig.projectRef}.');
      }

      // Perform a safe initial READ check
      await testDatabaseRead();
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        debugPrint('[SupabaseService] Initialization error: $e');
      }
    }
  }

  /// Safe database READ check against authorized table without altering any records or RLS rules.
  static Future<DatabaseReadStatus> testDatabaseRead() async {
    if (!_isInitialized) {
      _lastReadStatus = DatabaseReadStatus.uninitialized;
      return DatabaseReadStatus.uninitialized;
    }

    try {
      // Attempt safe read on parents table
      await Supabase.instance.client
          .from('parents')
          .select('id')
          .limit(1);

      _lastReadStatus = DatabaseReadStatus.success;
      _lastReadMessage = 'READ operation succeeded.';
      return DatabaseReadStatus.success;
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.code == '42501' || e.code == 'PGRST301' || msg.contains('row-level security') || msg.contains('permission denied') || msg.contains('unauthorized')) {
        _lastReadStatus = DatabaseReadStatus.blockedByRls;
        _lastReadMessage = 'Connection active. RLS correctly protected table from unauthenticated access.';
        if (kDebugMode) {
          debugPrint('[SupabaseService] Database read notice: RLS active (${e.message}).');
        }
        return DatabaseReadStatus.blockedByRls;
      }
      _lastReadStatus = DatabaseReadStatus.failed;
      _lastReadMessage = e.message;
      return DatabaseReadStatus.failed;
    } catch (e) {
      // Fallback check on schools table
      try {
        await Supabase.instance.client
            .from('schools')
            .select('id')
            .limit(1);

        _lastReadStatus = DatabaseReadStatus.success;
        _lastReadMessage = 'READ operation on schools table succeeded.';
        return DatabaseReadStatus.success;
      } on PostgrestException catch (pe) {
        final pmsg = pe.message.toLowerCase();
        if (pe.code == '42501' || pe.code == 'PGRST301' || pmsg.contains('row-level security') || pmsg.contains('permission denied') || pmsg.contains('unauthorized')) {
          _lastReadStatus = DatabaseReadStatus.blockedByRls;
          _lastReadMessage = 'Connection active. RLS correctly protected table from unauthenticated access.';
          return DatabaseReadStatus.blockedByRls;
        }
        _lastReadStatus = DatabaseReadStatus.failed;
        _lastReadMessage = pe.message;
        return DatabaseReadStatus.failed;
      } catch (e2) {
        _lastReadStatus = DatabaseReadStatus.failed;
        _lastReadMessage = e2.toString();
        return DatabaseReadStatus.failed;
      }
    }
  }

  /// Connection test helper.
  static Future<bool> testConnection() async {
    if (!_isInitialized) return false;
    final status = await testDatabaseRead();
    return status == DatabaseReadStatus.success || status == DatabaseReadStatus.blockedByRls;
  }
}
