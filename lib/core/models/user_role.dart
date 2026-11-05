enum UserRole { principal, teacher }

extension UserRoleX on UserRole {
  String get label => this == UserRole.principal ? 'Principal' : 'Teacher';

  static UserRole? fromString(String? value) {
    switch (value) {
      case 'principal':
        return UserRole.principal;
      case 'teacher':
        return UserRole.teacher;
      default:
        return null;
    }
  }
}
