import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/action_flow.dart';
import '../models/binding.dart';
import '../providers/action_flows_provider.dart';
import '../providers/bindings_provider.dart';
import '../providers/runtime_provider.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/badges.dart';
import '../widgets/common/fields.dart';
import '../widgets/common/panel.dart';

class BindingsScreen extends ConsumerStatefulWidget {
  const BindingsScreen({super.key});

  @override
  ConsumerState<BindingsScreen> createState() => _BindingsScreenState();
}

class _BindingsScreenState extends ConsumerState<BindingsScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final bindings = ref.read(bindingsProvider);
    _selectedId = bindings.isEmpty ? null : bindings.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final bindings = ref.watch(bindingsProvider);
    final variables = ref.watch(variablesProvider);
    final selected = _lookup(bindings, _selectedId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 240,
          child: _BindingList(
            bindings: bindings,
            variables: variables,
            selectedId: _selectedId,
            onSelect: (id) => setState(() => _selectedId = id),
            onAdd: () {
              final id = 'bind_${DateTime.now().microsecondsSinceEpoch}';
              final binding = WidgetBinding(
                id: id,
                widgetName: 'New ListView',
                kind: WidgetKind.listView,
                fields: const [
                  BindingField(label: 'Item label', expression: 'item.name'),
                ],
              );
              ref.read(bindingsProvider.notifier).add(binding);
              setState(() => _selectedId = id);
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? Center(
                  child: Text('Select a binding', style: AppTypography.bodyMedium),
                )
              : _BindingEditor(
                  key: ValueKey(selected.binding.id),
                  binding: selected.binding,
                  onChanged: (binding) =>
                      ref.read(bindingsProvider.notifier).updateBinding(binding),
                  onDelete: () {
                    ref
                        .read(bindingsProvider.notifier)
                        .remove(selected.binding.id);
                    final remaining = ref.read(bindingsProvider);
                    setState(() {
                      _selectedId = remaining.isEmpty ? null : remaining.first.id;
                    });
                  },
                ),
        ),
        const VerticalDivider(width: 1),
        const SizedBox(width: 380, child: _PreviewPanel()),
      ],
    );
  }

  ResolvedBinding? _lookup(List<WidgetBinding> bindings, String? id) {
    if (id == null) return null;
    final resolved = ref.watch(resolvedBindingsProvider);
    for (final item in resolved) {
      if (item.binding.id == id) return item;
    }
    return null;
  }
}

class _BindingList extends StatelessWidget {
  const _BindingList({
    required this.bindings,
    required this.variables,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  final List<WidgetBinding> bindings;
  final List<dynamic> variables;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PanelHeader(
            title: 'Bindings',
            subtitle: '${bindings.length} widgets',
            onAdd: onAdd,
            addLabel: 'New',
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            itemCount: bindings.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final binding = bindings[index];
              final selected = binding.id == selectedId;
              return Material(
                color: selected ? AppColors.surfaceHover : AppColors.surface,
                borderRadius: AppRadius.mdAll,
                child: InkWell(
                  onTap: () => onSelect(binding.id),
                  borderRadius: AppRadius.mdAll,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _widgetIcon(binding.kind),
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                binding.widgetName,
                                style: AppTypography.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                binding.sourceVariableId == null
                                    ? 'static'
                                    : '← ${_variableName(variables, binding.sourceVariableId!)}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _variableName(List<dynamic> variables, String id) {
    for (final variable in variables) {
      if (variable.id == id) return variable.name as String;
    }
    return id;
  }
}

IconData _widgetIcon(WidgetKind kind) => switch (kind) {
  WidgetKind.listView => Icons.view_list_outlined,
  WidgetKind.text => Icons.text_fields,
  WidgetKind.image => Icons.image_outlined,
  WidgetKind.form => Icons.description_outlined,
  WidgetKind.button => Icons.smart_button_outlined,
};

class _BindingEditor extends ConsumerStatefulWidget {
  const _BindingEditor({
    super.key,
    required this.binding,
    required this.onChanged,
    required this.onDelete,
  });

  final WidgetBinding binding;
  final ValueChanged<WidgetBinding> onChanged;
  final VoidCallback onDelete;

  @override
  ConsumerState<_BindingEditor> createState() => _BindingEditorState();
}

class _BindingEditorState extends ConsumerState<_BindingEditor> {
  late final TextEditingController _name;
  final Map<int, TextEditingController> _fieldControllers = {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.binding.widgetName);
    for (var i = 0; i < widget.binding.fields.length; i++) {
      _fieldControllers[i] = TextEditingController(
        text: widget.binding.fields[i].expression,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final binding = widget.binding;
    final variables = ref.watch(variablesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: PanelHeader(
                  title: 'Widget binding',
                  subtitle: 'Connect a widget data source to a variable.',
                  icon: _widgetIcon(binding.kind),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppField(
                        label: 'Widget name',
                        child: AppTextField(
                          controller: _name,
                          onChanged: (value) => widget.onChanged(
                            WidgetBinding(
                              id: binding.id,
                              widgetName: value,
                              kind: binding.kind,
                              sourceVariableId: binding.sourceVariableId,
                              itemLabel: binding.itemLabel,
                              fields: binding.fields,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 150,
                      child: AppField(
                        label: 'Widget',
                        child: AppDropdown<WidgetKind>(
                          value: binding.kind,
                          items: [
                            for (final kind in WidgetKind.values)
                              DropdownMenuItem(
                                value: kind,
                                child: Text(kind.label),
                              ),
                          ],
                          onChanged: (kind) {
                            if (kind == null) return;
                            widget.onChanged(
                              WidgetBinding(
                                id: binding.id,
                                widgetName: binding.widgetName,
                                kind: kind,
                                sourceVariableId: binding.sourceVariableId,
                                itemLabel: binding.itemLabel,
                                fields: binding.fields,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppField(
                  label: 'Data source variable',
                  helper: 'The variable this widget reads from.',
                  child: AppDropdown<String>(
                    value: variables.byId(binding.sourceVariableId)?.id,
                    hint: 'None (static)',
                    items: [
                      for (final variable in variables)
                        DropdownMenuItem(
                          value: variable.id,
                          child: Row(
                            children: [
                              Text(variable.name, style: AppTypography.code),
                              const SizedBox(width: AppSpacing.sm),
                              TypeBadge(
                                variable.type,
                                elementType: variable.elementType,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (id) => widget.onChanged(
                      WidgetBinding(
                        id: binding.id,
                        widgetName: binding.widgetName,
                        kind: binding.kind,
                        sourceVariableId: id,
                        itemLabel: binding.itemLabel,
                        fields: binding.fields,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionLabel('Field bindings (${binding.fields.length})'),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < binding.fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppPanel(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: AppField(
                        label: binding.fields[i].label,
                        child: AppTextField(
                          controller: _fieldControllers[i]!,
                          monospace: true,
                          onChanged: (value) => widget.onChanged(
                            WidgetBinding(
                              id: binding.id,
                              widgetName: binding.widgetName,
                              kind: binding.kind,
                              sourceVariableId: binding.sourceVariableId,
                              itemLabel: binding.itemLabel,
                              fields: [
                                for (var j = 0;
                                    j < binding.fields.length;
                                    j++)
                                  if (j == i)
                                    BindingField(
                                      label: binding.fields[j].label,
                                      expression: value,
                                    )
                                  else
                                    binding.fields[j],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => widget.onChanged(
                        WidgetBinding(
                          id: binding.id,
                          widgetName: binding.widgetName,
                          kind: binding.kind,
                          sourceVariableId: binding.sourceVariableId,
                          itemLabel: binding.itemLabel,
                          fields: [
                            for (var j = 0; j < binding.fields.length; j++)
                              if (j != i) binding.fields[j],
                          ],
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 15),
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                final index = binding.fields.length;
                setState(() {
                  _fieldControllers[index] = TextEditingController(
                    text: '${binding.itemLabel}.value',
                  );
                });
                widget.onChanged(
                  WidgetBinding(
                    id: binding.id,
                    widgetName: binding.widgetName,
                    kind: binding.kind,
                    sourceVariableId: binding.sourceVariableId,
                    itemLabel: binding.itemLabel,
                    fields: [
                      ...binding.fields,
                      BindingField(
                        label: 'Field ${index + 1}',
                        expression: '${binding.itemLabel}.value',
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add field binding'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends ConsumerWidget {
  const _PreviewPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(runtimeProvider);
    final flows = ref.watch(actionFlowsProvider);

    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Live preview'),
            const SizedBox(height: AppSpacing.md),
            Center(child: _PhonePreview(runtime: runtime, flows: flows)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(
                  child: Text('Variables', style: AppTypography.titleSmall),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(runtimeProvider.notifier).reset(),
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppPanel(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in runtime.values.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              entry.key,
                              style: AppTypography.code.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatValue(entry.value),
                              style: AppTypography.code.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(
                  child: Text('Run flow', style: AppTypography.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final flow in flows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: OutlinedButton.icon(
                  onPressed: runtime.isRunning
                      ? null
                      : () => ref.read(runtimeProvider.notifier).run(flow),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(flow.name),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Console'),
            const SizedBox(height: AppSpacing.sm),
            AppPanel(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.background,
              child: runtime.log.isEmpty
                  ? Text(
                      'Run a flow to see the action trace.',
                      style: AppTypography.bodySmall,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final entry in runtime.log)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxs,
                            ),
                            child: Text(
                              entry.message,
                              style: AppTypography.code.copyWith(
                                fontSize: 12,
                                color: switch (entry.kind) {
                                  RuntimeLogKind.success => AppColors.success,
                                  RuntimeLogKind.error => AppColors.error,
                                  RuntimeLogKind.info => AppColors.textSecondary,
                                },
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

  String _formatValue(Object? value) {
    if (value == null) return 'null';
    if (value is List) {
      if (value.isEmpty) return '[]';
      final first = value.first;
      if (first is Map) {
        return '[${value.length} × {${first.keys.take(3).join(', ')}}]';
      }
      return '[${value.length} items]';
    }
    if (value is Map) return '{${value.keys.take(4).join(', ')}}';
    return '$value';
  }
}

class _PhonePreview extends ConsumerWidget {
  const _PhonePreview({required this.runtime, required this.flows});

  final RuntimeState runtime;
  final List<ActionFlow> flows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = runtime.values['isLoading'] == true;
    final error = runtime.values['errorMessage'];
    final products = runtime.values['products'];
    final user = runtime.values['currentUser'];

    return Container(
      width: 300,
      height: 430,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('App preview', style: AppTypography.labelSmall),
              const Spacer(),
              Text(
                user is Map ? '${user['name']}' : 'guest',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (error is String && error.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorSubtle,
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      error,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _ProductList(products: products),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: runtime.isRunning
                      ? null
                      : () => ref
                            .read(runtimeProvider.notifier)
                            .run(_flowByName('Load Products')),
                  child: const Text('Load'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: runtime.isRunning
                      ? null
                      : () => ref
                            .read(runtimeProvider.notifier)
                            .run(_flowByName('Login')),
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ActionFlow _flowByName(String name) {
    for (final flow in flows) {
      if (flow.name == name) return flow;
    }
    return flows.isEmpty
        ? const ActionFlow(
            id: 'empty',
            name: 'Empty',
            trigger: FlowTrigger.onTap,
            steps: [],
          )
        : flows.first;
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products});

  final Object? products;

  @override
  Widget build(BuildContext context) {
    final items = products is List ? products! as List : const <Object?>[];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No products', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.xxs),
            Text('products = []', style: AppTypography.code),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        final title = item is Map ? '${item['name'] ?? item.values.first}' : '$item';
        final price = item is Map ? item['price'] : null;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: AppTypography.titleSmall),
              ),
              if (price != null)
                Text(
                  '\$$price',
                  style: AppTypography.code.copyWith(color: AppColors.success),
                ),
            ],
          ),
        );
      },
    );
  }
}
