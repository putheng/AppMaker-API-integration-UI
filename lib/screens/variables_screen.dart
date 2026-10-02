import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_variable.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/badges.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/fields.dart';
import '../widgets/common/panel.dart';

class VariablesScreen extends ConsumerStatefulWidget {
  const VariablesScreen({super.key});

  @override
  ConsumerState<VariablesScreen> createState() => _VariablesScreenState();
}

class _VariablesScreenState extends ConsumerState<VariablesScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final variables = ref.read(variablesProvider);
    _selectedId = variables.isEmpty ? null : variables.first.id;
  }

  void _addVariable() {
    final id = 'var_${DateTime.now().microsecondsSinceEpoch}';
    final variable = AppVariable(
      id: id,
      name: 'newVariable',
      type: VariableType.string,
      initialValue: '',
    );
    ref.read(variablesProvider.notifier).add(variable);
    setState(() => _selectedId = id);
  }

  @override
  Widget build(BuildContext context) {
    final variables = ref.watch(variablesProvider);
    final selected = variables.byId(_selectedId);

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
            onAdd: _addVariable,
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
                      return _VariableTile(
                        variable: variable,
                        selected: variable.id == _selectedId,
                        onTap: () =>
                            setState(() => _selectedId = variable.id),
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
                          onChanged: (updated) => ref
                              .read(variablesProvider.notifier)
                              .updateVariable(updated),
                          onDelete: () {
                            ref
                                .read(variablesProvider.notifier)
                                .remove(selected.id);
                            final remaining = ref.read(variablesProvider);
                            setState(() {
                              _selectedId =
                                  remaining.isEmpty ? null : remaining.first.id;
                            });
                          },
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

class _VariableTile extends StatelessWidget {
  const _VariableTile({
    required this.variable,
    required this.selected,
    required this.onTap,
  });

  final AppVariable variable;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceHover : AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ScopeBadge(variable.scope),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      '= ${variable.initialValue.isEmpty ? '—' : variable.initialValue}',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariableEditor extends StatefulWidget {
  const _VariableEditor({
    super.key,
    required this.variable,
    required this.onChanged,
    required this.onDelete,
  });

  final AppVariable variable;
  final ValueChanged<AppVariable> onChanged;
  final VoidCallback onDelete;

  @override
  State<_VariableEditor> createState() => _VariableEditorState();
}

class _VariableEditorState extends State<_VariableEditor> {
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
    VariableScope? scope,
    String? initial,
    String? description,
  }) {
    widget.onChanged(
      widget.variable.copyWith(
        name: name,
        type: type,
        elementType: elementType,
        scope: scope,
        initialValue: initial,
        description: description,
      ),
    );
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
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppField(
              label: 'Name',
              helper: 'Referenced in expressions, e.g. "{{products}}".',
              child: AppTextField(
                controller: _name,
                monospace: true,
                onChanged: (value) => _push(name: value.trim()),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: AppField(
                    label: 'Scope',
                    child: AppDropdown<VariableScope>(
                      value: variable.scope,
                      items: [
                        for (final scope in VariableScope.values)
                          DropdownMenuItem(
                            value: scope,
                            child: Text(scope.name),
                          ),
                      ],
                      onChanged: (scope) {
                        if (scope == null) return;
                        _push(scope: scope);
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (variable.type == VariableType.list) ...[
              const SizedBox(height: AppSpacing.lg),
              AppField(
                label: 'Element type',
                helper: 'Produces a strict Flutter type, e.g. List<String>.',
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
            ],
            if (variable.type == VariableType.map) ...[
              const SizedBox(height: AppSpacing.lg),
              AppField(
                label: 'Value type',
                helper: 'Maps are always keyed by String in generated code.',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
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
            ],
            const SizedBox(height: AppSpacing.lg),
            AppField(
              label: 'Resulting type',
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypeBadge(
                  variable.type,
                  elementType: variable.elementType,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              label: 'Initial value',
              child: AppTextField(
                controller: _initial,
                monospace: true,
                minLines: 3,
                maxLines: 6,
                onChanged: (value) => _push(initial: value),
              ),
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
