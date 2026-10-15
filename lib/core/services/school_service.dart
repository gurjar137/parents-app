import 'package:flutter/foundation.dart';
import '../../data/models/school_brand_model.dart';
import 'supabase_service.dart';

class SchoolService {
  static final Map<String, SchoolBrandModel> _cache = {};

  /// Resolves the authoritative school record from public.schools using canonical school ID
  static Future<SchoolBrandModel> fetchSchoolBrand(String schoolId) async {
    final cleanId = schoolId.trim();

    if (cleanId.isEmpty) {
      return SchoolBrandModel.defaultNeutral();
    }

    if (_cache.containsKey(cleanId)) {
      return _cache[cleanId]!;
    }

    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.client
            .from('schools')
            .select()
            .eq('id', cleanId)
            .maybeSingle();

        if (res != null) {
          final brand = SchoolBrandModel.fromMap(res);
          _cache[cleanId] = brand;
          return brand;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SchoolService] Notice resolving school record for $cleanId: $e');
        }
      }
    }

    // Default neutral branding bound to this specific school ID without any hardcoded Xavier/KPS fallback
    final neutralBrand = SchoolBrandModel.defaultNeutral();
    _cache[cleanId] = neutralBrand;
    return neutralBrand;
  }

  /// Clears in-memory school cache on logout or account switch
  static void clearCache() {
    _cache.clear();
  }
}
