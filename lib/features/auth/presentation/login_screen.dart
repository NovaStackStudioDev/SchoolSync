import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_role.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../core/widgets/school_logo.dart';
import '../data/auth_repository.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.role});
  final UserRole? role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthRepository().login(
        email: _email.text,
        password: _password.text,
        expectedRole: widget.role,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AppAuthException catch (error) {
      if (mounted) {
        final strings = L10nScope.of(context).strings;
        setState(() {
          _error = switch (error.code) {
            'email_not_confirmed' => strings.emailNotConfirmed,
            'invalid_credentials' => strings.signInFailed,
            _ => error.detail ?? strings.signInFailed,
          };
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '${L10nScope.of(context).strings.signInFailed}\n$error';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.background],
            stops: [0.0, 0.38],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageToggle(),
                    ),
                    const SchoolLogo(size: 112),
                    const SizedBox(height: 16),
                    Text(
                      strings.schoolName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.greenDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.sinhala
                          ? AppConstants.schoolName
                          : AppConstants.schoolNameSi,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greenDeep.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              AppConstants.appName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.tagline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: strings.email,
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || !value.contains('@')
                                  ? strings.validEmail
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: strings.password,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? strings.passwordRequired
                                  : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(color: AppColors.danger),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        if (!_email.text.contains('@')) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(strings.validEmail),
                                            ),
                                          );
                                          return;
                                        }
                                        await runAction(
                                          context,
                                          () => AuthRepository().resetPassword(
                                            _email.text,
                                          ),
                                          success: 'Password reset email sent.',
                                        );
                                      },
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            FilledButton(
                              onPressed: _loading ? null : _login,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(strings.signIn),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(strings.newTeacher),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.accessNote,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
