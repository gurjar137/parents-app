import '../../data/models/school_brand_model.dart';
import 'parent_api.dart';

class SchoolService {
  static final Map<String, SchoolBrandModel> _cache = {};

  /// School of a linked child (`parent_get_school`). Cached per student for
  /// the session; cleared on logout and child-link changes.
  static Future<SchoolBrandModel> fetchSchoolForStudent(String studentId) async {
    if (studentId.isEmpty) return SchoolBrandModel.defaultNeutral();
    final cached = _cache[studentId];
    if (cached != null) return cached;
    final json = await ParentApi.instance.rpcObject('parent_get_school', {'p_student_id': studentId});
    final brand = SchoolBrandModel.fromMap(json);
    _cache[studentId] = brand;
    return brand;
  }

  static void clearCache() => _cache.clear();
}
