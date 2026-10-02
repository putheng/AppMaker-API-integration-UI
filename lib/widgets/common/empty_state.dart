import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textTertiary, size: 24),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
