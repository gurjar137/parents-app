import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/supabase_service.dart';
import 'package:parent_app/core/services/auth_service.dart';
import 'package:parent_app/core/services/school_service.dart';
import 'package:parent_app/core/services/link_child_service.dart';
import 'package:parent_app/data/models/student_model.dart';
import 'package:parent_app/data/models/school_brand_model.dart';
import 'package:parent_app/providers/parent_app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  group('1. Father\'s Name Integrity Tests', () {
    test('StudentModel does not default or fall back to Rajesh Sharma', () {
      final studentWithoutFather = StudentModel.fromMap({
        'id': 'test-stu-1',
        'name': 'Aarav Kumar',
        'class_name': '6-A',
        'grade': 'Class 6',
        'section': 'A',
      }, 'test-stu-1');

      expect(studentWithoutFather.fatherName, isNull);
      expect(studentWithoutFather.displayFatherName, equals('Not provided'));
    });

    test('StudentModel displays genuine father\'s name accurately', () {
      final studentWithFather = StudentModel.fromMap({
        'id': 'test-stu-2',
        'name': 'Rohan Gupta',
        'father_name': 'Sunil Gupta',
        'class_name': '7-B',
        'grade': 'Class 7',
        'section': 'B',
      }, 'test-stu-2');

      expect(studentWithFather.fatherName, equals('Sunil Gupta'));
      expect(studentWithFather.displayFatherName, equals('Sunil Gupta'));
    });

    test('StudentModel never substitutes mother\'s name for father\'s name', () {
      final studentWithMotherOnly = StudentModel.fromMap({
        'id': 'test-stu-3',
        'name': 'Meera Verma',
        'mother_name': 'Anjali Verma',
        'class_name': '5-A',
        'grade': 'Class 5',
        'section': 'A',
      }, 'test-stu-3');

      expect(studentWithMotherOnly.fatherName, isNull);
      expect(studentWithMotherOnly.displayFatherName, equals('Not provided'));
      expect(studentWithMotherOnly.motherName, equals('Anjali Verma'));
    });

    test('StudentModel sanitizes string literals like "null" for father_name', () {
      final studentWithNullString = StudentModel.fromMap({
        'id': 'test-stu-4',
        'name': 'Kavya Singh',
        'father_name': 'null',
        'class_name': '8-A',
      }, 'test-stu-4');

      expect(studentWithNullString.fatherName, isNull);
      expect(studentWithNullString.displayFatherName, equals('Not provided'));
    });
  });

  group('2. Dynamic School Branding Isolation Tests', () {
    test('Default neutral branding contains no hardcoded St. Xavier or Xavier Academy', () {
      final neutral = SchoolBrandModel.defaultNeutral();

      expect(neutral.schoolName.toLowerCase().contains('xavier'), isFalse);
      expect(neutral.schoolName, equals('School Portal'));
      expect(neutral.affiliation.toLowerCase().contains('xavier'), isFalse);
    });

    test('Provider branding initializes to clean neutral brand without Xavier', () {
      final provider = ParentAppProvider();

      expect(provider.branding.schoolName.toLowerCase().contains('xavier'), isFalse);
      expect(provider.branding.schoolName, equals('School Portal'));
    });

    test('SchoolService handles non-existent school ID safely with neutral fallback', () async {
      final brand = await SchoolService.fetchSchoolBrand('non-existent-school-id-999');

      expect(brand.schoolName.toLowerCase().contains('xavier'), isFalse);
      expect(brand.schoolName, equals('School Portal'));
    });
  });

  group('3. Access Code Verification Flow Tests', () {
    test('Empty access code is rejected with invalidCode status', () async {
      final provider = ParentAppProvider();
      final res = await provider.linkChildWithCode(codeOrStudentId: '   ');

      expect(res.status, equals(LinkStatus.invalidCode));
      expect(res.student, isNull);
    });

    test('Invalid access code is rejected with invalidCode or notFound status', () async {
      final res = await AuthService.signInWithParentCode('INVALID-CODE-XYZ-1234');

      expect(res.status, isNot(equals(AuthStatus.success)));
      expect(res.parent, isNull);
    });
  });

  group('4. Cross-Student Isolation & Race-Condition Guard Tests', () {
    test('selectChild immediately clears previous child\'s cached module datasets', () {
      final provider = ParentAppProvider();

      final childA = StudentModel.fromMap({
        'id': 'student-aaa-111',
        'name': 'Child Alpha',
        'class_name': '8-A',
        'grade': 'Class 8',
        'section': 'A',
      }, 'student-aaa-111');

      final childB = StudentModel.fromMap({
        'id': 'student-bbb-222',
        'name': 'Child Beta',
        'class_name': '6-B',
        'grade': 'Class 6',
        'section': 'B',
      }, 'student-bbb-222');

      provider.selectChild(childA);
      expect(provider.selectedChild.id, equals('student-aaa-111'));

      // Switch to Child B
      provider.selectChild(childB);
      expect(provider.selectedChild.id, equals('student-bbb-222'));

      // Verify that after switching, the active caches for child A are completely cleared
      expect(provider.todayAttendance, isNull);
      expect(provider.currentAttendance.totalWorkingDays, equals(0));
      expect(provider.currentHomeworkList, isEmpty);
      expect(provider.currentTimetable.values.every((list) => list.isEmpty), isTrue);
      expect(provider.currentResultsList, isEmpty);
      expect(provider.currentFeeSummary.netFee, equals(0.0));
      expect(provider.notices, isEmpty);
      expect(provider.notifications, isEmpty);
    });
  });

  group('5. Logout State & Session Cleansing Tests', () {
    test('logout clears all session data, resets neutral branding, and purges child list', () async {
      final provider = ParentAppProvider();

      final dummyStudent = StudentModel.fromMap({
        'id': 'dummy-stu',
        'name': 'Dummy Child',
        'father_name': 'Real Father',
        'class_name': '4-A',
        'grade': 'Class 4',
        'section': 'A',
      }, 'dummy-stu');

      provider.selectChild(dummyStudent);
      expect(provider.isChildLinked, isTrue);

      await provider.logout();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.children, isEmpty);
      expect(provider.isChildLinked, isFalse);
      expect(provider.branding.schoolName, equals('School Portal'));
      expect(provider.branding.schoolName.toLowerCase().contains('xavier'), isFalse);
      expect(provider.todayAttendance, isNull);
      expect(provider.currentAttendance.totalWorkingDays, equals(0));
      expect(provider.currentHomeworkList, isEmpty);
      expect(provider.currentTimetable.values.every((list) => list.isEmpty), isTrue);
      expect(provider.currentResultsList, isEmpty);
      expect(provider.currentFeeSummary.netFee, equals(0.0));
    });
  });
}
