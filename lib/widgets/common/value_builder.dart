import 'package:flutter/material.dart';

import '../../models/app_variable.dart';
import '../../models/value_node.dart';
import '../../theme/theme.dart';
import 'fields.dart';
import 'panel.dart';

IconData valueKindIcon(ValueKind kind) => switch (kind) {
  ValueKind.text => Icons.text_fields,
  ValueKind.number => Icons.numbers,
  ValueKind.boolean => Icons.toggle_on_outlined,
  ValueKind.map => Icons.data_object,
  ValueKind.list => Icons.data_array,
  ValueKind.nullValue => Icons.block,
};

Color valueKindColor(ValueKind kind) => switch (kind) {
  ValueKind.text => AppColors.warning,
  ValueKind.number => AppColors.info,
  ValueKind.boolean => AppColors.success,
  ValueKind.map => AppColors.primary,
  ValueKind.list => const Color(0xFFA78BFA),
  ValueKind.nullValue => AppColors.textTertiary,
};

String valueKindLabel(ValueKind kind) => switch (kind) {
  ValueKind.text => 'Text',
  ValueKind.number => 'Number',
  ValueKind.boolean => 'Boolean',
  ValueKind.map => 'Map',
  ValueKind.list => 'List',
  ValueKind.nullValue => 'Null',
};

/// Structured editor for a variable's initial value. Primitive types get a
/// single control; containers get a nested tree, mirroring the design of the
/// standalone `variable` builder.
class ValueBuilder extends StatefulWidget {
  const ValueBuilder({
    super.key,
    required this.variable,
    required this.onChanged,
  });

  final AppVariable variable;

  /// Called with the new raw initial value (`true`/`false`, a number, plain
  /// text, or formatted JSON for containers).
  final ValueChanged<String> onChanged;

  @override
  State<ValueBuilder> createState() => _ValueBuilderState();
}

class _ValueBuilderState extends State<ValueBuilder> {
  late ValueNode _root;
  late final TextEditingController _primitiveController;

  @override
  void initState() {
    super.initState();
    _root = ValueNode.parse(widget.variable.initialValue, widget.variable.type);
    _primitiveController = TextEditingController(
      text: widget.variable.initialValue,
    );
  }

  @override
  void dispose() {
    _primitiveController.dispose();
    super.dispose();
  }

  /// Kinds offered when adding to a list. Strictly typed primitive lists
  /// only accept their element type; object/map lists accept anything.
  List<ValueKind>? get _listAllowedKinds {
    if (widget.variable.type != VariableType.list) return null;
    return switch (widget.variable.elementType) {
      VariableType.string => const [ValueKind.text],
      VariableType.number => const [ValueKind.number],
      VariableType.boolean => const [ValueKind.boolean],
      _ => null,
    };
  }

  void _emitTree() => widget.onChanged(_root.encode());

  void _addChild(String parentId, ValueKind kind) {
    setState(() {
      _root = ValueNode.addChild(_root, parentId, ValueNode.empty(kind));
    });
    _emitTree();
  }

  void _changeKey(String id, String key) {
    setState(() {
      _root = ValueNode.update(_root, id, (node) => node.copyWith(key: key));
    });
    _emitTree();
  }

  void _changeValue(String id, Object? value) {
    setState(() {
      _root = ValueNode.update(_root, id, (node) => node.copyWith(value: value));
    });
    _emitTree();
  }

  void _remove(String id) {
    setState(() => _root = ValueNode.remove(_root, id));
    _emitTree();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variable.type) {
      case VariableType.string:
        return AppTextField(
          controller: _primitiveController,
          monospace: true,
          minLines: 3,
          maxLines: 6,
          hintText: 'Text value',
          onChanged: widget.onChanged,
        );
      case VariableType.number:
        return AppTextField(
          controller: _primitiveController,
          monospace: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          hintText: '0',
          onChanged: widget.onChanged,
        );
      case VariableType.boolean:
        final isTrue = _root.value == true;
        return AppPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                valueKindIcon(ValueKind.boolean),
                size: 18,
                color: valueKindColor(ValueKind.boolean),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  isTrue ? 'true' : 'false',
                  style: AppTypography.code,
                ),
              ),
              Switch(
                value: isTrue,
                onChanged: (value) {
                  setState(
                    () => _root = _root.copyWith(value: value),
                  );
                  widget.onChanged(value ? 'true' : 'false');
                },
              ),
            ],
          ),
        );
      case VariableType.list:
      case VariableType.map:
      case VariableType.object:
      case VariableType.json:
        return _buildTree();
    }
  }

  Widget _buildTree() {
    final isList = _root.kind == ValueKind.list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPanel(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _root.children.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    isList
                        ? 'Empty list. Add the first item below.'
                        : 'Empty map. Add the first field below.',
                    style: AppTypography.bodySmall,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _root.children.length; i++)
                      _ValueNodeTile(
                        key: ValueKey(_root.children[i].id),
                        node: _root.children[i],
                        depth: 0,
                        index: i,
                        parentIsList: isList,
                        allowedKinds: isList ? _listAllowedKinds : null,
                        onChangeKey: _changeKey,
                        onChangeValue: _changeValue,
                        onAddChild: _addChild,
                        onRemove: _remove,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: _AddChildButton(
            allowedKinds: isList ? _listAllowedKinds : null,
            label: isList ? 'Add item' : 'Add field',
            onSelected: (kind) => _addChild(_root.id, kind),
          ),
        ),
      ],
    );
  }
}

class _ValueNodeTile extends StatefulWidget {
  const _ValueNodeTile({
    super.key,
    required this.node,
    required this.depth,
    required this.index,
    required this.parentIsList,
    required this.allowedKinds,
    required this.onChangeKey,
    required this.onChangeValue,
    required this.onAddChild,
    required this.onRemove,
  });

  final ValueNode node;
  final int depth;
  final int index;
  final bool parentIsList;
  final List<ValueKind>? allowedKinds;
  final void Function(String id, String key) onChangeKey;
  final void Function(String id, Object? value) onChangeValue;
  final void Function(String parentId, ValueKind kind) onAddChild;
  final void Function(String id) onRemove;

  @override
  State<_ValueNodeTile> createState() => _ValueNodeTileState();
}

class _ValueNodeTileState extends State<_ValueNodeTile> {
  bool _expanded = true;
  late final TextEditingController _keyController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.node.key);
    _valueController = TextEditingController(
      text: widget.node.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ValueNodeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.key != _keyController.text) {
      _keyController.text = widget.node.key;
    }
    final valueText = widget.node.value?.toString() ?? '';
    if (valueText != _valueController.text) {
      _valueController.text = valueText;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final color = valueKindColor(node.kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: widget.depth * 18,
            top: AppSpacing.xxs,
            bottom: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: node.isContainer && node.children.isNotEmpty
                    ? InkWell(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Icon(
                          _expanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
              ),
              Icon(valueKindIcon(node.kind), size: 16, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 4,
                child: widget.parentIsList
                    ? Text(
                        '[${widget.index}]',
                        style: AppTypography.code.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      )
                    : AppTextField(
                        controller: _keyController,
                        monospace: true,
                        hintText: 'key',
                        onChanged: (value) =>
                            widget.onChangeKey(node.id, value),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 5, child: _buildValueCell(node)),
              if (node.isContainer)
                _AddChildButton(
                  dense: true,
                  allowedKinds: widget.allowedKinds,
                  onSelected: (kind) => widget.onAddChild(node.id, kind),
                )
              else
                const SizedBox(width: 28),
              IconButton(
                onPressed: () => widget.onRemove(node.id),
                tooltip: 'Remove',
                icon: const Icon(Icons.close, size: 15),
                color: AppColors.textTertiary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (node.isContainer && _expanded)
          for (var i = 0; i < node.children.length; i++)
            _ValueNodeTile(
              key: ValueKey(node.children[i].id),
              node: node.children[i],
              depth: widget.depth + 1,
              index: i,
              parentIsList: node.kind == ValueKind.list,
              allowedKinds: null,
              onChangeKey: widget.onChangeKey,
              onChangeValue: widget.onChangeValue,
              onAddChild: widget.onAddChild,
              onRemove: widget.onRemove,
            ),
      ],
    );
  }

  Widget _buildValueCell(ValueNode node) {
    switch (node.kind) {
      case ValueKind.text:
        return AppTextField(
          controller: _valueController,
          monospace: true,
          hintText: 'value',
          onChanged: (value) => widget.onChangeValue(node.id, value),
        );
      case ValueKind.number:
        return AppTextField(
          controller: _valueController,
          monospace: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          hintText: '0',
          onChanged: (value) =>
              widget.onChangeValue(node.id, num.tryParse(value.trim()) ?? 0),
        );
      case ValueKind.boolean:
        return Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: node.value == true,
            onChanged: (value) => widget.onChangeValue(node.id, value),
          ),
        );
      case ValueKind.map:
        return Text(
          '{${node.children.length}}',
          style: AppTypography.code.copyWith(color: AppColors.textTertiary),
        );
      case ValueKind.list:
        return Text(
          '[${node.children.length}]',
          style: AppTypography.code.copyWith(color: AppColors.textTertiary),
        );
      case ValueKind.nullValue:
        return Text(
          'null',
          style: AppTypography.code.copyWith(color: AppColors.textTertiary),
        );
    }
  }
}

class _AddChildButton extends StatelessWidget {
  const _AddChildButton({
    required this.onSelected,
    this.allowedKinds,
    this.label,
    this.dense = false,
  });

  final ValueChanged<ValueKind> onSelected;
  final List<ValueKind>? allowedKinds;
  final String? label;
  final bool dense;

  static const List<ValueKind> _allKinds = [
    ValueKind.text,
    ValueKind.number,
    ValueKind.boolean,
    ValueKind.map,
    ValueKind.list,
    ValueKind.nullValue,
  ];

  List<ValueKind> get _kinds => allowedKinds ?? _allKinds;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ValueKind>(
      tooltip: label ?? 'Add child',
      padding: EdgeInsets.zero,
      iconSize: 16,
      onSelected: onSelected,
      itemBuilder: _menu,
      icon: dense
          ? const Icon(Icons.add, size: 16, color: AppColors.primary)
          : null,
      child: dense ? null : _TriggerButton(label: label ?? 'Add field'),
    );
  }

  List<PopupMenuEntry<ValueKind>> _menu(BuildContext context) => [
    for (final kind in _kinds)
      PopupMenuItem(
        value: kind,
        child: Row(
          children: [
            Icon(valueKindIcon(kind), size: 18, color: valueKindColor(kind)),
            const SizedBox(width: AppSpacing.md),
            Text('Add ${valueKindLabel(kind)}'),
          ],
        ),
      ),
  ];
}

class _TriggerButton extends StatelessWidget {
  const _TriggerButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.control,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.labelLarge),
        ],
      ),
    );
  }
}
