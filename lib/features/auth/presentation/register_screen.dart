import 'package:flutter/material.dart';

import '../../../core/constants/school_subjects.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../core/widgets/school_logo.dart';
import '../data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _employee = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _subjects = <String>{};
  bool _loading = false;
  bool _obscure = true;
  String? _message;
  bool _success = false;

  Future<void> _register() async {
    final strings = L10nScope.of(context).strings;
    if (!_formKey.currentState!.validate()) return;
    if (_subjects.isEmpty) {
      setState(() {
        _success = false;
        _message = strings.pickSubject;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _success = false;
    });

    try {
      final result = await AuthRepository().registerTeacher(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        subjects: _subjects.toList(),
        phone: _phone.text,
        employeeNumber: _employee.text,
      );
      if (!mounted) return;
      if (result.needsEmailConfirmation) {
        setState(() {
          _success = true;
          _message = L10nScope.of(context).strings.checkEmailThenLogin;
        });
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AppAuthException catch (error) {
      if (!mounted) return;
      setState(() => _message = _textFor(error, L10nScope.of(context).strings));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '${L10nScope.of(context).strings.registerFailed}\n$error';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _textFor(AppAuthException error, AppStrings strings) {
    switch (error.code) {
      case 'already_registered':
        return strings.alreadyRegistered;
      case 'email_not_confirmed':
        return strings.emailNotConfirmed;
      case 'weak_password':
        return strings.passwordShort;
      default:
        return error.detail == null
            ? strings.registerFailed
            : '${strings.registerFailed}\n${error.detail}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _employee.dispose();
    _password.dispose();
    _confirm.dispose();
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
            colors: [AppColors.greenDeep, AppColors.background],
            stops: [0.0, 0.32],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageToggle(onDark: true),
                    ),
                    const SchoolLogo(size: 88),
                    const SizedBox(height: 12),
                    Text(
                      strings.schoolName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              strings.createAccount,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenDeep,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: strings.fullName,
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().length < 3
                                  ? strings.nameRequired
                                  : null,
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
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
                                  value == null || value.length < 6
                                  ? strings.passwordShort
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirm,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: strings.confirmPassword,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                              ),
                              validator: (value) => value != _password.text
                                  ? strings.passwordMismatch
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText:
                                    '${strings.phone} (${strings.optional})',
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _employee,
                              decoration: InputDecoration(
                                labelText:
                                    '${strings.employeeNumber} (${strings.optional})',
                                prefixIcon: const Icon(Icons.numbers_rounded),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings.subjectYouTeach,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final subject in schoolSubjects)
                                  FilterChip(
                                    label: Text(subject.label(strings.sinhala)),
                                    selected: _subjects.contains(subject.code),
                                    selectedColor: AppColors.gold,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _subjects.add(subject.code);
                                        } else {
                                          _subjects.remove(subject.code);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _message!,
                                style: TextStyle(
                                  color: _success
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _loading ? null : _register,
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
                                    : Text(strings.register),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(strings.haveAccount),
                            ),
                          ],
                        ),
                      ),
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
