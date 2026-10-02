import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_variable.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
import '../utils/id.dart';
import '../widgets/common/badges.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/fields.dart';
import '../widgets/common/panel.dart';
import '../widgets/common/value_builder.dart';

class VariablesScreen extends ConsumerWidget {
  const VariablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variables = ref.watch(variablesProvider);
    final selected = variables.byId(ref.watch(selectedVariableIdProvider));

    void addVariable() {
      final id = newId('var');
      ref.read(variablesProvider.notifier).add(
            AppVariable(
              id: id,
              name: 'newVariable',
              type: VariableType.string,
            ),
          );
      ref.read(selectedVariableIdProvider.notifier).select(id);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: 'Application state',
            subtitle:
                'Reusable variables that APIs write to and widgets read from.',
            icon: Icons.data_object_outlined,
            onAdd: addVariable,
            addLabel: 'New variable',
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 300,
                  child: ListView.separated(
                    itemCount: variables.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final variable = variables[index];
                      return ProviderScope(
                        key: ValueKey(variable.id),
                        overrides: [
                          currentVariableProvider.overrideWithValue(variable),
                        ],
                        child: const VariableTile(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: selected == null
                      ? const EmptyState(
                          icon: Icons.data_object_outlined,
                          title: 'No variable selected',
                          message:
                              'Create a variable to store API responses and bind them to widgets.',
                        )
                      : _VariableEditor(
                          key: ValueKey(selected.id),
                          variable: selected,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single variable row. Reads its variable from the overridden
/// [currentVariableProvider] and its selection from [selectedVariableIdProvider].
class VariableTile extends ConsumerWidget {
  const VariableTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variable = ref.watch(currentVariableProvider);
    final selected = ref.watch(
      selectedVariableIdProvider.select((id) => id == variable.id),
    );

    return Material(
      color: selected ? AppColors.surfaceHover : AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: () =>
            ref.read(selectedVariableIdProvider.notifier).select(variable.id),
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  variable.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontFamily: 'SF Mono',
                  ),
                ),
              ),
              TypeBadge(
                variable.type,
                elementType: variable.elementType,
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariableEditor extends ConsumerStatefulWidget {
  const _VariableEditor({super.key, required this.variable});

  final AppVariable variable;

  @override
  ConsumerState<_VariableEditor> createState() => _VariableEditorState();
}

class _VariableEditorState extends ConsumerState<_VariableEditor> {
  late final TextEditingController _name;
  late final TextEditingController _initial;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.variable.name);
    _initial = TextEditingController(text: widget.variable.initialValue);
    _description = TextEditingController(text: widget.variable.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _initial.dispose();
    _description.dispose();
    super.dispose();
  }

  void _push({
    String? name,
    VariableType? type,
    VariableType? elementType,
    String? initial,
    InitialValueMode? valueMode,
    String? description,
  }) {
    ref.read(variablesProvider.notifier).updateVariable(
          widget.variable.copyWith(
            name: name,
            type: type,
            elementType: elementType,
            initialValue: initial,
            valueMode: valueMode,
            description: description,
          ),
        );
  }

  void _delete() {
    ref.read(variablesProvider.notifier).remove(widget.variable.id);
    final remaining = ref.read(variablesProvider);
    ref
        .read(selectedVariableIdProvider.notifier)
        .select(remaining.isEmpty ? null : remaining.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final variable = widget.variable;

    return SingleChildScrollView(
      child: AppPanel(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Edit variable', style: AppTypography.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppField(
                    label: 'Name',
                    helper: 'Referenced in expressions, e.g. "{{var.products}}".',
                    child: AppTextField(
                      controller: _name,
                      monospace: true,
                      onChanged: (value) => _push(name: value.trim()),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: AppField(
                    label: 'Type',
                    child: AppDropdown<VariableType>(
                      value: variable.type,
                      items: [
                        for (final type in VariableType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                TagChip(
                                  label: variableTypeLabel(type),
                                  color: variableTypeColor(type),
                                  dense: true,
                                ),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (type) {
                        if (type == null) return;
                        if (type == VariableType.list &&
                            variable.elementType == null) {
                          _push(type: type, elementType: VariableType.string);
                        } else {
                          _push(type: type);
                        }
                      },
                    ),
                  ),
                ),
                if (variable.type == VariableType.list) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppField(
                      label: 'Element type',
                      child: AppDropdown<VariableType>(
                        value: variable.elementType ?? VariableType.string,
                        items: [
                          for (final element in listElementTypes)
                            DropdownMenuItem(
                              value: element,
                              child: Text(
                                element == VariableType.map
                                    ? 'Map<String, dynamic>'
                                    : variableTypeLabel(element),
                              ),
                            ),
                        ],
                        onChanged: (element) {
                          if (element == null) return;
                          _push(elementType: element);
                        },
                      ),
                    ),
                  ),
                ] else if (variable.type == VariableType.map) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppField(
                      label: 'Value type',
                      child: Container(
                        height: AppSpacing.control,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 15,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Map<String, dynamic>',
                              style: AppTypography.code,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Initial value',
                    style: AppTypography.labelMedium,
                  ),
                ),
                SegmentedButton<InitialValueMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: InitialValueMode.builder,
                      label: Text('Builder'),
                      icon: Icon(Icons.account_tree_outlined, size: 15),
                    ),
                    ButtonSegment(
                      value: InitialValueMode.code,
                      label: Text('Code'),
                      icon: Icon(Icons.code, size: 15),
                    ),
                  ],
                  selected: {variable.valueMode},
                  onSelectionChanged: (selection) =>
                      _push(valueMode: selection.first),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (variable.valueMode == InitialValueMode.code)
              AppTextField(
                controller: _initial,
                monospace: true,
                minLines: 3,
                maxLines: 6,
                onChanged: (value) => _push(initial: value),
              )
            else
              ValueBuilder(
                key: ValueKey(
                  'builder_${variable.id}_${variable.type.name}_${variable.elementType?.name}',
                ),
                variable: variable,
                onChanged: (value) {
                  _initial.text = value;
                  _push(initial: value);
                },
              ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              label: 'Description',
              child: AppTextField(
                controller: _description,
                maxLines: 2,
                minLines: 2,
                onChanged: (value) => _push(description: value),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'This variable can be written by a "Set Variable" step and read by widget bindings.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
