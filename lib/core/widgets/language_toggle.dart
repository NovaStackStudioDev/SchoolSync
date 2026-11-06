import 'package:flutter/material.dart';

import '../l10n/l10n_scope.dart';
import '../theme/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scope = L10nScope.of(context);
    return TextButton(
      onPressed: scope.toggleLanguage,
      child: Text(
        scope.strings.otherLanguage,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: onDark ? AppColors.gold : AppColors.greenDeep,
        ),
      ),
    );
  }
}
