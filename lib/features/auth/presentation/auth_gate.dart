import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/school_logo.dart';
import '../../principal/presentation/principal_dashboard.dart';
import '../../teacher/presentation/teacher_dashboard.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/auth_repository.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthRepository();
  late final Stream<AuthState> _changes = _auth.authChanges;
  bool _recovered = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _changes,
      builder: (context, snapshot) {
        if (_auth.currentUser == null) {
          return const WelcomeScreen();
        }
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery &&
            !_recovered) {
          return ResetPasswordScreen(
            onDone: () => setState(() => _recovered = true),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _auth.getProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const _Splash();
            }

            final strings = L10nScope.of(context).strings;
            if (profileSnapshot.hasError) {
              return _StatusScreen(
                message:
                    '${strings.profileLoadFailed}\n${profileSnapshot.error}',
                onRetry: () => setState(() {}),
                onLogout: _auth.logout,
              );
            }

            final data = profileSnapshot.data;
            if (data == null) {
              return _StatusScreen(
                message: strings.profileMissing,
                onLogout: _auth.logout,
              );
            }

            final profile = Profile.fromMap(data);
            if (!profile.isActive) {
              return _StatusScreen(
                message: strings.profileInactive,
                onLogout: _auth.logout,
              );
            }

            switch (profile.role) {
              case UserRole.principal:
                return const PrincipalDashboard();
              case UserRole.teacher:
                return TeacherDashboard(profile: profile);
            }
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.greenDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SchoolLogo(size: 96),
            SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

class _StatusScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Future<void> Function() onLogout;

  const _StatusScreen({
    required this.message,
    this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SchoolLogo(size: 72),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(L10nScope.of(context).strings.retry),
                ),
              TextButton(
                onPressed: () async => onLogout(),
                child: Text(L10nScope.of(context).strings.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
