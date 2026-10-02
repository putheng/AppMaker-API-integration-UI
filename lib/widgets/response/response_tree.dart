import 'package:flutter/material.dart';

import '../../models/response_field.dart';
import '../../theme/theme.dart';
import '../common/badges.dart';

IconData fieldKindIcon(FieldKind kind) => switch (kind) {
  FieldKind.string => Icons.text_fields,
  FieldKind.number => Icons.numbers,
  FieldKind.boolean => Icons.toggle_on_outlined,
  FieldKind.list => Icons.data_array,
  FieldKind.object => Icons.data_object,
  FieldKind.nullValue => Icons.block,
};

/// Renders an API response schema as an interactive, expandable tree.
class ResponseTreeView extends StatelessWidget {
  const ResponseTreeView({
    super.key,
    required this.root,
    this.selectedPath,
    this.onSelect,
  });

  final ResponseField root;
  final String? selectedPath;
  final ValueChanged<ResponseField>? onSelect;

  @override
  Widget build(BuildContext context) {
    return _TreeNode(
      field: root,
      depth: 0,
      selectedPath: selectedPath,
      onSelect: onSelect,
    );
  }
}

class _TreeNode extends StatefulWidget {
  const _TreeNode({
    super.key,
    required this.field,
    required this.depth,
    required this.selectedPath,
    required this.onSelect,
  });

  final ResponseField field;
  final int depth;
  final String? selectedPath;
  final ValueChanged<ResponseField>? onSelect;

  @override
  State<_TreeNode> createState() => _TreeNodeState();
}

class _TreeNodeState extends State<_TreeNode> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.depth < 2;
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final selected = widget.selectedPath == field.path;
    final kindColor = fieldKindColor(field.kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.onSelect == null ? null : () => widget.onSelect!(field),
          borderRadius: AppRadius.smAll,
          child: Container(
            padding: EdgeInsets.only(
              left: AppSpacing.xs + widget.depth * 16,
              right: AppSpacing.sm,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySubtle : null,
              borderRadius: AppRadius.smAll,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (field.children.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: AppSpacing.xs),
                Icon(fieldKindIcon(field.kind), size: 14, color: kindColor),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    field.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.code.copyWith(
                      color: selected ? AppColors.textPrimary : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (field.preview != null)
                  Flexible(
                    child: Text(
                      field.preview!,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                TagChip(
                  label: fieldKindLabel(field.kind),
                  color: kindColor,
                  dense: true,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          for (final child in field.children)
            _TreeNode(
              key: ValueKey(child.path),
              field: child,
              depth: widget.depth + 1,
              selectedPath: widget.selectedPath,
              onSelect: widget.onSelect,
            ),
      ],
    );
  }
}
