import '../models/attendance.dart';
import '../models/leave_request.dart';
import '../models/teacher.dart';
import '../models/timetable.dart';

class SampleData {
  static const teachers = [
    Teacher(
      id: 't1',
      employeeNumber: 'EMP-014',
      fullName: 'N. Perera',
      subjects: ['Mathematics', 'ICT'],
      isActive: true,
      phone: '0771234567',
      email: 'n.perera@school.lk',
    ),
    Teacher(
      id: 't2',
      employeeNumber: 'EMP-021',
      fullName: 'S. Fernando',
      subjects: ['Sinhala', 'Buddhism'],
      isActive: true,
      email: 's.fernando@school.lk',
    ),
    Teacher(
      id: 't3',
      employeeNumber: 'EMP-033',
      fullName: 'R. Jayawardena',
      subjects: ['Science', 'Chemistry'],
      isActive: true,
    ),
    Teacher(
      id: 't4',
      employeeNumber: 'EMP-041',
      fullName: 'K. Silva',
      subjects: ['English', 'History'],
      isActive: true,
    ),
    Teacher(
      id: 't5',
      employeeNumber: 'EMP-052',
      fullName: 'M. Dissanayake',
      subjects: ['Commerce', 'Accounts'],
      isActive: false,
    ),
  ];

  static const periods = [
    SchoolPeriod(
      id: 'p1',
      number: 1,
      label: 'Period 1',
      startTime: '07:40',
      endTime: '08:20',
    ),
    SchoolPeriod(
      id: 'p2',
      number: 2,
      label: 'Period 2',
      startTime: '08:20',
      endTime: '09:00',
    ),
    SchoolPeriod(
      id: 'p3',
      number: 3,
      label: 'Period 3',
      startTime: '09:00',
      endTime: '09:40',
    ),
    SchoolPeriod(
      id: 'p4',
      number: 4,
      label: 'Period 4',
      startTime: '10:00',
      endTime: '10:40',
    ),
    SchoolPeriod(
      id: 'p5',
      number: 5,
      label: 'Period 5',
      startTime: '10:40',
      endTime: '11:20',
    ),
    SchoolPeriod(
      id: 'p6',
      number: 6,
      label: 'Period 6',
      startTime: '11:20',
      endTime: '12:00',
    ),
    SchoolPeriod(
      id: 'p7',
      number: 7,
      label: 'Period 7',
      startTime: '12:40',
      endTime: '13:20',
    ),
    SchoolPeriod(
      id: 'p8',
      number: 8,
      label: 'Period 8',
      startTime: '13:20',
      endTime: '14:00',
    ),
  ];

  static List<AttendanceRecord> attendanceToday() {
    final today = DateTime.now();
    return [
      AttendanceRecord(
        id: 'a1',
        teacherId: 't1',
        teacherName: 'N. Perera',
        date: today,
        status: AttendanceStatus.present,
        markedAt: DateTime(today.year, today.month, today.day, 7, 12),
      ),
      AttendanceRecord(
        id: 'a2',
        teacherId: 't2',
        teacherName: 'S. Fernando',
        date: today,
        status: AttendanceStatus.leave,
        note: 'Approved casual leave',
      ),
      AttendanceRecord(
        id: 'a3',
        teacherId: 't3',
        teacherName: 'R. Jayawardena',
        date: today,
        status: AttendanceStatus.pending,
      ),
      AttendanceRecord(
        id: 'a4',
        teacherId: 't4',
        teacherName: 'K. Silva',
        date: today,
        status: AttendanceStatus.present,
        markedAt: DateTime(today.year, today.month, today.day, 7, 21),
      ),
    ];
  }

  static List<LeaveRequest> leaves() {
    final now = DateTime.now();
    return [
      LeaveRequest(
        id: 'l1',
        teacherId: 't2',
        teacherName: 'S. Fernando',
        fromDate: now,
        toDate: now,
        reason: 'Medical appointment',
        status: LeaveStatus.approved,
      ),
      LeaveRequest(
        id: 'l2',
        teacherId: 't3',
        teacherName: 'R. Jayawardena',
        fromDate: now.add(const Duration(days: 2)),
        toDate: now.add(const Duration(days: 3)),
        reason: 'Family function',
        status: LeaveStatus.pending,
      ),
      LeaveRequest(
        id: 'l3',
        teacherId: 't1',
        teacherName: 'N. Perera',
        fromDate: now.subtract(const Duration(days: 8)),
        toDate: now.subtract(const Duration(days: 8)),
        reason: 'Personal',
        status: LeaveStatus.rejected,
        rejectionReason: 'Timetable clash during exam week',
      ),
    ];
  }

  static List<TimetableSlot> teacherTimetable() {
    return [
      TimetableSlot(
        id: 'tt1',
        weekday: 'Monday',
        period: periods[0],
        className: '10-A',
        subject: 'Mathematics',
        teacherName: 'N. Perera',
      ),
      TimetableSlot(
        id: 'tt2',
        weekday: 'Monday',
        period: periods[2],
        className: '11-B',
        subject: 'ICT',
        teacherName: 'N. Perera',
      ),
      TimetableSlot(
        id: 'tt3',
        weekday: 'Monday',
        period: periods[4],
        className: '9-C',
        subject: 'Mathematics',
        teacherName: 'N. Perera',
        isCover: true,
      ),
      TimetableSlot(
        id: 'tt4',
        weekday: 'Tuesday',
        period: periods[1],
        className: '10-A',
        subject: 'Mathematics',
        teacherName: 'N. Perera',
      ),
    ];
  }

  static const replacements = [
    ReplacementAssignment(
      id: 'r1',
      absentTeacher: 'S. Fernando',
      coverTeacher: 'N. Perera',
      className: '9-C',
      subject: 'Sinhala',
      periodLabel: 'Period 5',
      weekday: 'Monday',
      status: 'Assigned',
      score: 92,
    ),
    ReplacementAssignment(
      id: 'r2',
      absentTeacher: 'R. Jayawardena',
      coverTeacher: 'K. Silva',
      className: '11-A',
      subject: 'Science',
      periodLabel: 'Period 2',
      weekday: 'Wednesday',
      status: 'Suggested',
      score: 81,
    ),
  ];

  static List<AppNotification> notifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Cover period assigned',
        body: 'You cover 9-C Sinhala in Period 5 today.',
        createdAt: now.subtract(const Duration(minutes: 40)),
        icon: 'swap',
      ),
      AppNotification(
        id: 'n2',
        title: 'Leave approved',
        body: 'Casual leave for S. Fernando was approved.',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
        icon: 'leave',
      ),
      AppNotification(
        id: 'n3',
        title: 'Attendance cutoff',
        body: 'Mark present before 07:30 AM Sri Lanka time.',
        createdAt: now.subtract(const Duration(hours: 14)),
        isRead: true,
        icon: 'bell',
      ),
    ];
  }
}
