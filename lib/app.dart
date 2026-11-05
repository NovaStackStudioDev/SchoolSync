import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_strings.dart';
import 'core/l10n/l10n_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

class SchoolSyncApp extends ConsumerWidget {
  const SchoolSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final sinhala = locale.languageCode != 'en';

    return L10nScope(
      strings: AppStrings(sinhala),
      toggleLanguage: () => ref.read(localeProvider.notifier).toggle(),
      child: MaterialApp(
        title: 'SchoolSync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: const [Locale('si'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthGate(),
      ),
    );
  }
}
