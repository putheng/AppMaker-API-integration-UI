import 'package:flutter/material.dart';

import '../../models/api_definition.dart';
import '../../models/app_variable.dart';
import '../../models/response_field.dart';
import '../../theme/theme.dart';

const Color _objectColor = Color(0xFFA78BFA);
const Color _nullColor = Color(0xFF5C6470);

Color methodColor(HttpMethod method) => switch (method) {
  HttpMethod.get => AppColors.info,
  HttpMethod.post => AppColors.success,
  HttpMethod.put => AppColors.warning,
  HttpMethod.patch => AppColors.primary,
  HttpMethod.delete => AppColors.error,
};

String variableTypeLabel(VariableType type) => switch (type) {
  VariableType.string => 'String',
  VariableType.number => 'Number',
  VariableType.boolean => 'Boolean',
  VariableType.list => 'List',
  VariableType.map => 'Map',
  VariableType.object => 'Object',
  VariableType.json => 'JSON',
};

Color variableTypeColor(VariableType type) => switch (type) {
  VariableType.string => AppColors.info,
  VariableType.number => AppColors.warning,
  VariableType.boolean => AppColors.success,
  VariableType.list => AppColors.primary,
  VariableType.map => _objectColor,
  VariableType.object => _objectColor,
  VariableType.json => AppColors.textSecondary,
};

/// Element types that can appear inside a `List<...>`.
const List<VariableType> listElementTypes = [
  VariableType.string,
  VariableType.number,
  VariableType.boolean,
  VariableType.map,
  VariableType.object,
];

/// The strict, Flutter-style type name for a variable. Maps are always
/// rendered as `Map<String, dynamic>`, and lists include their element type
/// (e.g. `List<String>`, `List<Map<String, dynamic>>`).
String variableDisplayType(VariableType type, [VariableType? elementType]) {
  switch (type) {
    case VariableType.map:
      return 'Map<String, dynamic>';
    case VariableType.list:
      final element = elementType ?? VariableType.string;
      final label = element == VariableType.map
          ? 'Map<String, dynamic>'
          : variableTypeLabel(element);
      return 'List<$label>';
    default:
      return variableTypeLabel(type);
  }
}

Color variableDisplayColor(VariableType type, [VariableType? elementType]) {
  if (type == VariableType.map) return _objectColor;
  if (type == VariableType.list && elementType != null) {
    return variableTypeColor(elementType);
  }
  return variableTypeColor(type);
}

String fieldKindLabel(FieldKind kind) => switch (kind) {
  FieldKind.string => 'String',
  FieldKind.number => 'Number',
  FieldKind.boolean => 'Boolean',
  FieldKind.list => 'List',
  FieldKind.object => 'Object',
  FieldKind.nullValue => 'Null',
};

Color fieldKindColor(FieldKind kind) => switch (kind) {
  FieldKind.string => AppColors.info,
  FieldKind.number => AppColors.warning,
  FieldKind.boolean => AppColors.success,
  FieldKind.list => AppColors.primary,
  FieldKind.object => _objectColor,
  FieldKind.nullValue => _nullColor,
};

/// Small monospace-ish pill used for HTTP methods, types and scopes.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class MethodChip extends StatelessWidget {
  const MethodChip(this.method, {super.key, this.dense = false});

  final HttpMethod method;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TagChip(
      label: method.label,
      color: methodColor(method),
      dense: dense,
    );
  }
}

class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key, this.elementType, this.dense = false});

  final VariableType type;
  final VariableType? elementType;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TagChip(
      label: variableDisplayType(type, elementType),
      color: variableDisplayColor(type, elementType),
      dense: dense,
    );
  }
}

class ScopeBadge extends StatelessWidget {
  const ScopeBadge(this.scope, {super.key, this.dense = true});

  final VariableScope scope;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (scope) {
      VariableScope.global => ('global', AppColors.primary),
      VariableScope.page => ('page', AppColors.info),
      VariableScope.session => ('session', AppColors.warning),
    };
    return TagChip(label: label, color: color, dense: dense);
  }
}
