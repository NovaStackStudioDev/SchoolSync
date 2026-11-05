import 'user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.schoolId,
    required this.isActive,
    this.email,
  });

  final String id;
  final String fullName;
  final UserRole role;
  final String schoolId;
  final bool isActive;
  final String? email;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? 'Staff member',
      role: UserRoleX.fromString(map['role'] as String?) ?? UserRole.teacher,
      schoolId: map['school_id'] as String? ?? '',
      isActive: map['is_active'] == true,
      email: map['email'] as String?,
    );
  }
}
