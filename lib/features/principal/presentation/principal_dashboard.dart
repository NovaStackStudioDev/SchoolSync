import 'package:flutter/material.dart';

import '../../dashboard/presentation/school_dashboard.dart';

class PrincipalDashboard extends StatelessWidget {
  const PrincipalDashboard({super.key});
  @override
  Widget build(BuildContext context) => const SchoolDashboard(teacher: false);
}
