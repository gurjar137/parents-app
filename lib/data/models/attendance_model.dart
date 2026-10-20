enum AttendanceStatus { present, absent, late, leave, holiday }

class DailyAttendance {
  final String id;
  final String studentId;
  final String schoolId;
  final DateTime date;
  final AttendanceStatus status;
  final String? remark;

  const DailyAttendance({
    this.id = '',
    this.studentId = '',
    this.schoolId = '',
    required this.date,
    required this.status,
    this.remark,
  });

  factory DailyAttendance.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['status'] ?? '').toString().toLowerCase().trim();
    AttendanceStatus parsedStatus;

    if (rawStatus == 'absent') {
      parsedStatus = AttendanceStatus.absent;
    } else if (rawStatus == 'late') {
      parsedStatus = AttendanceStatus.late;
    } else if (rawStatus == 'leave' || rawStatus == 'excused' || rawStatus == 'on_leave') {
      parsedStatus = AttendanceStatus.leave;
    } else if (rawStatus == 'holiday') {
      parsedStatus = AttendanceStatus.holiday;
    } else {
      parsedStatus = AttendanceStatus.present;
    }

    DateTime parsedDate;
    final rawDate = map['attendance_date'] ?? map['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    return DailyAttendance(
      id: (map['id'] ?? '').toString(),
      studentId: (map['student_id'] ?? '').toString(),
      schoolId: (map['school_id'] ?? '').toString(),
      date: parsedDate,
      status: parsedStatus,
      remark: (map['remarks'] ?? map['remark'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'date': date.toIso8601String().split('T').first,
      'status': status.name,
      'remarks': remark,
    };
  }
}

class MonthlyAttendanceSummary {
  final String monthYear; // e.g. "September 2026"
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  final int holidayDays;
  final double percentage;
  final List<DailyAttendance> dailyRecords;

  bool get hasRecords => totalWorkingDays > 0;

  const MonthlyAttendanceSummary({
    required this.monthYear,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    this.leaveDays = 0,
    required this.holidayDays,
    required this.percentage,
    required this.dailyRecords,
  });

  factory MonthlyAttendanceSummary.fromDailyRecords({
    required String monthYear,
    required List<DailyAttendance> records,
  }) {
    int present = 0;
    int absent = 0;
    int lateCount = 0;
    int leave = 0;
    int holiday = 0;

    for (final r in records) {
      switch (r.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.late:
          lateCount++;
          break;
        case AttendanceStatus.leave:
          leave++;
          break;
        case AttendanceStatus.holiday:
          holiday++;
          break;
      }
    }

    final totalCounted = present + absent + lateCount + leave;
    // No marks recorded = 0% with hasRecords false; the screen says "no
    // attendance recorded" instead of showing an invented 100%.
    final double calcPercentage = totalCounted > 0
        ? ((present + lateCount) / totalCounted) * 100.0
        : 0.0;

    return MonthlyAttendanceSummary(
      monthYear: monthYear,
      totalWorkingDays: totalCounted,
      presentDays: present,
      absentDays: absent,
      lateDays: lateCount,
      leaveDays: leave,
      holidayDays: holiday,
      percentage: calcPercentage,
      dailyRecords: records,
    );
  }
}
