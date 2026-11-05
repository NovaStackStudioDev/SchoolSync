class SchoolSubject {
  const SchoolSubject({required this.code, required this.en, required this.si});

  final String code;
  final String en;
  final String si;

  String label(bool sinhala) => sinhala ? si : en;
}

const schoolSubjects = <SchoolSubject>[
  SchoolSubject(code: 'Mathematics', en: 'Mathematics', si: 'ගණිතය'),
  SchoolSubject(code: 'Science', en: 'Science', si: 'විද්‍යාව'),
  SchoolSubject(code: 'Sinhala', en: 'Sinhala', si: 'සිංහල'),
  SchoolSubject(code: 'English', en: 'English', si: 'ඉංග්‍රීසි'),
  SchoolSubject(code: 'Buddhism', en: 'Buddhism', si: 'බුද්ධ ධර්මය'),
  SchoolSubject(code: 'History', en: 'History', si: 'ඉතිහාසය'),
  SchoolSubject(code: 'Geography', en: 'Geography', si: 'භූගෝල විද්‍යාව'),
  SchoolSubject(code: 'ICT', en: 'ICT', si: 'තොරතුරු තාක්ෂණය'),
  SchoolSubject(code: 'Commerce', en: 'Commerce', si: 'වාණිජ'),
  SchoolSubject(code: 'Health', en: 'Health', si: 'සෞඛ්‍ය'),
  SchoolSubject(code: 'Art', en: 'Art', si: 'චිත්‍ර'),
  SchoolSubject(code: 'Music', en: 'Music', si: 'සංගීතය'),
  SchoolSubject(code: 'Dancing', en: 'Dancing', si: 'නර්තනය'),
  SchoolSubject(code: 'Tamil', en: 'Tamil', si: 'දෙමළ'),
  SchoolSubject(code: 'Agriculture', en: 'Agriculture', si: 'කෘෂිකර්මය'),
  SchoolSubject(code: 'Civic', en: 'Civic education', si: 'පුරවැසි අධ්‍යාපනය'),
];

String subjectLabel(String code, bool sinhala) {
  for (final subject in schoolSubjects) {
    if (subject.code == code || subject.en == code || subject.si == code) {
      return subject.label(sinhala);
    }
  }
  return code;
}
