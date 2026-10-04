import 'package:flutter/material.dart';
import '../models/parent_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/homework_model.dart';
import '../models/fee_model.dart';
import '../models/result_model.dart';
import '../models/timetable_model.dart';
import '../models/notice_model.dart';
import '../models/notification_model.dart';
import '../models/ptm_access_code.dart';
import '../models/exam_model.dart';
import '../models/ptm_model.dart';
import '../models/document_model.dart';
import '../models/message_model.dart';
import '../models/transport_model.dart';
import '../models/calendar_event_model.dart';
import '../models/school_brand_model.dart';

class MockData {
  // Dynamic School Branding
  static const SchoolBrandModel defaultBranding = SchoolBrandModel(
    schoolName: 'St. Xavier International School',
    logoUrl: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?fit=crop&w=120&h=120',
    primaryColor: Color(0xFF1E293B),
    secondaryColor: Color(0xFF4F46E5),
    affiliation: 'CBSE Affiliation No. 2130892',
    motto: 'Excellence in Leadership & Knowledge',
  );

  // Parent (Rajesh Sharma)
  static final ParentModel currentParent = ParentModel(
    id: 'P-9042',
    name: 'Rajesh Sharma',
    email: 'rajesh.sharma@gmail.com',
    phone: '+91 98765 43210',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
    childrenIds: ['S-8017', 'S-5012'],
  );

  static ParentModel? findParentByUniqueId(String uniqueId) {
    final cleanId = uniqueId.trim().toUpperCase();
    if (cleanId == 'P-9042' ||
        cleanId == 'SXIS-PAR-9042' ||
        cleanId == 'KPM-PAR-1025' ||
        cleanId == 'PAR-1001' ||
        cleanId == 'DEMO') {
      return currentParent;
    }
    return null;
  }

  static List<StudentModel> getChildrenForParent(String parentId) {
    return children;
  }

  // Children
  static final List<StudentModel> children = [];

  // PTM Access Code Database for linking children
  static final List<PtmAccessCodeModel> availablePtmCodes = [];

  // Attendance Data - Rahul Sharma (94%)
  static MonthlyAttendanceSummary getAttendanceRahul() {
    List<DailyAttendance> records = [];
    for (int day = 1; day <= 31; day++) {
      final date = DateTime(2026, 8, day);
      final weekday = date.weekday;
      
      if (weekday == DateTime.sunday) {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.holiday, remark: 'Sunday'));
      } else if (day == 15) {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.holiday, remark: 'Independence Day'));
      } else if (day == 5) {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.absent, remark: 'Medical Leave'));
      } else if (day == 12) {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.late, remark: 'Late by 15 mins'));
      } else {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.present));
      }
    }

    return MonthlyAttendanceSummary(
      monthYear: 'August 2026',
      totalWorkingDays: 25,
      presentDays: 23,
      absentDays: 1,
      lateDays: 1,
      holidayDays: 7,
      percentage: 94.0,
      dailyRecords: records,
    );
  }

  // Attendance Data - Priya Sharma (96%)
  static MonthlyAttendanceSummary getAttendancePriya() {
    List<DailyAttendance> records = [];
    for (int day = 1; day <= 31; day++) {
      final date = DateTime(2026, 8, day);
      final weekday = date.weekday;

      if (weekday == DateTime.sunday) {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.holiday, remark: 'Sunday'));
      } else if (day == 15) {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.holiday, remark: 'Independence Day'));
      } else if (day == 8) {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.absent, remark: 'Family Function'));
      } else {
        records.add(DailyAttendance(date: date, status: AttendanceStatus.present));
      }
    }

    return MonthlyAttendanceSummary(
      monthYear: 'August 2026',
      totalWorkingDays: 25,
      presentDays: 24,
      absentDays: 1,
      lateDays: 0,
      holidayDays: 7,
      percentage: 96.0,
      dailyRecords: records,
    );
  }

  // Fees Data - Rahul (Total ₹45,000, Paid ₹30,000, Pending ₹15,000)
  static final FeeSummaryModel feeRahul = FeeSummaryModel(
    studentId: 'S-8017',
    grossFee: 45000,
    discountAmount: 0,
    waiverAmount: 0,
    netFee: 45000,
    paidAmount: 30000,
    outstandingAmount: 15000,
    dueDate: DateTime(2026, 9, 30),
    status: 'partially_paid',
    payments: [
      FeePaymentModel(
        id: 'PAY-1',
        feeAccountId: 'ACC-1',
        studentId: 'S-8017',
        receiptNo: 'REC-2026-00125',
        amount: 10000,
        date: DateTime(2026, 8, 10),
        paymentMethod: 'Online UPI',
        transactionRef: 'UPI/62819401829',
        notes: 'Term 1 Registration & Admission',
        remainingBalance: 25000,
      ),
      FeePaymentModel(
        id: 'PAY-2',
        feeAccountId: 'ACC-1',
        studentId: 'S-8017',
        receiptNo: 'REC-2026-00091',
        amount: 20000,
        date: DateTime(2026, 7, 10),
        paymentMethod: 'Cash',
        transactionRef: 'CSH/89201948',
        notes: 'Term 1 Tuition Instalment',
        remainingBalance: 15000,
      ),
    ],
  );

  // Fees Data - Priya (Total ₹38,000, Paid ₹38,000, Pending ₹0)
  static final FeeSummaryModel feePriya = FeeSummaryModel(
    studentId: 'S-5012',
    grossFee: 38000,
    discountAmount: 0,
    waiverAmount: 0,
    netFee: 38000,
    paidAmount: 38000,
    outstandingAmount: 0,
    dueDate: DateTime(2026, 9, 30),
    status: 'paid',
    payments: [
      FeePaymentModel(
        id: 'PAY-3',
        feeAccountId: 'ACC-2',
        studentId: 'S-5012',
        receiptNo: 'REC-2026-00098',
        amount: 38000,
        date: DateTime(2026, 8, 5),
        paymentMethod: 'Bank Transfer',
        transactionRef: 'NET/99182301',
        notes: 'Annual Tuition & Bus Conveyance',
        remainingBalance: 0,
      ),
    ],
  );

  // Homework Data - Rahul
  static List<HomeworkModel> getHomeworkRahul() {
    return [
      HomeworkModel(
        id: 'HW-801',
        studentId: 'S-8017',
        subject: 'Mathematics',
        title: 'Exercise 4.2 - Linear Equations',
        description: 'Complete Exercise 4.2 from NCERT textbook Chapter 4. Solve all 10 algebraic equations showing step-by-step working in homework notebook.',
        assignedDate: DateTime(2026, 8, 30),
        dueDate: DateTime(2026, 9, 1),
        teacherName: 'Rahul Singh',
        attachmentName: 'Linear_Equations_Practice_Sheet.pdf',
        attachmentType: 'pdf',
        isCompleted: false,
      ),
      HomeworkModel(
        id: 'HW-802',
        studentId: 'S-8017',
        subject: 'Science',
        title: 'Metals & Non-Metals Chemical Reactions',
        description: 'Write balanced chemical equations for reactions of metals with dilute acids and water.',
        assignedDate: DateTime(2026, 8, 29),
        dueDate: DateTime(2026, 9, 3),
        teacherName: 'Dr. Smita Rao',
        attachmentName: 'Lab_Experiment_Diagrams.png',
        attachmentType: 'image',
        isCompleted: false,
      ),
      HomeworkModel(
        id: 'HW-803',
        studentId: 'S-8017',
        subject: 'English',
        title: 'Essay Writing - Climate Change',
        description: 'Write a 300-word essay on global climate change and how students can contribute to environmental conservation.',
        assignedDate: DateTime(2026, 8, 28),
        dueDate: DateTime(2026, 9, 4),
        teacherName: 'Ms. Clara D\'Souza',
        isCompleted: false,
      ),
      HomeworkModel(
        id: 'HW-804',
        studentId: 'S-8017',
        subject: 'Social Science',
        title: 'Map Work - Major River Basins of India',
        description: 'Mark major rivers of North and South India on an outline map of India.',
        assignedDate: DateTime(2026, 8, 20),
        dueDate: DateTime(2026, 8, 25),
        teacherName: 'Mr. Vikas Sharma',
        isCompleted: true,
      ),
    ];
  }

  // Homework Data - Priya
  static List<HomeworkModel> getHomeworkPriya() {
    return [
      HomeworkModel(
        id: 'HW-501',
        studentId: 'S-5012',
        subject: 'Mathematics',
        title: 'Fractions & Decimals Page 42',
        description: 'Solve problems 1 to 5 on converting improper fractions to mixed numbers.',
        assignedDate: DateTime(2026, 8, 30),
        dueDate: DateTime(2026, 9, 2),
        teacherName: 'Mrs. Ananya Verma',
        attachmentName: 'Fraction_Chart.pdf',
        attachmentType: 'pdf',
        isCompleted: false,
      ),
      HomeworkModel(
        id: 'HW-502',
        studentId: 'S-5012',
        subject: 'Environmental Studies',
        title: 'Plant Kingdom Diagram',
        description: 'Draw and color the parts of a plant and label root system and shoot system.',
        assignedDate: DateTime(2026, 8, 25),
        dueDate: DateTime(2026, 8, 28),
        teacherName: 'Mrs. Ananya Verma',
        isCompleted: true,
      ),
    ];
  }

  // Exams - Rahul
  static List<ExamModel> getExamsRahul() {
    return [
      ExamModel(
        id: 'EX-UP-801',
        studentId: 'S-8017',
        subject: 'Mathematics',
        title: 'Term 1 Mid Examination',
        examDate: DateTime(2026, 9, 10),
        timeSlot: '10:00 AM - 12:00 PM',
        totalMarks: 50,
        roomNo: 'Room 204',
        isUpcoming: true,
        status: 'Scheduled',
      ),
      ExamModel(
        id: 'EX-UP-802',
        studentId: 'S-8017',
        subject: 'Science',
        title: 'Term 1 Mid Examination',
        examDate: DateTime(2026, 9, 12),
        timeSlot: '10:00 AM - 12:00 PM',
        totalMarks: 50,
        roomNo: 'Room 204',
        isUpcoming: true,
        status: 'Scheduled',
      ),
      ExamModel(
        id: 'EX-PAST-801',
        studentId: 'S-8017',
        subject: 'Mathematics',
        title: 'Unit Test 1',
        examDate: DateTime(2026, 7, 15),
        timeSlot: '9:00 AM - 10:00 AM',
        totalMarks: 50,
        roomNo: 'Room 204',
        isUpcoming: false,
        status: 'Result Published',
      ),
    ];
  }

  // Exams - Priya
  static List<ExamModel> getExamsPriya() {
    return [
      ExamModel(
        id: 'EX-UP-501',
        studentId: 'S-5012',
        subject: 'Mathematics',
        title: 'Mid Term Assessment',
        examDate: DateTime(2026, 9, 11),
        timeSlot: '9:00 AM - 11:00 AM',
        totalMarks: 50,
        roomNo: 'Room 105',
        isUpcoming: true,
        status: 'Scheduled',
      ),
    ];
  }

  // Exam Results (ONLY Published results returned)
  static List<ExamResultModel> getResultsRahul() {
    return [
      ExamResultModel(
        id: 'EX-801',
        studentId: 'S-8017',
        examName: 'Mid Term Examination 2026',
        examDate: DateTime(2026, 7, 25),
        overallGrade: 'A',
        teacherRemarks: 'Good performance. Continue improving in English and essay structures.',
        subjects: [
          const SubjectResultModel(subject: 'Mathematics', maxMarks: 100, obtainedMarks: 86, grade: 'A', teacherComment: 'Excellent logical reasoning'),
          const SubjectResultModel(subject: 'Science', maxMarks: 100, obtainedMarks: 91, grade: 'A+', teacherComment: 'Outstanding conceptual clarity'),
          const SubjectResultModel(subject: 'English', maxMarks: 100, obtainedMarks: 78, grade: 'B+', teacherComment: 'Good grammar'),
          const SubjectResultModel(subject: 'Social Science', maxMarks: 100, obtainedMarks: 82, grade: 'A', teacherComment: 'Thorough map skills'),
          const SubjectResultModel(subject: 'Computer Science', maxMarks: 50, obtainedMarks: 48, grade: 'A+', teacherComment: 'Top rank in coding'),
        ],
      ),
    ];
  }

  static List<ExamResultModel> getResultsPriya() {
    return [
      ExamResultModel(
        id: 'EX-501',
        studentId: 'S-5012',
        examName: 'Mid Term Examination 2026',
        examDate: DateTime(2026, 7, 22),
        overallGrade: 'A+',
        teacherRemarks: 'Priya is an exceptionally diligent student. Her handwriting and creative arts performance are top-notch.',
        subjects: [
          const SubjectResultModel(subject: 'Mathematics', maxMarks: 100, obtainedMarks: 94, grade: 'A+'),
          const SubjectResultModel(subject: 'English', maxMarks: 100, obtainedMarks: 89, grade: 'A'),
          const SubjectResultModel(subject: 'Environmental Studies', maxMarks: 100, obtainedMarks: 96, grade: 'A+'),
        ],
      ),
    ];
  }

  // Parent–Teacher Message Channels & Threads
  static List<MessageThread> getMessagesRahul() {
    return [
      MessageThread(
        id: 'TH-801',
        studentId: 'S-8017',
        teacherName: 'Mr. Rahul Singh',
        teacherSubject: 'Class Teacher & Mathematics',
        teacherAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?fit=crop&w=200&h=200',
        lastMessage: 'Rahul showed good improvement in the algebra quiz today.',
        lastMessageTime: DateTime(2026, 8, 30, 15, 20),
        unreadCount: 1,
        messages: [
          MessageItem(
            id: 'M-1',
            senderName: 'Mr. Rahul Singh',
            isFromTeacher: true,
            text: 'Hello Mr. Sharma, please ensure Rahul revises Chapter 4 for next week\'s assessment.',
            timestamp: DateTime(2026, 8, 29, 11, 30),
          ),
          MessageItem(
            id: 'M-2',
            senderName: 'Dharampal Sharma',
            isFromTeacher: false,
            text: 'Thank you Sir, we are supervising his evening homework practice.',
            timestamp: DateTime(2026, 8, 29, 18, 45),
          ),
          MessageItem(
            id: 'M-3',
            senderName: 'Mr. Rahul Singh',
            isFromTeacher: true,
            text: 'Rahul showed good improvement in the algebra quiz today.',
            timestamp: DateTime(2026, 8, 30, 15, 20),
          ),
        ],
      ),
      MessageThread(
        id: 'TH-802',
        studentId: 'S-8017',
        teacherName: 'Dr. Smita Rao',
        teacherSubject: 'Science Faculty',
        teacherAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?fit=crop&w=200&h=200',
        lastMessage: 'Please find attached the lab safety guideline for Friday\'s practical.',
        lastMessageTime: DateTime(2026, 8, 28, 14, 10),
        unreadCount: 0,
        messages: [
          MessageItem(
            id: 'M-4',
            senderName: 'Dr. Smita Rao',
            isFromTeacher: true,
            text: 'Please find attached the lab safety guideline for Friday\'s practical.',
            timestamp: DateTime(2026, 8, 28, 14, 10),
            attachmentName: 'Lab_Safety_Guidelines.pdf',
            attachmentType: 'pdf',
          ),
        ],
      ),
    ];
  }

  static List<MessageThread> getMessagesPriya() {
    return [
      MessageThread(
        id: 'TH-501',
        studentId: 'S-5012',
        teacherName: 'Mrs. Ananya Verma',
        teacherSubject: 'Class Teacher & EVS',
        teacherAvatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?fit=crop&w=200&h=200',
        lastMessage: 'Priya won 1st prize in the school story narration competition! 🎉',
        lastMessageTime: DateTime(2026, 8, 30, 13, 0),
        unreadCount: 1,
        messages: [
          MessageItem(
            id: 'M-5',
            senderName: 'Mrs. Ananya Verma',
            isFromTeacher: true,
            text: 'Priya won 1st prize in the school story narration competition! 🎉',
            timestamp: DateTime(2026, 8, 30, 13, 0),
          ),
        ],
      ),
    ];
  }

  // Transport Data
  static TransportModel getTransportRahul() {
    return const TransportModel(
      studentId: 'S-8017',
      busNumber: 'Bus #14 (DL-1PC-4829)',
      routeName: 'Route 12 - South Delhi & Green Park',
      driverName: 'Mr. Ram Singh',
      driverPhone: '+91 98112 34567',
      helperName: 'Mr. Dinesh Kumar',
      currentStatus: 'On Route to School (On Time)',
      estimatedArrival: '7:45 AM',
      currentSpeedKmph: 34.0,
      routeStops: [
        BusStop(stopName: 'Depot Start', morningPickupTime: '06:45 AM', afternoonDropTime: '03:30 PM', isCompleted: true),
        BusStop(stopName: 'Hauz Khas Metro', morningPickupTime: '07:05 AM', afternoonDropTime: '03:15 PM', isCompleted: true),
        BusStop(stopName: 'Green Park Main Gate', morningPickupTime: '07:20 AM', afternoonDropTime: '03:00 PM', isCompleted: true, isStudentStop: true),
        BusStop(stopName: 'AIIMS Circle', morningPickupTime: '07:35 AM', afternoonDropTime: '02:45 PM', isCompleted: false),
        BusStop(stopName: 'School Main Campus', morningPickupTime: '07:50 AM', afternoonDropTime: '02:30 PM', isCompleted: false),
      ],
    );
  }

  static TransportModel getTransportPriya() {
    return const TransportModel(
      studentId: 'S-5012',
      busNumber: 'Bus #08 (DL-1PC-2210)',
      routeName: 'Route 8 - Vasant Kunj Sector C',
      driverName: 'Mr. Baldev Raj',
      driverPhone: '+91 98119 87654',
      helperName: 'Mr. Mukesh',
      currentStatus: 'Arrived at School Campus',
      estimatedArrival: '7:40 AM',
      currentSpeedKmph: 0.0,
      routeStops: [
        BusStop(stopName: 'Sector C Pocket 9', morningPickupTime: '07:15 AM', afternoonDropTime: '02:50 PM', isCompleted: true, isStudentStop: true),
        BusStop(stopName: 'School Primary Gate', morningPickupTime: '07:40 AM', afternoonDropTime: '02:25 PM', isCompleted: true),
      ],
    );
  }

  // Academic Calendar Events (2026)
  static final List<CalendarEventModel> calendarEvents = [
    CalendarEventModel(
      id: 'EV-1',
      title: 'Independence Day National Celebration',
      date: DateTime(2026, 8, 15),
      timeRange: '8:00 AM - 10:00 AM',
      category: EventCategory.holiday,
      location: 'School Main Ground',
      description: 'National flag hoisting ceremony & student parade. School closed for normal classes.',
      isHighlight: true,
    ),
    CalendarEventModel(
      id: 'EV-2',
      title: 'Term 1 Parent-Teacher Meeting (PTM)',
      date: DateTime(2026, 9, 20),
      timeRange: '10:00 AM - 2:00 PM',
      category: EventCategory.ptm,
      location: 'Respective Classrooms',
      description: 'Review of Mid Term academic evaluation and student developmental progress.',
      isHighlight: true,
    ),
    CalendarEventModel(
      id: 'EV-3',
      title: 'Mid Term Mathematics & Science Exams',
      date: DateTime(2026, 9, 10),
      timeRange: '9:00 AM - 12:00 PM',
      category: EventCategory.exam,
      location: 'Examination Halls A & B',
      description: 'First semester formal summative assessment.',
    ),
    CalendarEventModel(
      id: 'EV-4',
      title: 'Annual Inter-House Sports Trials',
      date: DateTime(2026, 8, 25),
      timeRange: '8:30 AM - 1:30 PM',
      category: EventCategory.sports,
      location: 'Sports Complex & Swimming Pool',
      description: 'Selection trials for athletics, football, badminton, and swimming squads.',
    ),
    CalendarEventModel(
      id: 'EV-5',
      title: 'Gandhi Jayanti Public Holiday',
      date: DateTime(2026, 10, 2),
      timeRange: 'All Day',
      category: EventCategory.holiday,
      location: 'Nationwide',
      description: 'Gazetted public holiday in observance of Mahatma Gandhi\'s birth anniversary.',
    ),
  ];

  // PTM Schedules
  static final Map<String, PtmModel> ptmSchedules = {
    'S-8017': PtmModel(
      id: 'PTM-801',
      studentId: 'S-8017',
      meetingDate: DateTime(2026, 9, 20),
      timeWindow: '10:00 AM – 2:00 PM',
      className: 'Class 8-A',
      classTeacher: 'Mr. Rahul Singh',
      venue: 'Room 204, Second Floor, Academic Block',
      instructions: 'Please bring your child\'s Mid Term answer scripts and diary. Adhere strictly to allotted time slots.',
    ),
    'S-5012': PtmModel(
      id: 'PTM-501',
      studentId: 'S-5012',
      meetingDate: DateTime(2026, 9, 20),
      timeWindow: '10:00 AM – 2:00 PM',
      className: 'Class 5-B',
      classTeacher: 'Mrs. Ananya Verma',
      venue: 'Room 105, First Floor, Primary Block',
      instructions: 'Discuss student progress in holistic development and co-curricular arts.',
    ),
  };

  // Official Documents Vault
  static List<DocumentModel> getDocuments(String studentId) {
    return [
      DocumentModel(
        id: 'DOC-1',
        studentId: studentId,
        title: 'Mid Term Academic Report Card 2026',
        type: DocumentType.reportCard,
        issueDate: DateTime(2026, 8, 1),
        fileSize: '1.4 MB',
        fileFormat: 'pdf',
      ),
      DocumentModel(
        id: 'DOC-2',
        studentId: studentId,
        title: 'Fee Payment Receipt #REC-2026-00125',
        type: DocumentType.feeReceipt,
        issueDate: DateTime(2026, 8, 10),
        fileSize: '450 KB',
        fileFormat: 'pdf',
      ),
      DocumentModel(
        id: 'DOC-3',
        studentId: studentId,
        title: 'Official Bonafide Student Certificate',
        type: DocumentType.bonafideCertificate,
        issueDate: DateTime(2026, 4, 15),
        fileSize: '820 KB',
        fileFormat: 'pdf',
      ),
      DocumentModel(
        id: 'DOC-4',
        studentId: studentId,
        title: 'Term 1 Examination Admit Card',
        type: DocumentType.admitCard,
        issueDate: DateTime(2026, 7, 1),
        fileSize: '600 KB',
        fileFormat: 'pdf',
      ),
    ];
  }

  // Timetables
  static Map<String, List<TimetableEntryModel>> getTimetableRahul() {
    return {
      'MONDAY': const [
        TimetableEntryModel(dayOfWeek: 'MONDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'Mathematics', room: 'Room 204', teacherName: 'Rahul Singh'),
        TimetableEntryModel(dayOfWeek: 'MONDAY', startTime: '9:00 AM', endTime: '10:00 AM', subject: 'English', room: 'Room 204', teacherName: 'Ms. Clara D\'Souza'),
        TimetableEntryModel(dayOfWeek: 'MONDAY', startTime: '10:00 AM', endTime: '10:30 AM', subject: 'Morning Break', room: 'Cafeteria', teacherName: '', isBreak: true),
        TimetableEntryModel(dayOfWeek: 'MONDAY', startTime: '10:30 AM', endTime: '11:30 AM', subject: 'Science Lab', room: 'Physics Lab 2', teacherName: 'Dr. Smita Rao'),
        TimetableEntryModel(dayOfWeek: 'MONDAY', startTime: '11:30 AM', endTime: '12:30 PM', subject: 'Social Science', room: 'Room 204', teacherName: 'Mr. Vikas Sharma'),
      ],
      'TUESDAY': const [
        TimetableEntryModel(dayOfWeek: 'TUESDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'Science', room: 'Room 204', teacherName: 'Dr. Smita Rao'),
        TimetableEntryModel(dayOfWeek: 'TUESDAY', startTime: '9:00 AM', endTime: '10:00 AM', subject: 'Mathematics', room: 'Room 204', teacherName: 'Rahul Singh'),
      ],
      'WEDNESDAY': const [
        TimetableEntryModel(dayOfWeek: 'WEDNESDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'Social Science', room: 'Room 204', teacherName: 'Mr. Vikas Sharma'),
      ],
      'THURSDAY': const [
        TimetableEntryModel(dayOfWeek: 'THURSDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'English Grammar', room: 'Room 204', teacherName: 'Ms. Clara D\'Souza'),
      ],
      'FRIDAY': const [
        TimetableEntryModel(dayOfWeek: 'FRIDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'Biology Lab', room: 'Bio Lab', teacherName: 'Dr. Smita Rao'),
      ],
      'SATURDAY': const [
        TimetableEntryModel(dayOfWeek: 'SATURDAY', startTime: '8:00 AM', endTime: '9:30 AM', subject: 'Extracurricular Club', room: 'Auditorium', teacherName: 'Mentors'),
      ],
    };
  }

  static Map<String, List<TimetableEntryModel>> getTimetablePriya() {
    return {
      'MONDAY': const [
        TimetableEntryModel(dayOfWeek: 'MONDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'English Literature', room: 'Room 105', teacherName: 'Mrs. Ananya Verma'),
        TimetableEntryModel(dayOfWeek: 'MONDAY', startTime: '9:00 AM', endTime: '10:00 AM', subject: 'Mathematics Fun', room: 'Room 105', teacherName: 'Mr. K.L. Saini'),
      ],
      'TUESDAY': const [
        TimetableEntryModel(dayOfWeek: 'TUESDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'Art & Craft', room: 'Art Studio', teacherName: 'Ms. Sonal Kapoor'),
      ],
      'WEDNESDAY': const [
        TimetableEntryModel(dayOfWeek: 'WEDNESDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'Mathematics', room: 'Room 105', teacherName: 'Mr. K.L. Saini'),
      ],
      'THURSDAY': const [
        TimetableEntryModel(dayOfWeek: 'THURSDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'Music & Dance', room: 'Music Hall', teacherName: 'Mr. A.R. Das'),
      ],
      'FRIDAY': const [
        TimetableEntryModel(dayOfWeek: 'FRIDAY', startTime: '8:00 AM', endTime: '9:00 AM', subject: 'EVS Lab', room: 'Room 105', teacherName: 'Mrs. Ananya Verma'),
      ],
      'SATURDAY': const [
        TimetableEntryModel(dayOfWeek: 'SATURDAY', startTime: '8:00 AM', endTime: '10:00 AM', subject: 'Storytelling & Games', room: 'Activity Room', teacherName: 'Mrs. Ananya Verma'),
      ],
    };
  }

  // School Notices
  static final List<NoticeModel> notices = [
    NoticeModel(
      id: 'N-101',
      title: 'School Holiday - Independence Day Celebration',
      category: 'Holiday',
      date: DateTime(2026, 8, 15),
      shortDescription: 'School will remain closed on 15th August 2026 on account of 80th Independence Day.',
      fullDescription: 'Dear Parents & Guardians,\n\nPlease note that St. Xavier International School will remain closed on Saturday, 15th August 2026 in observance of Independence Day.',
      attachmentName: 'Independence_Day_Schedule.pdf',
      attachmentType: 'pdf',
      isImportant: true,
    ),
    NoticeModel(
      id: 'N-102',
      title: 'Parent-Teacher Meeting (PTM) for Term 1',
      category: 'Academic',
      date: DateTime(2026, 8, 20),
      shortDescription: 'PTM scheduled for discussing Mid Term academic evaluations and holistic student progress.',
      fullDescription: 'Dear Parents,\n\nThe 1st Term Parent-Teacher Meeting (PTM) will take place on Thursday, 20th September 2026 from 10:00 AM to 2:00 PM.',
      isImportant: true,
    ),
    NoticeModel(
      id: 'N-103',
      title: 'Annual Sports Day 2026 Selection Trials',
      category: 'Events',
      date: DateTime(2026, 8, 25),
      shortDescription: 'Registration opens for athletics, football, basketball and swimming trials.',
      fullDescription: 'Students from Class 5 to 12 can participate in the Annual Sports Meet selection trials.',
      attachmentName: 'Sports_Trial_Categories.pdf',
      attachmentType: 'pdf',
    ),
  ];

  // App Notifications
  static final List<AppNotificationModel> notifications = [];
}
