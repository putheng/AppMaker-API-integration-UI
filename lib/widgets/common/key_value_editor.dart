import 'package:flutter/material.dart';

import '../../models/api_definition.dart';
import '../../theme/theme.dart';
import 'fields.dart';

/// Editable list of key/value rows (headers, query parameters, ...).
class KeyValueEditor extends StatelessWidget {
  const KeyValueEditor({
    super.key,
    required this.pairs,
    required this.onChanged,
    required this.onAdd,
    this.keyHint = 'Key',
    this.valueHint = 'Value',
    this.addLabel = 'Add row',
  });

  final List<KeyValuePair> pairs;
  final ValueChanged<List<KeyValuePair>> onChanged;
  final VoidCallback onAdd;
  final String keyHint;
  final String valueHint;
  final String addLabel;

  void _replace(KeyValuePair updated) {
    onChanged([
      for (final pair in pairs)
        if (pair.id == updated.id) updated else pair,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pairs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'No rows yet.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        for (final pair in pairs)
          Padding(
            key: ValueKey(pair.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _KeyValueRow(
              pair: pair,
              keyHint: keyHint,
              valueHint: valueHint,
              onChanged: _replace,
              onDelete: () =>
                  onChanged(pairs.where((p) => p.id != pair.id).toList()),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 15),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatefulWidget {
  const _KeyValueRow({
    required this.pair,
    required this.keyHint,
    required this.valueHint,
    required this.onChanged,
    required this.onDelete,
  });

  final KeyValuePair pair;
  final String keyHint;
  final String valueHint;
  final ValueChanged<KeyValuePair> onChanged;
  final VoidCallback onDelete;

  @override
  State<_KeyValueRow> createState() => _KeyValueRowState();
}

class _KeyValueRowState extends State<_KeyValueRow> {
  late final TextEditingController _keyController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.pair.key);
    _valueController = TextEditingController(text: widget.pair.value);
  }

  @override
  void didUpdateWidget(covariant _KeyValueRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pair.key != _keyController.text) {
      _keyController.text = widget.pair.key;
    }
    if (widget.pair.value != _valueController.text) {
      _valueController.text = widget.pair.value;
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
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: AppTextField(
            controller: _keyController,
            hintText: widget.keyHint,
            onChanged: (value) =>
                widget.onChanged(widget.pair.copyWith(key: value)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 6,
          child: AppTextField(
            controller: _valueController,
            hintText: widget.valueHint,
            monospace: true,
            onChanged: (value) =>
                widget.onChanged(widget.pair.copyWith(value: value)),
          ),
        ),
        IconButton(
          onPressed: widget.onDelete,
          tooltip: 'Remove',
          icon: const Icon(Icons.close, size: 16),
          color: AppColors.textTertiary,
        ),
      ],
    );
  }
}
