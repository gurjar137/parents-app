import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;

import '../core/services/attendance_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/fee_service.dart';
import '../core/services/homework_service.dart';
import '../core/services/link_child_service.dart';
import '../core/services/notice_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/parent_api.dart';
import '../core/services/result_service.dart';
import '../core/services/school_service.dart';
import '../core/services/supabase_service.dart';
import '../core/services/timetable_service.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/ai_message_model.dart';
import '../data/models/attendance_model.dart';
import '../data/models/calendar_event_model.dart';
import '../data/models/correction_request_model.dart';
import '../data/models/document_model.dart';
import '../data/models/exam_model.dart';
import '../data/models/fee_model.dart';
import '../data/models/homework_model.dart';
import '../data/models/message_model.dart';
import '../data/models/notice_model.dart';
import '../data/models/notification_model.dart';
import '../data/models/parent_model.dart';
import '../data/models/ptm_model.dart';
import '../data/models/result_model.dart';
import '../data/models/school_brand_model.dart';
import '../data/models/student_model.dart';
import '../data/models/timetable_model.dart';
import '../data/models/transport_model.dart';

/// App state of the Parents App.
///
/// * Who is signed in and which children they may see comes ONLY from the
///   server (`parent_get_session`), never from device storage.
/// * Every per-child load carries a token; a response that arrives after the
///   parent switched child (or signed out) is discarded.
/// * A failed load sets an error message and keeps "no data" distinct from
///   "empty": the lists stay null until a load succeeds.
class ParentAppProvider extends ChangeNotifier {
  ParentAppProvider({bool autoStart = true}) {
    if (autoStart) {
      _setupAuthListener();
      checkExistingSession();
    } else {
      _isSessionChecking = false;
    }
  }

  ParentModel _parent = _emptyParent;
  List<StudentModel> _children = [];
  StudentModel? _selectedChild;
  SchoolBrandModel _branding = SchoolBrandModel.defaultNeutral();
  int _loadToken = 0;
  StreamSubscription<AuthState>? _authSub;

  bool _isLoggedIn = false;
  bool _isAuthLoading = false;
  bool _isSessionChecking = true;
  bool _isDashboardLoading = false;
  String? _authError;
  String? _dashboardError;
  String? _accountNotice;

  // Per-feature state. null list = not loaded (or failed), [] = loaded, empty.
  bool _isAttendanceLoading = false;
  String? _attendanceError;
  DailyAttendance? _todayAttendance;
  MonthlyAttendanceSummary? _activeAttendanceSummary;
  int _attendanceYear = DateTime.now().year;
  int _attendanceMonth = DateTime.now().month;

  bool _isHomeworkLoading = false;
  String? _homeworkError;
  List<HomeworkModel>? _activeHomeworkList;

  bool _isTimetableLoading = false;
  String? _timetableError;
  List<TimetableEntryModel>? _activeTimetableList;

  bool _isResultsLoading = false;
  String? _resultsError;
  List<ExamResultModel>? _activeResultsList;

  bool _isExamsLoading = false;
  String? _examsError;
  List<ExamModel>? _activeExamsList;

  bool _isFeesLoading = false;
  String? _feesError;
  FeeSummaryModel? _activeFeeSummary;

  bool _isNoticesLoading = false;
  String? _noticesError;
  List<NoticeModel>? _activeNoticesList;

  bool _isNotificationsLoading = false;
  String? _notificationsError;
  List<AppNotificationModel>? _activeNotificationsList;

  List<AiMessageModel> _aiMessages = [];
  ThemeMode _themeMode = ThemeMode.light;
  int _selectedBottomNavIndex = 0;
  DateTime? _lastSyncedAt;
  bool _isRefreshing = false;

  static const ParentModel _emptyParent = ParentModel(
    id: '',
    name: '',
    email: '',
    phone: '',
    avatarUrl: '',
    childrenIds: [],
  );

  static const StudentModel _emptyStudent = StudentModel(
    id: '',
    name: 'No Child Linked',
    className: '',
    grade: '',
    section: '',
    rollNo: 0,
    admissionNo: '',
    schoolId: '',
    academicYear: '',
    avatarUrl: '',
    classTeacher: '',
    classmateCount: 0,
    houseName: '',
  );

  // ------------------------------------------------------------------
  // Getters
  // ------------------------------------------------------------------
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthLoading => _isAuthLoading;
  bool get isSessionChecking => _isSessionChecking;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get isAttendanceLoading => _isAttendanceLoading;
  bool get isHomeworkLoading => _isHomeworkLoading;
  bool get isTimetableLoading => _isTimetableLoading;
  bool get isResultsLoading => _isResultsLoading;
  bool get isExamsLoading => _isExamsLoading;
  bool get isFeesLoading => _isFeesLoading;
  bool get isNoticesLoading => _isNoticesLoading;
  bool get isNotificationsLoading => _isNotificationsLoading;
  String? get authError => _authError;
  String? get dashboardError => _dashboardError;

  /// Set when the signed-in account cannot use the Parents App (staff login,
  /// inactive account). Shown on the link screen.
  String? get accountNotice => _accountNotice;
  String? get attendanceError => _attendanceError;
  String? get homeworkError => _homeworkError;
  String? get timetableError => _timetableError;
  String? get resultsError => _resultsError;
  String? get examsError => _examsError;
  String? get feesError => _feesError;
  String? get noticesError => _noticesError;
  String? get notificationsError => _notificationsError;

  ParentModel get parent => _parent;
  List<StudentModel> get children => List.unmodifiable(_children);
  StudentModel get selectedChild => _selectedChild ?? _emptyStudent;
  bool get isChildLinked => _selectedChild != null && _selectedChild!.id.isNotEmpty;
  SchoolBrandModel get branding => _branding;
  ThemeMode get themeMode => _themeMode;
  int get selectedBottomNavIndex => _selectedBottomNavIndex;
  bool get isRefreshing => _isRefreshing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String get lastUpdatedTime =>
      _lastSyncedAt == null ? 'Not synced yet' : 'Updated ${DateFormatter.formatTime(_lastSyncedAt!)}';

  DailyAttendance? get todayAttendance => _todayAttendance;
  int get attendanceYear => _attendanceYear;
  int get attendanceMonth => _attendanceMonth;

  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  /// Parent's own name (no name is guessed from the student record).
  String get currentFatherName => _parent.name.trim();

  MonthlyAttendanceSummary get currentAttendance =>
      _activeAttendanceSummary ??
      MonthlyAttendanceSummary.fromDailyRecords(
        monthYear: DateFormatter.formatMonthYear(DateTime(_attendanceYear, _attendanceMonth)),
        records: const [],
      );

  FeeSummaryModel get currentFeeSummary => _activeFeeSummary ?? FeeSummaryModel.empty(_selectedChild?.id ?? '');
  bool get hasFeeData => _activeFeeSummary != null;
  bool get hasAttendanceData => _activeAttendanceSummary != null;
  bool get hasHomeworkData => _activeHomeworkList != null;
  bool get hasTimetableData => _activeTimetableList != null;
  bool get hasResultsData => _activeResultsList != null;
  bool get hasExamsData => _activeExamsList != null;
  bool get hasNoticesData => _activeNoticesList != null;
  bool get hasNotificationsData => _activeNotificationsList != null;

  List<HomeworkModel> get currentHomeworkList => _activeHomeworkList ?? const [];
  List<ExamModel> get currentExamsList => _activeExamsList ?? const [];
  List<ExamResultModel> get currentResultsList => _activeResultsList ?? const [];
  List<NoticeModel> get notices => _activeNoticesList ?? const [];
  List<AppNotificationModel> get notifications => _activeNotificationsList ?? const [];

  Map<String, List<TimetableEntryModel>> get currentTimetable {
    final list = _activeTimetableList;
    if (list == null || list.isEmpty) return {};
    final map = <String, List<TimetableEntryModel>>{};
    for (final entry in list) {
      map.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
    }
    return map;
  }

  /// Next class today (or the first class of the next school day).
  TimetableEntryModel? get nextClassEntry {
    final timetable = currentTimetable;
    if (timetable.isEmpty) return null;
    final now = DateTime.now();
    for (var offset = 0; offset < 7; offset++) {
      final day = TimetableEntryModel.weekdays[(now.weekday - 1 + offset) % 7];
      final classes = (timetable[day] ?? const <TimetableEntryModel>[]).where((e) => !e.isBreak).toList();
      if (classes.isEmpty) continue;
      if (offset > 0) return classes.first;
      final nowMinutes = now.hour * 60 + now.minute;
      for (final c in classes) {
        final m = _minutesOf(c.startTime);
        if (m == null || m >= nowMinutes) return c;
      }
    }
    return null;
  }

  static int? _minutesOf(String time) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?').firstMatch(time.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ampm = m.group(3)?.toLowerCase();
    if (ampm == 'pm' && h < 12) h += 12;
    if (ampm == 'am' && h == 12) h = 0;
    return h * 60 + min;
  }

  // Features without a School OS data source. They return nothing and the
  // screens say the feature is not available (no demo data).
  PtmModel? get currentPtmSchedule => null;
  List<DocumentModel> get currentDocuments => const [];
  List<CalendarEventModel> get calendarEvents => const [];
  TransportModel? get currentTransport => null;
  List<MessageThread> get currentMessagesList => const [];
  int get unreadMessagesCount => 0;
  List<CorrectionRequestModel> get correctionRequests => const [];
  List<AiMessageModel> get aiMessages => _aiMessages;

  // ------------------------------------------------------------------
  // Session
  // ------------------------------------------------------------------
  void _setupAuthListener() {
    if (!SupabaseService.isInitialized) return;
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut && _isLoggedIn) {
        _resetState();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> checkExistingSession() async {
    _isSessionChecking = true;
    notifyListeners();
    try {
      if (AuthService.currentSession != null) {
        await _loadSessionAndChildren();
      } else {
        _resetState();
      }
    } catch (e) {
      // Signed in but the server could not be reached: stay signed in and let
      // the dashboard show the error with Retry (no cached child data).
      _isLoggedIn = AuthService.currentSession != null;
      _dashboardError = parentErrorMessage(e);
    }
    _isSessionChecking = false;
    notifyListeners();
  }

  /// Loads the parent and linked children from the server and reloads the
  /// selected child's data. Keeps the current child selected if still linked.
  Future<void> _loadSessionAndChildren() async {
    final session = await AuthService.loadSession();
    _parent = session.parent;
    _isLoggedIn = true;
    _dashboardError = null;
    _accountNotice = session.isStaffAccount
        ? 'This is a school staff account. The Parents App needs a parent account.'
        : (session.isInactive ? 'Your parent account is inactive. Please contact the school office.' : null);

    final previousId = _selectedChild?.id;
    _children = List.of(session.children);
    if (_children.isEmpty) {
      _selectChildInternal(null);
      return;
    }
    final keep = _children.where((c) => c.id == previousId).toList();
    _selectChildInternal(keep.isNotEmpty ? keep.first : _children.first, force: keep.isEmpty || previousId == null);
  }

  void _resetState() {
    _loadToken++;
    _isLoggedIn = false;
    _parent = _emptyParent;
    _children = [];
    _selectedChild = null;
    _branding = SchoolBrandModel.defaultNeutral();
    _selectedBottomNavIndex = 0;
    _accountNotice = null;
    _dashboardError = null;
    _lastSyncedAt = null;
    _aiMessages = [];
    _clearChildData();
    SchoolService.clearCache();
  }

  void _clearChildData() {
    _todayAttendance = null;
    _activeAttendanceSummary = null;
    _activeHomeworkList = null;
    _activeTimetableList = null;
    _activeResultsList = null;
    _activeExamsList = null;
    _activeFeeSummary = null;
    _activeNoticesList = null;
    _activeNotificationsList = null;
    _attendanceError = _homeworkError = _timetableError = _resultsError = _examsError = null;
    _feesError = _noticesError = _notificationsError = null;
    _attendanceYear = DateTime.now().year;
    _attendanceMonth = DateTime.now().month;
  }

  Future<AuthResponse> loginWithEmail({required String email, required String password}) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    final response = await AuthService.signInWithEmailPassword(email: email, password: password);
    if (response.status == AuthStatus.success) {
      try {
        await _loadSessionAndChildren();
      } catch (e) {
        _isLoggedIn = true;
        _dashboardError = parentErrorMessage(e);
      }
    } else {
      _authError = response.errorMessage;
    }

    _isAuthLoading = false;
    notifyListeners();
    return response;
  }

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
    if (response.status == AuthStatus.success) {
      try {
        await _loadSessionAndChildren();
      } catch (e) {
        _isLoggedIn = true;
        _dashboardError = parentErrorMessage(e);
      }
    } else {
      _authError = response.errorMessage;
    }

    _isAuthLoading = false;
    notifyListeners();
    return response;
  }

  /// Redeems a Parent Access Code, then reloads the children from the server.
  Future<LinkChildResponse> linkChildWithCode({required String codeOrStudentId, String relationship = 'Parent'}) async {
    final res = await LinkChildService.claimChild(accessCode: codeOrStudentId, relationship: relationship);
    if (res.status != LinkStatus.success && res.status != LinkStatus.alreadyLinked) return res;

    final studentId = res.studentId;
    try {
      await _loadSessionAndChildren();
    } catch (e) {
      return LinkChildResponse(
        status: LinkStatus.networkError,
        errorMessage: 'The child was linked, but the list could not be refreshed: ${parentErrorMessage(e)}',
      );
    }
    final linked = _children.where((c) => c.id == studentId).toList();
    if (linked.isNotEmpty) selectChild(linked.first);
    notifyListeners();
    if (linked.isEmpty) {
      // Claimed on the server but not visible in the session (e.g. the
      // account is inactive): report it instead of showing success.
      return LinkChildResponse(
        status: LinkStatus.backendError,
        errorMessage: _accountNotice ?? 'The child could not be loaded after linking. Please contact the school office.',
      );
    }
    return LinkChildResponse(
      status: res.status,
      student: linked.first,
      studentId: studentId,
      userMessage: res.userMessage,
    );
  }

  Future<void> logout() async {
    await AuthService.clearSession();
    _resetState();
    notifyListeners();
  }

  Future<void> retryDashboardLoad() async {
    _isDashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      await _loadSessionAndChildren();
    } catch (e) {
      _dashboardError = parentErrorMessage(e);
    }
    _isDashboardLoading = false;
    notifyListeners();
  }

  /// Pull-to-refresh: re-reads the session (links may have been revoked) and
  /// every dataset of the selected child from the server.
  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      await _loadSessionAndChildren();
      await _loadAllForSelectedChild();
    } catch (e) {
      _dashboardError = parentErrorMessage(e);
    }
    _isRefreshing = false;
    notifyListeners();
  }

  Future<bool> updateProfile({required String name, required String phone, String? avatarUrl, String? relationship}) async {
    try {
      await AuthService.updateParentContact(name: name, phone: phone);
      _parent = _parent.copyWith(name: name.trim(), phone: phone.trim());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResponse> updatePassword({required String newPassword, required String confirmPassword}) {
    return AuthService.updatePassword(newPassword: newPassword, confirmPassword: confirmPassword);
  }

  // ------------------------------------------------------------------
  // Child selection
  // ------------------------------------------------------------------
  void selectChild(StudentModel child) {
    if (!_children.any((c) => c.id == child.id)) return; // only server-verified children
    if (_selectedChild?.id == child.id) return;
    _selectChildInternal(child, force: true);
    notifyListeners();
  }

  void _selectChildInternal(StudentModel? child, {bool force = false}) {
    final changed = force || _selectedChild?.id != child?.id;
    _selectedChild = child;
    if (!changed) {
      // Same child after a session reload: refresh its data in place.
      if (child != null) _loadAllForSelectedChild();
      return;
    }
    _loadToken++;
    _clearChildData();
    _branding = SchoolBrandModel.defaultNeutral();
    _aiMessages = [];
    if (child != null) _loadAllForSelectedChild();
  }

  Future<void> _loadAllForSelectedChild() async {
    if (_selectedChild == null) return;
    await Future.wait([
      _loadSchoolForSelectedChild(),
      loadAttendanceForSelectedChild(),
      loadHomeworkForSelectedChild(),
      loadTimetableForSelectedChild(),
      loadFeeSummaryForSelectedChild(),
      loadResultsForSelectedChild(),
      loadExamsForSelectedChild(),
      loadNoticesForSelectedChild(),
      loadNotificationsForSelectedChild(),
    ]);
    _lastSyncedAt = DateTime.now();
    notifyListeners();
  }

  /// Runs [load] for the selected child and applies the result only if the
  /// same child is still selected when it completes.
  Future<void> _guarded<T>({
    required Future<T> Function(String studentId) load,
    required void Function(bool loading) setLoading,
    required void Function(String? error) setError,
    required void Function(T value) apply,
  }) async {
    final child = _selectedChild;
    if (child == null) return;
    final token = _loadToken;
    setLoading(true);
    setError(null);
    notifyListeners();
    try {
      final value = await load(child.id);
      if (token != _loadToken || _selectedChild?.id != child.id) return;
      apply(value);
    } catch (e) {
      if (token != _loadToken || _selectedChild?.id != child.id) return;
      setError(parentErrorMessage(e));
      if (e is ParentDataException && e.kind == ParentDataErrorKind.notAuthorized) {
        // The link was revoked or the session ended: re-read the session.
        unawaited(retryDashboardLoad());
      }
    } finally {
      if (token == _loadToken && _selectedChild?.id == child.id) {
        setLoading(false);
        notifyListeners();
      }
    }
  }

  Future<void> _loadSchoolForSelectedChild() => _guarded<SchoolBrandModel>(
        load: (id) => SchoolService.fetchSchoolForStudent(id),
        setLoading: (_) {},
        setError: (_) {},
        apply: (b) => _branding = b,
      );

  Future<void> loadAttendanceForSelectedChild() => _guarded<(MonthlyAttendanceSummary, DailyAttendance?)>(
        load: (id) async {
          final month = await AttendanceService.fetchAttendanceForStudent(
              studentId: id, year: _attendanceYear, month: _attendanceMonth);
          final today = await AttendanceService.fetchTodayAttendance(studentId: id);
          return (month, today);
        },
        setLoading: (v) => _isAttendanceLoading = v,
        setError: (e) => _attendanceError = e,
        apply: (r) {
          _activeAttendanceSummary = r.$1;
          _todayAttendance = r.$2;
        },
      );

  Future<void> changeAttendanceMonth(int year, int month) async {
    _attendanceYear = year;
    _attendanceMonth = month;
    _activeAttendanceSummary = null;
    await loadAttendanceForSelectedChild();
  }

  Future<void> loadHomeworkForSelectedChild() => _guarded<List<HomeworkModel>>(
        load: (id) => HomeworkService.fetchHomeworkForStudent(studentId: id),
        setLoading: (v) => _isHomeworkLoading = v,
        setError: (e) => _homeworkError = e,
        apply: (v) => _activeHomeworkList = v,
      );

  Future<void> loadTimetableForSelectedChild() => _guarded<List<TimetableEntryModel>>(
        load: (id) => TimetableService.fetchTimetableForStudent(studentId: id),
        setLoading: (v) => _isTimetableLoading = v,
        setError: (e) => _timetableError = e,
        apply: (v) => _activeTimetableList = v,
      );

  Future<void> loadFeeSummaryForSelectedChild() => _guarded<FeeSummaryModel>(
        load: (id) => FeeService.fetchFeeSummaryForStudent(studentId: id),
        setLoading: (v) => _isFeesLoading = v,
        setError: (e) => _feesError = e,
        apply: (v) => _activeFeeSummary = v,
      );

  Future<void> loadResultsForSelectedChild() => _guarded<List<ExamResultModel>>(
        load: (id) => ResultService.fetchResultsForStudent(studentId: id),
        setLoading: (v) => _isResultsLoading = v,
        setError: (e) => _resultsError = e,
        apply: (v) => _activeResultsList = v,
      );

  Future<void> loadExamsForSelectedChild() => _guarded<List<ExamModel>>(
        load: (id) => ResultService.fetchExamScheduleForStudent(studentId: id),
        setLoading: (v) => _isExamsLoading = v,
        setError: (e) => _examsError = e,
        apply: (v) => _activeExamsList = v,
      );

  Future<void> loadNoticesForSelectedChild() => _guarded<List<NoticeModel>>(
        load: (id) => NoticeService.fetchNoticesForParent(studentId: id),
        setLoading: (v) => _isNoticesLoading = v,
        setError: (e) => _noticesError = e,
        apply: (v) => _activeNoticesList = v,
      );

  Future<void> loadNotificationsForSelectedChild() => _guarded<List<AppNotificationModel>>(
        load: (id) => NotificationService.fetchNotificationsForParent(studentId: id),
        setLoading: (v) => _isNotificationsLoading = v,
        setError: (e) => _notificationsError = e,
        apply: (v) => _activeNotificationsList = v,
      );

  /// Records the read on the server first; the badge changes only if it
  /// succeeded. Returns false (and keeps the item unread) on failure.
  Future<bool> markAppNotificationAsRead(String notificationId) async {
    try {
      await NotificationService.markRead(ids: [notificationId]);
    } catch (_) {
      return false;
    }
    _activeNotificationsList = _activeNotificationsList
        ?.map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
    return true;
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      await NotificationService.markRead();
    } catch (_) {
      return false;
    }
    _activeNotificationsList = _activeNotificationsList?.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    return true;
  }

  Future<bool> markNoticeAsRead(String noticeId) async {
    try {
      await NoticeService.markNoticeAsRead(noticeId: noticeId);
    } catch (_) {
      return false;
    }
    _activeNoticesList = _activeNoticesList?.map((n) => n.id == noticeId ? n.copyWith(isRead: true) : n).toList();
    // The notice's announcement notification is read now as well.
    _activeNotificationsList = _activeNotificationsList
        ?.map((n) => n.targetType == 'notice' && n.targetId == noticeId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------------
  // UI preferences
  // ------------------------------------------------------------------
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

  void setBottomNavIndex(int index) {
    _selectedBottomNavIndex = index;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Features that have no backend workflow (product decision pending).
  // They do nothing and report that, instead of faking success.
  // ------------------------------------------------------------------
  bool sendMessageReply(String threadId, String text) => false;
  void markThreadRead(String threadId) {}

  /// Correction requests are not supported by School OS yet: nothing is sent.
  bool submitCorrectionRequest({
    required String fieldName,
    required String currentValue,
    required String requestedValue,
    required String reason,
  }) =>
      false;

  // ------------------------------------------------------------------
  // Assistant: answers only from data already loaded from the school.
  // ------------------------------------------------------------------
  void sendAiPrompt(String userQuery) {
    if (userQuery.trim().isEmpty) return;
    _aiMessages.add(AiMessageModel(
      id: 'AI-USR-${DateTime.now().microsecondsSinceEpoch}',
      text: userQuery,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    String reply;
    final child = _selectedChild;
    if (child == null) {
      reply = 'Please link your child with the Parent Access Code from your school first.';
    } else {
      final q = userQuery.toLowerCase();
      final name = child.name;
      if (q.contains('attendance')) {
        final att = _activeAttendanceSummary;
        reply = att == null
            ? 'Attendance for $name has not loaded yet. Open Attendance and pull to refresh.'
            : (!att.hasRecords
                ? 'No attendance has been recorded for $name in ${att.monthYear}.'
                : '$name: ${att.percentage.toStringAsFixed(0)}% in ${att.monthYear} '
                    '(${att.presentDays} present, ${att.lateDays} late, ${att.absentDays} absent, ${att.leaveDays} leave).');
      } else if (q.contains('fee') || q.contains('due') || q.contains('payment')) {
        final fee = _activeFeeSummary;
        if (fee == null) {
          reply = 'Fee details for $name have not loaded yet. Open Fees and pull to refresh.';
        } else if (!fee.hasFeeAccount) {
          reply = 'The school has not assigned fees to $name yet.';
        } else {
          final due = fee.dueDate != null ? ' (due ${DateFormatter.formatShort(fee.dueDate!)})' : '';
          reply = 'Net fee ${CurrencyFormatter.formatINR(fee.netFee)}, paid ${CurrencyFormatter.formatINR(fee.paidAmount)}, '
              'balance ${CurrencyFormatter.formatINR(fee.outstandingAmount)}$due.';
        }
      } else if (q.contains('homework') || q.contains('assignment')) {
        final hw = _activeHomeworkList;
        if (hw == null) {
          reply = 'Homework has not loaded yet.';
        } else {
          final upcoming = hw.where((h) => !h.isOverdue).toList();
          reply = upcoming.isEmpty
              ? 'No upcoming homework for $name.'
              : 'Upcoming homework:\n• ${upcoming.map((h) => '${h.subject}: ${h.title} (due ${DateFormatter.formatShort(h.dueDate)})').join('\n• ')}';
        }
      } else if (q.contains('exam') || q.contains('test')) {
        final exams = _activeExamsList;
        final upcoming = (exams ?? const <ExamModel>[]).where((e) => e.isUpcoming).toList();
        reply = exams == null
            ? 'The exam schedule has not loaded yet.'
            : (upcoming.isEmpty
                ? 'No upcoming exams are scheduled for $name.'
                : 'Upcoming: ${upcoming.map((e) => '${e.title}${e.subject.isNotEmpty ? ' – ${e.subject}' : ''}'
                    '${e.examDate != null ? ' on ${DateFormatter.formatShort(e.examDate!)}' : ''}').join('; ')}.');
      } else {
        reply = 'I can summarise attendance, fees, homework and exams for $name from the school\'s records. What would you like to know?';
      }
    }

    _aiMessages.add(AiMessageModel(
      id: 'AI-BOT-${DateTime.now().microsecondsSinceEpoch}',
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Test hook: set the server-verified session without network calls.
  @visibleForTesting
  void debugSetSession(ParentModel parent, List<StudentModel> children) {
    _parent = parent;
    _children = List.of(children);
    _isLoggedIn = true;
    _isSessionChecking = false;
    _selectedChild = null;
    _selectChildInternal(children.isEmpty ? null : children.first, force: true);
    notifyListeners();
  }
}
