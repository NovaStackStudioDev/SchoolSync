import 'package:flutter/material.dart';

import '../../../core/models/profile.dart';
import '../../dashboard/presentation/school_dashboard.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key, this.profile});
  final Profile? profile;
  @override
  Widget build(BuildContext context) => const SchoolDashboard(teacher: true);
}
