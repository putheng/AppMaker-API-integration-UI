import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// A surface container used throughout the builder.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.elevated = false,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lgAll,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final Color? color;
  final Color? borderColor;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (elevated ? AppColors.surfaceElevated : AppColors.surface),
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

/// Header row for a panel with an optional action.
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onAdd,
    this.addLabel = 'Add',
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle!, style: AppTypography.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: Text(addLabel),
          ),
      ],
    );
  }
}

/// Small uppercase section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(letterSpacing: 0.8),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
