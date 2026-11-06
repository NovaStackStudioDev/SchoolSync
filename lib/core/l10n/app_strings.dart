import '../constants/app_constants.dart';

class AppStrings {
  const AppStrings(this.sinhala);

  final bool sinhala;

  String get schoolName =>
      sinhala ? AppConstants.schoolNameSi : AppConstants.schoolName;

  String get tagline => sinhala ? AppConstants.taglineSi : AppConstants.tagline;

  String get otherLanguage => sinhala ? 'English' : 'සිංහල';

  String pick(String si, String en) => sinhala ? si : en;

  String get signIn => pick('ඇතුළු වන්න', 'Sign in');
  String get signOut => pick('ඉවත් වන්න', 'Sign out');
  String get retry => pick('නැවත උත්සාහ කරන්න', 'Retry');
  String get email => pick('විද්‍යුත් තැපෑල', 'Email');
  String get password => pick('මුරපදය', 'Password');
  String get confirmPassword => pick('මුරපදය තහවුරු කරන්න', 'Confirm password');
  String get fullName => pick('සම්පූර්ණ නම', 'Full name');
  String get phone => pick('දුරකථන අංකය', 'Phone number');
  String get employeeNumber => pick('සේවක අංකය', 'Employee number');
  String get optional => pick('අනිවාර්ය නොවේ', 'Optional');
  String get register => pick('ලියාපදිංචි වන්න', 'Register');
  String get createAccount => pick('ගුරු ගිණුම සාදන්න', 'Create teacher account');
  String get newTeacher => pick('නව ගුරුවරයෙක්ද?', 'New teacher?');
  String get haveAccount => pick('දැනටමත් ගිණුමක් තිබේද?', 'Already have an account?');
  String get subjectYouTeach =>
      pick('ඔබ උගන්වන විෂය තෝරන්න', 'Choose the subject you teach');
  String get accessNote =>
      pick('විදුහල්පති සහ ගුරු ප්‍රවේශය පමණි', 'Principal and teacher access only');
  String get validEmail => pick('වලංගු ඊමේල් එකක් ඇතුළත් කරන්න', 'Enter a valid email');
  String get passwordRequired => pick('මුරපදය අවශ්‍යයි', 'Password is required');
  String get passwordShort =>
      pick('මුරපදය අකුරු 6 කට නොඅඩු විය යුතුය', 'Password must be at least 6 characters');
  String get passwordMismatch => pick('මුරපද නොගැලපේ', 'Passwords do not match');
  String get nameRequired => pick('නම අවශ්‍යයි', 'Name is required');
  String get pickSubject => pick('අඩුම තරමින් විෂයක් තෝරන්න', 'Choose at least one subject');
  String get signInFailed => pick(
        'ඇතුළු වීම අසාර්ථකයි. ඊමේල් සහ මුරපදය පරීක්ෂා කරන්න.',
        'Sign in failed. Check email and password.',
      );
  String get emailNotConfirmed => pick(
        'ඊමේල් එක තහවුරු කළ පසු එම ඊමේල් සහ මුරපදයෙන් ඇතුළු වන්න.',
        'Confirm your email, then sign in with that email and password.',
      );
  String get alreadyRegistered => pick(
        'මෙම ඊමේල් එක දැනටමත් ලියාපදිංචි වී ඇත. ඇතුළු වන්න.',
        'This email is already registered. Sign in instead.',
      );
  String get checkEmailThenLogin => pick(
        'ලියාපදිංචිය සාර්ථකයි. ඊමේල් එකේ තහවුරු කිරීමේ සබැඳිය විවෘත කර, ඊළඟට ඔබ දුන් ඊමේල් සහ මුරපදයෙන් ඇතුළු වන්න.',
        'Registration succeeded. Open the confirmation link in your email, then sign in with the email and password you entered.',
      );
  String get registerFailed => pick(
        'ලියාපදිංචිය සුරැකිය නොහැකි විය.',
        'Could not save the registration.',
      );
  String get profileMissing =>
      pick('ගිණුම සක්‍රිය හෝ සකසා නැත.', 'Account is not active or configured.');
  String get profileInactive =>
      pick('මෙම ගිණුම අක්‍රියයි.', 'This staff account is inactive.');
  String get profileLoadFailed =>
      pick('පැතිකඩ පූරණය කළ නොහැක.', 'Unable to load your profile.');

  String get home => pick('මුල් පිටුව', 'Home');
  String get checkIn => pick('පැමිණීම', 'Check-in');
  String get leave => pick('නිවාඩු', 'Leave');
  String get timetable => pick('කාලසටහන', 'Timetable');
  String get teacher => pick('ගුරුවරයා', 'Teacher');
  String get principal => pick('විදුහල්පති', 'Principal');
  String get goodMorning => pick('සුභ උදෑසනක්', 'Good morning');
  String get markBefore =>
      pick('07:30 ට පෙර පැමිණීම සටහන් කරන්න', 'Mark present before 07:30 AM');
  String get todayStatus => pick('අද තත්ත්වය', 'Today status');
  String get open => pick('විවෘතයි', 'Open');
  String get coverPeriods => pick('ආදේශ පාඩම්', 'Cover periods');
  String get markAttendance => pick('පැමිණීම සටහන් කරන්න', 'Mark attendance');
  String get beforeCutoff =>
      pick('සේවාදායක වේලාව 07:30 ට පෙර', 'Before 07:30 server time');
  String get myTimetable => pick('මගේ කාලසටහන', 'My timetable');
  String get classesAndFree =>
      pick('පන්ති සහ නිදහස් පාඩම්', 'Classes and free periods');
  String get requestLeave => pick('නිවාඩු ඉල්ලන්න', 'Request leave');
  String get sendForReview =>
      pick('විදුහල්පති අනුමැතියට යවන්න', 'Send for principal review');
  String get assignedCover =>
      pick('පවරා ඇති ආදේශන', 'Assigned replacements');
  String get notifications => pick('දැනුම්දීම්', 'Notifications');
  String get leaveAlerts =>
      pick('නිවාඩු සහ ආදේශ දැනුම්දීම්', 'Leave and cover alerts');
  String get mySubjects => pick('මගේ විෂයයන්', 'My subjects');
  String get attendance => pick('පැමිණීම', 'Attendance');
  String get cover => pick('ආදේශන', 'Cover');
  String get schoolOps => pick('පාසල් කටයුතු', 'School operations');
  String get teachers => pick('ගුරුවරු', 'Teachers');
  String get presentToday => pick('අද පැමිණි', 'Present today');
  String get coverNeeded => pick('ආදේශන අවශ්‍යයි', 'Cover needed');
  String get directoryHint =>
      pick('ලේඛනය, විෂයයන් සහ තත්ත්වය', 'Directory, subjects and status');
  String get dailyRoll =>
      pick('දෛනික පැමිණීම සහ ව්‍යතිරේක', 'Daily roll and exceptions');
  String get approveLeave =>
      pick('ඉල්ලීම් අනුමත හෝ ප්‍රතික්ෂේප කරන්න', 'Approve or reject requests');
  String get replacements => pick('ආදේශන', 'Replacements');
  String get rankHint =>
      pick('ස්වයංක්‍රීය යෝජනා සහ අතින් පැවරීම', 'Auto rank and manual assign');
  String get calendar => pick('දින දර්ශනය', 'Calendar');
  String get calendarHint =>
      pick('වැඩ කරන දින සහ නිවාඩු', 'Working days and holidays');
  String get timetableHint =>
      pick('පන්ති, පාඩම් සහ විෂයයන්', 'Classes, periods and subjects');
  String get schoolTimetable => pick('පාසල් කාලසටහන', 'School timetable');
  String get reports => pick('වාර්තා', 'Reports');
  String get reportsHint =>
      pick('පැමිණීම සහ ආදේශ බර', 'Attendance and cover load');
  String get alerts => pick('ඇඟවීම්', 'Alerts');
  String get alertsHint =>
      pick('නිවාඩු, ආදේශන සහ කාල සීමාව', 'Leave, cover and cutoff');
  String get teacherDirectory => pick('ගුරු ලේඛනය', 'Teacher directory');
  String get noTeachers =>
      pick('තවම ගුරුවරු ලියාපදිංචි වී නැත.', 'No teachers have registered yet.');
  String get teachersSelfRegister => pick(
        'ගුරුවරුන් ඇතුළු වීමේ පිටුවෙන් ලියාපදිංචි වේ.',
        'Teachers register from the sign-in page.',
      );
  String get active => pick('සක්‍රිය', 'Active');
  String get inactive => pick('අක්‍රිය', 'Inactive');
  String get present => pick('පැමිණි', 'Present');
  String get absent => pick('නොපැමිණි', 'Absent');
  String get late => pick('ප්‍රමාද', 'Late');
  String get onLeave => pick('නිවාඩු', 'On leave');
  String get pending => pick('පොරොත්තු', 'Pending');
  String get approved => pick('අනුමත', 'Approved');
  String get rejected => pick('ප්‍රතික්ෂේප', 'Rejected');
  String get dailyAttendance => pick('දෛනික පැමිණීම', 'Daily attendance');
  String get notMarked => pick('තවම සටහන් කර නැත', 'Not marked yet');
  String get markedAt => pick('සටහන් කළ වේලාව', 'Marked at');
  String get checkInOpen => pick('පැමිණීම විවෘතයි', 'Check-in is open');
  String get cutoffPassed => pick('කාල සීමාව ඉකුත් වී ඇත', 'Cutoff has passed');
  String get cutoffHelp => pick(
        'පාසල් දිනයකදී ශ්‍රී ලංකා වේලාවෙන් 07:30 ට පෙර පමණක් පැමිණීම සටහන් කළ හැක. දුරකථන ඔරලෝසුව නොව සේවාදායක වේලාව භාවිතා වේ.',
        'Present can be marked only before 07:30 on a school day. Server time in Asia/Colombo is used, not the phone clock.',
      );
  String get markMePresent => pick('මම පැමිණ ඇත', 'Mark me present');
  String get holidayNote => pick(
        'සති අන්ත සහ නිවාඩු දිනවල සටහන් කිරීම වසා ඇත. වැඩ කරන සෙනසුරාදාවක් විදුහල්පතිට විවෘත කළ හැක.',
        'Weekends and holidays stay locked unless the principal enables a working Saturday.',
      );
  String get leaveApprovals => pick('නිවාඩු අනුමැතිය', 'Leave approvals');
  String get reject => pick('ප්‍රතික්ෂේප', 'Reject');
  String get approve => pick('අනුමත කරන්න', 'Approve');
  String get leaveHelp => pick(
        'විදුහල්පති විමසන ඉල්ලීමක් යවන්න. අනුමත නිවාඩු, කාල සීමාවෙන් පසු පැමිණීම සමඟ සසඳයි.',
        'Send a request for the principal to review. Approved leave is used when attendance is reconciled after cutoff.',
      );
  String get chooseDates => pick('දින තෝරන්න', 'Choose dates');
  String get reason => pick('හේතුව', 'Reason');
  String get submitRequest => pick('ඉල්ලීම යවන්න', 'Submit request');
  String get leaveHistory => pick('මගේ නිවාඩු ඉතිහාසය', 'My leave history');
  String get periodReplacements => pick('පාඩම් ආදේශන', 'Period replacements');
  String get replacementHelp => pick(
        'නිදහස් පාඩම, පැමිණීම, විෂය ගැළපීම සහ වැඩ බර අනුව යෝජනා පෙළගස්වයි. යෝජනාවක් භාරගෙන හෝ සුදුසු ගුරුවරයෙකු පැවරිය හැක.',
        'Candidates are ranked by free period, presence, subject fit and workload. Accept a suggestion or assign a qualified teacher.',
      );
  String get absentTeacher => pick('නොපැමිණි', 'Absent');
  String get coverTeacher => pick('ආදේශ', 'Cover');
  String get matchScore => pick('ගැළපුම් ලකුණු', 'Match score');
  String get assignOther => pick('වෙනත් අයෙකු', 'Assign other');
  String get accept => pick('භාරගන්න', 'Accept');
  String get myCover => pick('මගේ ආදේශ පාඩම්', 'My cover periods');
  String get assigned => pick('පවරා ඇත', 'Assigned');
  String get suggested => pick('යෝජිත', 'Suggested');
  String get freePeriod => pick('නිදහස් පාඩම', 'Free period');
  String get coverAssignment => pick('ආදේශ පැවරීම', 'Cover assignment');
  String get schoolCalendar => pick('පාසල් දින දර්ශනය', 'School calendar');
  String get workingDay =>
      pick('වැඩ කරන දිනය · 07:30 දක්වා පැමිණීම', 'Working day · attendance until 07:30');
  String get poya => pick('පෝය නිවාඩුව', 'Poya holiday');
  String get weekend => pick('සති අන්තය', 'Weekend');
  String get attendanceRate => pick('පැමිණීමේ අනුපාතය', 'Attendance rate');
  String get absences30 => pick('නොපැමිණීම් (දින 30)', 'Absences (30d)');
  String get leavePending => pick('පොරොත්තු නිවාඩු', 'Leave pending');
  String get attendanceSummary => pick('පැමිණීමේ සාරාංශය', 'Attendance summary');
  String get attendanceSummaryHint => pick(
        'ගුරුවරයා අනුව පැමිණීම, නිවාඩු සහ නොපැමිණීම',
        'Present, leave and absence by teacher',
      );
  String get coverLoad => pick('ආදේශ වැඩ බර', 'Replacement workload');
  String get coverLoadHint =>
      pick('මෙම වාරයේ පවරා ඇති ආදේශ පාඩම්', 'Cover periods assigned this term');
  String get days => pick('දින', 'day(s)');
  String get loadingTeachers => pick('ගුරුවරු පූරණය වෙමින්...', 'Loading teachers...');
  String get couldNotLoadTeachers =>
      pick('ගුරු ලේඛනය පූරණය කළ නොහැක.', 'Could not load the teacher directory.');
  String get attendanceSuccess =>
      pick('පැමිණීම සාර්ථකව සටහන් විය.', 'Attendance marked successfully.');
  String get alreadyMarked =>
      pick('අද දින පැමිණීම දැනටමත් සටහන් කර ඇත.', 'Attendance already marked for today.');
  String get leaveSubmitted =>
      pick('නිවාඩු ඉල්ලීම සාර්ථකව යවන ලදී.', 'Leave request submitted successfully.');
  String get actionFailed =>
      pick('ක්‍රියාව අසාර්ථක විය. නැවත උත්සාහ කරන්න.', 'Action failed. Please try again.');
  String get save => pick('සුරකින්න', 'Save');
  String get cancel => pick('අවලංගු කරන්න', 'Cancel');
  String get rejectionReasonPrompt =>
      pick('ප්‍රතික්ෂේප කිරීමට හේතුව ඇතුළත් කරන්න', 'Enter rejection reason');
  String get selectTeacher => pick('ගුරුවරයෙකු තෝරන්න', 'Select a teacher');
  String get selectDate => pick('දිනය තෝරන්න', 'Select date');
  String get toggleWorkingDay => pick('වැඩ කරන දිනයක් කරන්න', 'Toggle working day');
  String get markAllRead => pick('සියල්ල කියවූ ලෙස සලකුණු කරන්න', 'Mark all as read');
  String get noNotifications => pick('නව දැනුම්දීම් නොමැත', 'No new notifications');
}
