import 'package:flutter/material.dart';

import '../../../core/models/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_surface.dart';
import '../../../core/widgets/school_logo.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _step = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BrandWaves(height: 150),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _step == 0
                      ? Column(
                          key: const ValueKey('intro'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SchoolLogo(size: 94),
                            const SizedBox(height: 14),
                            const _Wordmark(),
                            const SchoolIllustration(),
                            const Text(
                              'Streamline\nSchool Operations',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Teachers, students, attendance and more.\nYour school, connected in one place.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.muted,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => setState(() => _step = 1),
                                child: const Text('Get Started'),
                              ),
                            ),
                            const SizedBox(height: 85),
                          ],
                        )
                      : Column(
                          key: const ValueKey('roles'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SchoolLogo(size: 96),
                            const SizedBox(height: 22),
                            const Text(
                              'Welcome to',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const _Wordmark(),
                            const SizedBox(height: 40),
                            const Text(
                              'Continue as',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _role(
                              UserRole.principal,
                              Icons.person_rounded,
                              'Manage your school',
                            ),
                            const SizedBox(height: 14),
                            _role(
                              UserRole.teacher,
                              Icons.school_rounded,
                              'Manage your classes',
                            ),
                            const SizedBox(height: 130),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _role(UserRole role, IconData icon, String subtitle) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Icon(
        icon,
        color: role == UserRole.principal
            ? AppColors.goldDeep
            : AppColors.greenDark,
        size: 38,
      ),
      title: Text(
        role.label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => LoginScreen(role: role))),
    ),
  );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();
  @override
  Widget build(BuildContext context) => RichText(
    text: const TextSpan(
      style: TextStyle(
        fontSize: 34,
        fontFamily: 'Nirmala UI',
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      children: [
        TextSpan(
          text: 'School',
          style: TextStyle(color: AppColors.greenDeep),
        ),
        TextSpan(
          text: 'Sync',
          style: TextStyle(color: AppColors.greenDark),
        ),
      ],
    ),
  );
}
