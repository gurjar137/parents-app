import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import '../data/models/parent_model.dart';
import '../data/models/student_model.dart';
import '../data/models/attendance_model.dart';
import '../data/models/homework_model.dart';
import '../data/models/fee_model.dart';
import '../data/models/result_model.dart';
import '../data/models/timetable_model.dart';
import '../data/models/notice_model.dart';
import '../data/models/notification_model.dart';
import '../data/models/ptm_access_code.dart';
import '../data/models/exam_model.dart';
import '../data/models/ptm_model.dart';
import '../data/models/document_model.dart';
import '../data/models/correction_request_model.dart';
import '../data/models/message_model.dart';
import '../data/models/transport_model.dart';
import '../data/models/calendar_event_model.dart';
import '../data/models/ai_message_model.dart';
import '../data/models/school_brand_model.dart';
import '../data/mock/mock_data.dart';
import '../core/services/auth_service.dart';
import '../core/services/attendance_service.dart';
import '../core/services/homework_service.dart';
import '../core/services/timetable_service.dart';
import '../core/services/result_service.dart';
import '../core/services/fee_service.dart';
import '../core/services/notice_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/link_child_service.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';

class ParentAppProvider extends ChangeNotifier {
  late ParentModel _parent;
  late List<StudentModel> _children;
  StudentModel? _selectedChild;
  late SchoolBrandModel _branding;

  // Authentication & Session State
  bool _isLoggedIn = false;
  bool _isAuthLoading = false;
  bool _isSessionChecking = true;
  bool _isDashboardLoading = false;
  bool _isAttendanceLoading = false;
  String? _authError;
  String? _dashboardError;
  String? _attendanceError;

  // Attendance State
  DailyAttendance? _todayAttendance;
  MonthlyAttendanceSummary? _activeAttendanceSummary;
  int _attendanceYear = DateTime.now().year;
  int _attendanceMonth = DateTime.now().month;

  // Homework State
  bool _isHomeworkLoading = false;
  String? _homeworkError;
  List<HomeworkModel>? _activeHomeworkList;

  // Timetable State
  bool _isTimetableLoading = false;
  String? _timetableError;
  List<TimetableEntryModel>? _activeTimetableList;

  // Results State
  bool _isResultsLoading = false;
  String? _resultsError;
  List<ExamResultModel>? _activeResultsList;

  // Fees State
  bool _isFeesLoading = false;
  String? _feesError;
  FeeSummaryModel? _activeFeeSummary;

  // Notices State
  bool _isNoticesLoading = false;
  String? _noticesError;
  List<NoticeModel>? _activeNoticesList;

  // Notifications State
  bool _isNotificationsLoading = false;
  String? _notificationsError;
  List<AppNotificationModel>? _activeNotificationsList;

  // Local mutable datasets
  late List<AppNotificationModel> _notifications;
  late List<CorrectionRequestModel> _correctionRequests;
  late List<AiMessageModel> _aiMessages;

  ThemeMode _themeMode = ThemeMode.light;
  int _selectedBottomNavIndex = 0;
  String _lastUpdatedTime = 'Today, 10:42 AM';
  bool _isRefreshing = false;

  ParentAppProvider() {
    _init();
    _setupAuthListener();
    checkExistingSession();
  }

  void _init() {
    _branding = MockData.defaultBranding;
    _parent = const ParentModel(
      id: '',
      name: '',
      email: '',
      phone: '',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
      childrenIds: [],
    );
    _children = [];
    _selectedChild = null;

    _notifications = [];
    _correctionRequests = [];
    _aiMessages = [];
  }

  void _setupAuthListener() {
    if (SupabaseService.isInitialized) {
      SupabaseService.client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          final user = session.user;
          final profile = await AuthService.fetchOrCreateParentProfile(user);
          _parent = profile;
          _isLoggedIn = true;
          notifyListeners();
        } else if (event == AuthChangeEvent.signedOut) {
          _isLoggedIn = false;
          _selectedBottomNavIndex = 0;
          notifyListeners();
        }
      });
    }
  }

  // Auth, Dashboard, Attendance, Homework, Timetable, Results, Fees, Notices & Notifications Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthLoading => _isAuthLoading;
  bool get isSessionChecking => _isSessionChecking;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get isAttendanceLoading => _isAttendanceLoading;
  bool get isHomeworkLoading => _isHomeworkLoading;
  bool get isTimetableLoading => _isTimetableLoading;
  bool get isResultsLoading => _isResultsLoading;
  bool get isFeesLoading => _isFeesLoading;
  bool get isNoticesLoading => _isNoticesLoading;
  bool get isNotificationsLoading => _isNotificationsLoading;
  String? get authError => _authError;
  String? get dashboardError => _dashboardError;
  String? get attendanceError => _attendanceError;
  String? get homeworkError => _homeworkError;
  String? get timetableError => _timetableError;
  String? get resultsError => _resultsError;
  String? get feesError => _feesError;
  String? get noticesError => _noticesError;
  String? get notificationsError => _notificationsError;
  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;
  DailyAttendance? get todayAttendance => _todayAttendance;
  int get attendanceYear => _attendanceYear;
  int get attendanceMonth => _attendanceMonth;

  Future<void> loadNotificationsForSelectedChild() async {
    if (_selectedChild == null) {
      _isNotificationsLoading = false;
      notifyListeners();
      return;
    }
    _isNotificationsLoading = true;
    _notificationsError = null;
    notifyListeners();

    try {
      await NotificationService.registerDeviceToken(
        parentAuthId: _parent.id,
        schoolId: _selectedChild!.schoolId,
      );
      final list = await NotificationService.fetchNotificationsForParent(
        parentAuthId: _parent.id,
        schoolId: _selectedChild!.schoolId,
        studentId: _selectedChild!.id,
      );
      _activeNotificationsList = list;
      _notificationsError = null;
    } catch (e) {
      _notificationsError = 'Unable to load notifications. Please try again.';
    }

    _isNotificationsLoading = false;
    notifyListeners();
  }

  Future<void> markAppNotificationAsRead(String notificationId) async {
    _activeNotificationsList ??= List.from(MockData.notifications);
    final index = _activeNotificationsList!.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_activeNotificationsList![index].isRead) {
      _activeNotificationsList![index] = _activeNotificationsList![index].copyWith(isRead: true);
      notifyListeners();
    }
    await NotificationService.markNotificationAsRead(
      notificationId: notificationId,
      parentAuthId: _parent.id,
    );
  }

  Future<void> loadNoticesForSelectedChild() async {
    if (_selectedChild == null) {
      _isNoticesLoading = false;
      notifyListeners();
      return;
    }
    _isNoticesLoading = true;
    _noticesError = null;
    notifyListeners();

    try {
      final list = await NoticeService.fetchNoticesForParent(
        schoolId: _selectedChild!.schoolId,
        className: _selectedChild!.className,
        studentId: _selectedChild!.id,
      );
      _activeNoticesList = list;
      _noticesError = null;
    } catch (e) {
      _noticesError = 'Unable to load notices. Please try again.';
    }

    _isNoticesLoading = false;
    notifyListeners();
  }

  Future<void> markNoticeAsRead(String noticeId) async {
    _activeNoticesList ??= List.from(MockData.notices);
    final index = _activeNoticesList!.indexWhere((n) => n.id == noticeId);
    if (index != -1 && !_activeNoticesList![index].isRead) {
      _activeNoticesList![index] = _activeNoticesList![index].copyWith(isRead: true);
      notifyListeners();
    }
    await NoticeService.markNoticeAsRead(noticeId: noticeId, parentAuthId: _parent.id);
  }

  Future<void> loadFeeSummaryForSelectedChild() async {
    if (_selectedChild == null) {
      _isFeesLoading = false;
      notifyListeners();
      return;
    }
    _isFeesLoading = true;
    _feesError = null;
    notifyListeners();

    try {
      final parentCode = (_selectedChild!.linkingCode != null && _selectedChild!.linkingCode!.isNotEmpty)
          ? _selectedChild!.linkingCode!
          : (await AuthService.getSavedParentCode() ?? '');

      final summary = await FeeService.fetchFeeSummaryForStudent(
        studentId: _selectedChild!.id,
        schoolId: _selectedChild!.schoolId,
        academicYearId: _selectedChild!.academicYear,
        parentAccessCode: parentCode,
      );
      _activeFeeSummary = summary;
      _feesError = null;
    } catch (e) {
      _feesError = 'Unable to load fee details. Please try again.';
    }

    _isFeesLoading = false;
    notifyListeners();
  }

  Future<void> loadResultsForSelectedChild() async {
    if (_selectedChild == null) {
      _isResultsLoading = false;
      notifyListeners();
      return;
    }
    _isResultsLoading = true;
    _resultsError = null;
    notifyListeners();

    try {
      final list = await ResultService.fetchResultsForStudent(
        studentId: _selectedChild!.id,
        schoolId: _selectedChild!.schoolId,
      );
      _activeResultsList = list;
      _resultsError = null;
    } catch (e) {
      _resultsError = 'Unable to load examination results. Please try again.';
    }

    _isResultsLoading = false;
    notifyListeners();
  }

  Future<void> loadTimetableForSelectedChild() async {
    if (_selectedChild == null) {
      _isTimetableLoading = false;
      notifyListeners();
      return;
    }
    _isTimetableLoading = true;
    _timetableError = null;
    notifyListeners();

    try {
      final list = await TimetableService.fetchTimetableForStudent(
        schoolId: _selectedChild!.schoolId,
        className: _selectedChild!.className,
        section: _selectedChild!.section,
        studentId: _selectedChild!.id,
      );
      _activeTimetableList = list;
      _timetableError = null;
    } catch (e) {
      _timetableError = 'Unable to load timetable. Please try again.';
    }

    _isTimetableLoading = false;
    notifyListeners();
  }

  Future<void> loadHomeworkForSelectedChild() async {
    if (_selectedChild == null) {
      _isHomeworkLoading = false;
      notifyListeners();
      return;
    }
    _isHomeworkLoading = true;
    _homeworkError = null;
    notifyListeners();

    try {
      final list = await HomeworkService.fetchHomeworkForStudent(
        studentId: _selectedChild!.id,
        className: _selectedChild!.className,
        schoolId: _selectedChild!.schoolId,
      );
      _activeHomeworkList = list;
      _homeworkError = null;
    } catch (e) {
      _homeworkError = 'Unable to load homework. Please try again.';
    }

    _isHomeworkLoading = false;
    notifyListeners();
  }

  Future<void> loadAttendanceForSelectedChild() async {
    if (_selectedChild == null) {
      _isAttendanceLoading = false;
      notifyListeners();
      return;
    }
    _isAttendanceLoading = true;
    _attendanceError = null;
    notifyListeners();

    try {
      final summary = await AttendanceService.fetchAttendanceForStudent(
        studentId: _selectedChild!.id,
        year: _attendanceYear,
        month: _attendanceMonth,
      );
      _activeAttendanceSummary = summary;
      _todayAttendance = await AttendanceService.fetchTodayAttendance(studentId: _selectedChild!.id);
      _attendanceError = null;
    } catch (e) {
      _attendanceError = 'Unable to load attendance. Please try again.';
    }

    _isAttendanceLoading = false;
    notifyListeners();
  }

  Future<void> changeAttendanceMonth(int year, int month) async {
    _attendanceYear = year;
    _attendanceMonth = month;
    await loadAttendanceForSelectedChild();
  }

  Future<void> retryDashboardLoad() async {
    _isDashboardLoading = true;
    _dashboardError = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final user = AuthService.currentUser;
      if (user != null) {
        final profile = await AuthService.fetchOrCreateParentProfile(user);
        _parent = profile;
        _children = await LinkChildService.fetchLinkedStudentsForParent(user.id);
        if (_children.isNotEmpty) {
          _selectedChild = _children.first;
        }
      }
      _dashboardError = null;
    } catch (e) {
      _dashboardError = 'Unable to load your child\'s information. Please try again.';
    }

    _isDashboardLoading = false;
    notifyListeners();
  }

  static const StudentModel _emptyStudent = StudentModel(
    id: '',
    name: 'No Child Linked',
    className: '',
    grade: '',
    section: '',
    rollNo: 0,
    admissionNo: '',
    schoolId: 'SCH-STX-2026',
    fatherName: '',
    academicYear: '2026-2027',
    avatarUrl: '',
    classTeacher: '',
    classmateCount: 0,
    houseName: '',
  );

  // Data Getters
  ParentModel get parent => _parent;
  List<StudentModel> get children => _children;
  StudentModel get selectedChild => _selectedChild ?? _emptyStudent;
  bool get isChildLinked => _selectedChild != null && _selectedChild!.id.isNotEmpty;

  /// Dynamic Father/Parent Name derived from currently connected/selected student record
  String get currentFatherName {
    if (_selectedChild != null &&
        _selectedChild!.fatherName != null &&
        _selectedChild!.fatherName!.isNotEmpty) {
      return _selectedChild!.fatherName!;
    }
    if (_parent.name.isNotEmpty &&
        _parent.name != 'Parent User' &&
        _parent.name != 'Dharampal Sharma') {
      return _parent.name;
    }
    return '';
  }

  SchoolBrandModel get branding => _branding;
  ThemeMode get themeMode => _themeMode;
  int get selectedBottomNavIndex => _selectedBottomNavIndex;
  String get lastUpdatedTime => _lastUpdatedTime;
  bool get isRefreshing => _isRefreshing;
  List<CorrectionRequestModel> get correctionRequests => _correctionRequests;
  List<AiMessageModel> get aiMessages => _aiMessages;

  // Check persistent session on app startup
  Future<void> checkExistingSession() async {
    _isSessionChecking = true;
    notifyListeners();

    try {
      final savedCode = await AuthService.getSavedParentCode();
      if (savedCode != null && savedCode.isNotEmpty) {
        final authRes = await AuthService.signInWithParentCode(savedCode);
        if (authRes.status == AuthStatus.success && authRes.parent != null) {
          _parent = authRes.parent!;
          if (authRes.children != null && authRes.children!.isNotEmpty) {
            _children = List.from(authRes.children!);
            _selectedChild = _children.first;
            loadAttendanceForSelectedChild();
            loadHomeworkForSelectedChild();
            loadTimetableForSelectedChild();
            loadFeeSummaryForSelectedChild();
            loadResultsForSelectedChild();
            loadNoticesForSelectedChild();
            loadNotificationsForSelectedChild();
          } else {
            _children = [];
            _selectedChild = null;
          }
          _isLoggedIn = true;
          _isSessionChecking = false;
          notifyListeners();
          return;
        }
      }

      final user = AuthService.currentUser;
      final session = AuthService.currentSession;

      if (user != null && session != null) {
        final profile = await AuthService.fetchOrCreateParentProfile(user);
        if (profile.status.toLowerCase() == 'active') {
          _parent = profile;
          _children = await LinkChildService.fetchLinkedStudentsForParent(user.id);
          if (_children.isNotEmpty) {
            _selectedChild = _children.first;
          } else {
            _selectedChild = null;
          }
          _isLoggedIn = true;
        } else {
          await AuthService.clearSession();
          _isLoggedIn = false;
          _children = [];
          _selectedChild = null;
        }
      } else {
        _isLoggedIn = false;
        _children = [];
        _selectedChild = null;
      }
    } catch (_) {
      _isLoggedIn = false;
      _children = [];
      _selectedChild = null;
    }

    _isSessionChecking = false;
    notifyListeners();
  }

  // Secure Student Linking Method
  Future<LinkChildResponse> linkChildWithCode({
    required String codeOrStudentId,
    String relationship = 'Parent',
  }) async {
    final cleanCode = codeOrStudentId.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return const LinkChildResponse(
        status: LinkStatus.invalidCode,
        errorMessage: 'Please enter a valid Parent Access Code.',
      );
    }

    final response = await LinkChildService.linkStudentToParent(
      codeOrStudentId: cleanCode,
      relationship: relationship,
    );

    if (response.status == LinkStatus.success && response.student != null) {
      final newStudent = response.student!;
      if (_children.any((s) => s.id == newStudent.id)) {
        return LinkChildResponse(
          status: LinkStatus.alreadyLinked,
          student: newStudent,
          errorMessage: 'This child is already linked.',
        );
      }
      _children.add(newStudent);
      _selectedChild = newStudent;
      notifyListeners();
    }

    return response;
  }

  // Connect Admin-Generated Unique Parent Code to Parent App Login
  Future<AuthResponse> loginWithParentCode(String parentCode) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    final response = await AuthService.signInWithParentCode(parentCode);

    if (response.status == AuthStatus.success && response.parent != null) {
      _parent = response.parent!;
      if (response.children != null && response.children!.isNotEmpty) {
        _children = List.from(response.children!);
        _selectedChild = _children.first;

        loadAttendanceForSelectedChild();
        loadHomeworkForSelectedChild();
        loadTimetableForSelectedChild();
        loadFeeSummaryForSelectedChild();
        loadResultsForSelectedChild();
        loadNoticesForSelectedChild();
        loadNotificationsForSelectedChild();
      } else {
        _children = [];
        _selectedChild = null;
      }
      _isLoggedIn = true;
      _authError = null;
    } else {
      _children = [];
      _selectedChild = null;
      _authError = response.errorMessage;
    }

    _isAuthLoading = false;
    notifyListeners();
    return response;
  }

  // Real Supabase Auth: Sign In with Email & Password
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    final response = await AuthService.signInWithEmailPassword(
      email: email,
      password: password,
    );

    if (response.status == AuthStatus.success && response.parent != null) {
      _parent = response.parent!;
      if (response.children != null && response.children!.isNotEmpty) {
        _children = response.children!;
        _selectedChild = _children.first;
      }
      _isLoggedIn = true;
      _authError = null;
    } else {
      _authError = response.errorMessage;
    }

    _isAuthLoading = false;
    notifyListeners();
    return response;
  }

  // Real Supabase Auth: Sign Up New Parent Account
  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    final response = await AuthService.signUpWithEmail(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (response.status == AuthStatus.success && response.parent != null) {
      _parent = response.parent!;
      if (response.children != null && response.children!.isNotEmpty) {
        _children = response.children!;
        _selectedChild = _children.first;
      }
      _isLoggedIn = true;
      _authError = null;
    } else {
      _authError = response.errorMessage;
    }

    _isAuthLoading = false;
    notifyListeners();
    return response;
  }

  // Update Profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? avatarUrl,
    String? relationship,
  }) async {
    final updated = await AuthService.updateParentProfile(
      currentParent: _parent,
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
      relationship: relationship,
    );

    if (updated != null) {
      _parent = updated;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Update Password
  Future<AuthResponse> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await AuthService.updatePassword(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  // Parent Logout & Secure State Clear
  Future<void> logout() async {
    await AuthService.clearSession();
    _isLoggedIn = false;
    _children = [];
    _selectedChild = null;
    _selectedBottomNavIndex = 0;

    // Reset module caches to prevent data leakage on account switching
    _todayAttendance = null;
    _activeAttendanceSummary = null;
    _activeHomeworkList = null;
    _activeTimetableList = null;
    _activeResultsList = null;
    _activeFeeSummary = null;
    _activeNoticesList = null;
    _activeNotificationsList = null;

    notifyListeners();
  }

  // Theme Mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Child Switching
  void selectChild(StudentModel child) {
    if (_selectedChild == null || _selectedChild!.id != child.id) {
      _selectedChild = child;
      _aiMessages = [
        AiMessageModel(
          id: 'AI-SWITCH-${DateTime.now().millisecondsSinceEpoch}',
          text: 'Switched profile to ${_selectedChild!.name} (${_selectedChild!.className}). How can I assist you with ${_selectedChild!.name}\'s academics today?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
      loadAttendanceForSelectedChild();
      loadHomeworkForSelectedChild();
      loadTimetableForSelectedChild();
      loadResultsForSelectedChild();
      loadFeeSummaryForSelectedChild();
      loadNoticesForSelectedChild();
      loadNotificationsForSelectedChild();
      notifyListeners();
    }
  }

  void setBottomNavIndex(int index) {
    _selectedBottomNavIndex = index;
    notifyListeners();
  }

  // Pull to refresh simulation
  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _lastUpdatedTime = 'Just now';
    _isRefreshing = false;
    notifyListeners();
  }

  // PTM Access Code Linking Flow
  PtmAccessCodeModel? validatePtmCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    final match = MockData.availablePtmCodes.where((c) => c.code == cleanCode).toList();
    if (match.isNotEmpty && !match.first.isUsed) {
      return match.first;
    }
    return null;
  }

  bool confirmLinkChild(PtmAccessCodeModel codeModel) {
    final newStudent = codeModel.studentPreview;
    if (!_children.any((s) => s.id == newStudent.id)) {
      _children.add(newStudent);
      _selectedChild = newStudent;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Child-Specific Data Getters
  MonthlyAttendanceSummary get currentAttendance {
    if (_activeAttendanceSummary != null) {
      return _activeAttendanceSummary!;
    }
    return const MonthlyAttendanceSummary(
      monthYear: 'September 2026',
      totalWorkingDays: 0,
      presentDays: 0,
      absentDays: 0,
      lateDays: 0,
      holidayDays: 0,
      percentage: 0.0,
      dailyRecords: [],
    );
  }

  FeeSummaryModel get currentFeeSummary {
    if (_activeFeeSummary != null) {
      return _activeFeeSummary!;
    }
    return FeeSummaryModel.fromData(
      studentId: _selectedChild?.id ?? '',
      schoolId: _selectedChild?.schoolId ?? '',
      academicYearId: _selectedChild?.academicYear ?? '',
    );
  }

  List<HomeworkModel> get currentHomeworkList {
    if (_activeHomeworkList != null) {
      return _activeHomeworkList!;
    }
    return [];
  }

  List<ExamModel> get currentExamsList {
    return [];
  }

  List<ExamResultModel> get currentResultsList {
    if (_activeResultsList != null) {
      return _activeResultsList!;
    }
    return [];
  }

  Map<String, List<TimetableEntryModel>> get currentTimetable {
    if (_activeTimetableList != null && _activeTimetableList!.isNotEmpty) {
      final Map<String, List<TimetableEntryModel>> map = {
        'Monday': [],
        'Tuesday': [],
        'Wednesday': [],
        'Thursday': [],
        'Friday': [],
        'Saturday': [],
      };
      for (final entry in _activeTimetableList!) {
        final day = entry.dayOfWeek.substring(0, 1).toUpperCase() + entry.dayOfWeek.substring(1).toLowerCase();
        if (map.containsKey(day)) {
          map[day]!.add(entry);
        } else {
          map[day] = [entry];
        }
      }
      return map;
    }
    return {};
  }

  PtmModel? get currentPtmSchedule {
    if (_selectedChild == null) return null;
    return MockData.ptmSchedules[_selectedChild!.id];
  }

  List<DocumentModel> get currentDocuments {
    if (_selectedChild == null) return [];
    return MockData.getDocuments(_selectedChild!.id);
  }

  List<MessageThread> get currentMessagesList {
    return [];
  }

  int get unreadMessagesCount {
    return currentMessagesList.fold(0, (sum, t) => sum + t.unreadCount);
  }

  TransportModel? get currentTransport {
    return null;
  }

  List<CalendarEventModel> get calendarEvents => MockData.calendarEvents;

  TimetableEntryModel? get nextClassEntry {
    final timetable = currentTimetable;
    final mondayClasses = timetable['MONDAY'] ?? timetable['Monday'] ?? [];
    if (mondayClasses.isNotEmpty) {
      return mondayClasses.firstWhere(
        (e) => !e.isBreak,
        orElse: () => mondayClasses.first,
      );
    }
    return null;
  }

  List<NoticeModel> get notices => _activeNoticesList ?? [];

  List<AppNotificationModel> get notifications => _activeNotificationsList ?? _notifications;

  // Messaging Interactions
  void sendMessageReply(String threadId, String text) {
    if (text.trim().isEmpty) return;
  }

  void markThreadRead(String threadId) {
  }

  // AI Assistant Query Handler
  void sendAiPrompt(String userQuery) {
    if (userQuery.trim().isEmpty) return;

    final userMsg = AiMessageModel(
      id: 'AI-USR-${DateTime.now().millisecondsSinceEpoch}',
      text: userQuery,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _aiMessages.add(userMsg);
    notifyListeners();

    if (_selectedChild == null) {
      final botMsg = AiMessageModel(
        id: 'AI-BOT-${DateTime.now().millisecondsSinceEpoch}',
        text: 'Please link a student profile using your school\'s Parent Access Code to access student information.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _aiMessages.add(botMsg);
      notifyListeners();
      return;
    }

    final childName = _selectedChild!.name;
    final queryLower = userQuery.toLowerCase();
    String responseText;

    if (queryLower.contains('attendance')) {
      final att = currentAttendance;
      responseText = '$childName\'s overall attendance for ${att.monthYear} is ${att.percentage.toInt()}% with ${att.presentDays} days present, ${att.absentDays} days absent, and ${att.lateDays} day late out of ${att.totalWorkingDays} working days.';
    } else if (queryLower.contains('fee') || queryLower.contains('fees') || queryLower.contains('due')) {
      final fee = currentFeeSummary;
      if (fee.pendingAmount > 0) {
        final dueStr = fee.dueDate != null ? 'due by ${DateFormatter.formatShort(fee.dueDate!)}' : 'due soon';
        responseText = '$childName has a pending fee balance of ${CurrencyFormatter.formatINR(fee.pendingAmount)} $dueStr. Net fee is ${CurrencyFormatter.formatINR(fee.netFee)}, and ${CurrencyFormatter.formatINR(fee.paidAmount)} has already been paid.';
      } else {
        responseText = 'All academic fees for $childName are fully settled (${CurrencyFormatter.formatINR(fee.netFee)} paid, ₹0 pending).';
      }
    } else if (queryLower.contains('homework') || queryLower.contains('assignment')) {
      final hwList = currentHomeworkList;
      final pending = hwList.where((h) => !h.isCompleted).toList();
      if (pending.isNotEmpty) {
        final titles = pending.map((h) => '${h.subject}: "${h.title}" (Due ${DateFormatter.formatShort(h.dueDate)})').join('\n• ');
        responseText = '$childName currently has ${pending.length} pending homework assignment(s):\n• $titles';
      } else {
        responseText = 'Great news! $childName has no pending homework assignments.';
      }
    } else if (queryLower.contains('exam') || queryLower.contains('test')) {
      final exams = currentExamsList;
      final upcoming = exams.where((e) => e.isUpcoming).toList();
      if (upcoming.isNotEmpty) {
        final examDetails = upcoming.map((e) => '${e.subject} on ${DateFormatter.formatShort(e.examDate)} (${e.timeSlot})').join(', ');
        responseText = 'The next upcoming examination(s) for $childName are: $examDetails.';
      } else {
        responseText = 'There are no upcoming examinations scheduled in the next 14 days.';
      }
    } else if (queryLower.contains('bus') || queryLower.contains('transport')) {
      final trans = currentTransport;
      if (trans != null) {
        responseText = '$childName travels via ${trans.busNumber} (${trans.routeName}). Driver: ${trans.driverName} (${trans.driverPhone}). Current status: ${trans.currentStatus}.';
      } else {
        responseText = 'No bus route details available for $childName.';
      }
    } else {
      responseText = 'Regarding $childName (Class ${_selectedChild!.className}): Attendance is ${currentAttendance.percentage.toInt()}%, Pending fee is ${CurrencyFormatter.formatINR(currentFeeSummary.pendingAmount)}, and Class Teacher is ${_selectedChild!.classTeacher}. How else can I assist?';
    }

    final botMsg = AiMessageModel(
      id: 'AI-BOT-${DateTime.now().millisecondsSinceEpoch}',
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _aiMessages.add(botMsg);
    notifyListeners();
  }

  // Interactive Mutations
  void toggleHomeworkCompletion(String homeworkId) {
    if (_activeHomeworkList != null) {
      final index = _activeHomeworkList!.indexWhere((h) => h.id == homeworkId);
      if (index != -1) {
        _activeHomeworkList![index] = _activeHomeworkList![index].copyWith(
          isCompleted: !_activeHomeworkList![index].isCompleted,
        );
        notifyListeners();
      }
    }
  }

  void markAllNotificationsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void submitCorrectionRequest({
    required String fieldName,
    required String currentValue,
    required String requestedValue,
    required String reason,
  }) {
    if (_selectedChild == null) return;

    final newReq = CorrectionRequestModel(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _selectedChild!.id,
      studentName: _selectedChild!.name,
      fieldName: fieldName,
      currentValue: currentValue,
      requestedValue: requestedValue,
      reason: reason,
      dateSubmitted: DateTime.now(),
    );
    _correctionRequests.add(newReq);
    notifyListeners();
  }
}
