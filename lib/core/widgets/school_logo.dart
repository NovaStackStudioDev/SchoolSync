import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDeep.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.gold, width: 3),
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Image.asset(
          AppConstants.logoAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
