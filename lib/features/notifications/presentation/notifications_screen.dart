import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/sample_data.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String key) {
    switch (key) {
      case 'swap':
        return Icons.swap_horiz_rounded;
      case 'leave':
        return Icons.event_available_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final items = SampleData.notifications();
    return Scaffold(
      appBar: BrandAppBar(title: strings.notifications),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.isRead ? Colors.white : AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.green.withValues(alpha: 0.15),
                  child: Icon(_icon(item.icon), color: AppColors.greenDeep),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(item.body, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('d MMM, h:mm a').format(item.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
