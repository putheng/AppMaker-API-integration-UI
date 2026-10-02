import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// A labelled form field wrapper.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        child,
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(helper!, style: AppTypography.labelSmall),
        ],
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.monospace = false,
    this.keyboardType,
    this.prefixIcon,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final bool monospace;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: (monospace ? AppTypography.code : AppTypography.bodyMedium)
          .copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 16, color: AppColors.textTertiary),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }
}

/// A lightweight, fully themed dropdown driven by [value].
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.height = AppSpacing.control,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          isDense: true,
          borderRadius: AppRadius.mdAll,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.textTertiary,
          ),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          hint: hint == null
              ? null
              : Text(hint!, style: AppTypography.bodyMedium),
        ),
      ),
    );
  }
}

/// Simple labelled dropdown for string values.
class AppStringDropdown extends StatelessWidget {
  const AppStringDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?>? onChanged;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : null;
    return AppDropdown<String>(
      value: safeValue,
      hint: hint,
      enabled: enabled,
      items: [
        for (final option in options)
          DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
