import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

class LocaleController extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    Future.microtask(_restore);
    return const Locale('si');
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == 'en' || code == 'si') {
      state = Locale(code!);
    }
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'si' ? const Locale('en') : const Locale('si');
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class L10nScope extends InheritedWidget {
  const L10nScope({
    super.key,
    required this.strings,
    required this.toggleLanguage,
    required super.child,
  });

  final AppStrings strings;
  final VoidCallback toggleLanguage;

  static L10nScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<L10nScope>() ??
        const L10nScope(
          strings: AppStrings(true),
          toggleLanguage: _noop,
          child: SizedBox.shrink(),
        );
  }

  static void _noop() {}

  @override
  bool updateShouldNotify(L10nScope oldWidget) {
    return oldWidget.strings.sinhala != strings.sinhala;
  }
}
