class Teacher {
  const Teacher({
    required this.id,
    required this.employeeNumber,
    required this.fullName,
    required this.subjects,
    required this.isActive,
    this.phone,
    this.email,
  });

  final String id;
  final String employeeNumber;
  final String fullName;
  final List<String> subjects;
  final bool isActive;
  final String? phone;
  final String? email;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
