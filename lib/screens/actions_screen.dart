import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/action_flow.dart';
import '../models/app_variable.dart';
import '../models/response_field.dart';
import '../providers/action_flows_provider.dart';
import '../providers/apis_provider.dart';
import '../providers/runtime_provider.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
import '../utils/id.dart';
import '../widgets/common/badges.dart';
import '../widgets/common/fields.dart';
import '../widgets/common/panel.dart';
import '../widgets/flow/flow_connector.dart';
import '../widgets/flow/flow_step_card.dart';

class ActionsScreen extends ConsumerStatefulWidget {
  const ActionsScreen({super.key});

  @override
  ConsumerState<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends ConsumerState<ActionsScreen> {
  String? _selectedStepId;

  FlowStep _newStep(StepKind kind) {
    final id = newId('step');
    final apis = ref.read(apisProvider);
    final variables = ref.read(variablesProvider);

    return switch (kind) {
      StepKind.callApi => FlowStep(
        id: id,
        kind: kind,
        label: apis.isEmpty ? 'Select API' : apis.first.name,
        apiId: apis.isEmpty ? null : apis.first.id,
      ),
      StepKind.setVariable => FlowStep(
        id: id,
        kind: kind,
        variableId: variables.isEmpty ? null : variables.first.id,
        expression: 'response.data',
      ),
      StepKind.navigate => FlowStep(id: id, kind: kind, target: 'Home'),
      StepKind.showMessage => FlowStep(
        id: id,
        kind: kind,
        expression: 'errorMessage',
      ),
      StepKind.condition => FlowStep(
        id: id,
        kind: kind,
        expression: 'isLoading == false',
      ),
      StepKind.transform => FlowStep(
        id: id,
        kind: kind,
        expression: 'filter(price > 100)',
      ),
    };
  }

  void _addTopLevel(StepKind kind) {
    final flow = _flow();
    if (flow == null) return;
    final step = _newStep(kind);
    ref
        .read(actionFlowsProvider.notifier)
        .updateFlow(flow.copyWith(steps: [...flow.steps, step]));
    setState(() => _selectedStepId = step.id);
  }

  void _addChild(FlowStep parent, bool onSuccess, StepKind kind) {
    final flow = _flow();
    if (flow == null) return;
    final child = _newStep(kind);
    final updated = [
      for (final step in flow.steps)
        FlowStepTree.addChild(step, parent.id, child, onSuccess: onSuccess),
    ];
    ref
        .read(actionFlowsProvider.notifier)
        .updateFlow(flow.copyWith(steps: updated));
    setState(() => _selectedStepId = child.id);
  }

  void _deleteStep(FlowStep step) {
    final flow = _flow();
    if (flow == null) return;
    final updated = [
      for (final root in flow.steps)
        if (root.id != step.id) FlowStepTree.remove(root, step.id),
    ];
    ref
        .read(actionFlowsProvider.notifier)
        .updateFlow(flow.copyWith(steps: updated));
    setState(() => _selectedStepId = null);
  }

  void _toggleStep(FlowStep step) {
    final flow = _flow();
    if (flow == null) return;
    final toggled = step.copyWith(enabled: !step.enabled);
    final updated = [
      for (final root in flow.steps) FlowStepTree.replace(root, toggled),
    ];
    ref
        .read(actionFlowsProvider.notifier)
        .updateFlow(flow.copyWith(steps: updated));
  }

  void _reorderTopLevel(int oldIndex, int newIndex) {
    final flow = _flow();
    if (flow == null) return;
    final steps = [...flow.steps];
    final step = steps.removeAt(oldIndex);
    steps.insert(newIndex, step);
    ref
        .read(actionFlowsProvider.notifier)
        .updateFlow(flow.copyWith(steps: steps));
  }

  void _reorderBranch(
    FlowStep parent,
    bool onSuccess,
    int oldIndex,
    int newIndex,
  ) {
    final flow = _flow();
    if (flow == null) return;
    final updated = [
      for (final root in flow.steps)
        FlowStepTree.reorderBranch(
          root,
          parent.id,
          onSuccess,
          oldIndex,
          newIndex,
        ),
    ];
    ref
        .read(actionFlowsProvider.notifier)
        .updateFlow(flow.copyWith(steps: updated));
  }

  ActionFlow? _flow() {
    return ref
        .read(actionFlowsProvider)
        .byId(ref.read(selectedFlowProvider));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedFlowProvider, (previous, next) {
      if (previous != next && mounted) {
        setState(() => _selectedStepId = null);
      }
    });

    final flows = ref.watch(actionFlowsProvider);
    final selectedId = ref.watch(selectedFlowProvider);
    final flow = flows.byId(selectedId);

    FlowStep? selectedStep;
    String? responseApiId;
    if (flow != null && _selectedStepId != null) {
      for (final step in flow.steps) {
        selectedStep = FlowStepTree.find(step, _selectedStepId!);
        responseApiId = FlowStepTree.responseApiFor(step, _selectedStepId!);
        if (selectedStep != null) break;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 236,
          child: _FlowList(
            onAdd: () {
              final id = newId('flow');
              final newFlow = ActionFlow(
                id: id,
                name: 'New Flow',
                trigger: FlowTrigger.onTap,
                steps: const [],
              );
              ref.read(actionFlowsProvider.notifier).add(newFlow);
              ref.read(selectedFlowProvider.notifier).select(id);
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: flow == null
              ? const SizedBox.shrink()
              : _FlowCanvas(
                  flow: flow,
                  selectedStepId: _selectedStepId,
                  onSelectStep: (step) =>
                      setState(() => _selectedStepId = step.id),
                  onDeleteStep: _deleteStep,
                  onToggleStep: _toggleStep,
                  onAddChild: _addChild,
                  onAddTopLevel: _addTopLevel,
                  onReorderTopLevel: _reorderTopLevel,
                  onReorderBranch: _reorderBranch,
                  onRun: () => ref.read(runtimeProvider.notifier).run(flow),
                ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 340,
          child: flow == null
              ? const SizedBox.shrink()
              : _Inspector(
                  flow: flow,
                  selectedStep: selectedStep,
                  responseApiId: responseApiId,
                  onDeleteStep: _deleteStep,
                  onClearSelection: () =>
                      setState(() => _selectedStepId = null),
                ),
        ),
      ],
    );
  }
}

class _FlowList extends ConsumerWidget {
  const _FlowList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flows = ref.watch(actionFlowsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PanelHeader(
            title: 'Action flows',
            subtitle: '${flows.length} flows',
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
            itemCount: flows.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final flow = flows[index];
              return ProviderScope(
                key: ValueKey(flow.id),
                overrides: [currentFlowProvider.overrideWithValue(flow)],
                child: const FlowTile(),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single action-flow row. Reads its flow from the overridden
/// [currentFlowProvider] and its selection from [selectedFlowProvider].
class FlowTile extends ConsumerWidget {
  const FlowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(currentFlowProvider);
    final selected = ref.watch(
      selectedFlowProvider.select((id) => id == flow.id),
    );

    return Material(
      color: selected ? AppColors.surfaceHover : AppColors.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: () => ref.read(selectedFlowProvider.notifier).select(flow.id),
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(flow.name, style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  TagChip(
                    label: flow.trigger.label,
                    color: AppColors.primary,
                    dense: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${flow.steps.length} steps',
                    style: AppTypography.bodySmall,
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

class _FlowCanvas extends StatelessWidget {
  const _FlowCanvas({
    required this.flow,
    required this.selectedStepId,
    required this.onSelectStep,
    required this.onDeleteStep,
    required this.onToggleStep,
    required this.onAddChild,
    required this.onAddTopLevel,
    required this.onReorderTopLevel,
    required this.onReorderBranch,
    required this.onRun,
  });

  final ActionFlow flow;
  final String? selectedStepId;
  final ValueChanged<FlowStep> onSelectStep;
  final ValueChanged<FlowStep> onDeleteStep;
  final ValueChanged<FlowStep> onToggleStep;
  final void Function(FlowStep parent, bool onSuccess, StepKind kind) onAddChild;
  final ValueChanged<StepKind> onAddTopLevel;
  final void Function(int oldIndex, int newIndex) onReorderTopLevel;
  final BranchReorderCallback onReorderBranch;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flow.name, style: AppTypography.titleLarge),
                    if (flow.description.isNotEmpty)
                      Text(flow.description, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onRun,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Run flow'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TriggerCard(trigger: flow.trigger),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: FlowConnector(height: 16, showArrow: true),
                ),
                if (flow.steps.isEmpty)
                  AppPanel(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Text(
                          'No steps yet',
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Add the first step to start reacting to this trigger.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    itemCount: flow.steps.length,
                    onReorderItem: onReorderTopLevel,
                    itemBuilder: (context, index) {
                      final step = flow.steps[index];
                      return Column(
                        key: ValueKey(step.id),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (index > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: FlowConnector(
                                height: 16,
                                showArrow: true,
                              ),
                            ),
                          FlowStepView(
                            step: step,
                            selectedStepId: selectedStepId,
                            onSelect: onSelectStep,
                            onDelete: onDeleteStep,
                            onToggle: onToggleStep,
                            onAddChild: (parent, onSuccess) => _pickKind(
                              context,
                              (kind) => onAddChild(parent, onSuccess, kind),
                            ),
                            onReorderBranch: onReorderBranch,
                            dragHandle: ReorderableDragStartListener(
                              index: index,
                              child: const FlowDragHandle(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickKind(context, onAddTopLevel),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add step'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _pickKind(BuildContext context, ValueChanged<StepKind> onPicked) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a step', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final kind in StepKind.values)
                ListTile(
                  onTap: () {
                    Navigator.of(context).pop();
                    onPicked(kind);
                  },
                  leading: Icon(stepKindIcon(kind), color: stepKindColor(kind)),
                  title: Text(kind.label),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({required this.trigger});

  final FlowTrigger trigger;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      color: AppColors.primarySubtle,
      borderColor: AppColors.primary.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(Icons.bolt, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trigger', style: AppTypography.labelSmall),
              Text(trigger.label, style: AppTypography.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({
    required this.flow,
    required this.selectedStep,
    required this.responseApiId,
    required this.onDeleteStep,
    required this.onClearSelection,
  });

  final ActionFlow flow;
  final FlowStep? selectedStep;
  final String? responseApiId;
  final ValueChanged<FlowStep> onDeleteStep;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FlowSettings(key: ValueKey(flow.id), flow: flow),
            const SizedBox(height: AppSpacing.xl),
            if (selectedStep == null)
              AppPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Select a step', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Click any step on the canvas to edit its properties.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              )
            else
              _StepEditor(
                key: ValueKey(selectedStep!.id),
                step: selectedStep!,
                responseApiId: responseApiId,
                onDelete: () => onDeleteStep(selectedStep!),
                onClose: onClearSelection,
              ),
          ],
        ),
      ),
    );
  }
}

class _FlowSettings extends ConsumerStatefulWidget {
  const _FlowSettings({super.key, required this.flow});

  final ActionFlow flow;

  @override
  ConsumerState<_FlowSettings> createState() => _FlowSettingsState();
}

class _FlowSettingsState extends ConsumerState<_FlowSettings> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.flow.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _push(ActionFlow flow) =>
      ref.read(actionFlowsProvider.notifier).updateFlow(flow);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Flow settings'),
        const SizedBox(height: AppSpacing.md),
        AppField(
          label: 'Name',
          child: AppTextField(
            controller: _name,
            onChanged: (value) =>
                _push(widget.flow.copyWith(name: value)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppField(
          label: 'Trigger',
          child: AppDropdown<FlowTrigger>(
            value: widget.flow.trigger,
            items: [
              for (final trigger in FlowTrigger.values)
                DropdownMenuItem(value: trigger, child: Text(trigger.label)),
            ],
            onChanged: (trigger) {
              if (trigger == null) return;
              _push(
                ActionFlow(
                  id: widget.flow.id,
                  name: widget.flow.name,
                  trigger: trigger,
                  steps: widget.flow.steps,
                  description: widget.flow.description,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StepEditor extends ConsumerStatefulWidget {
  const _StepEditor({
    super.key,
    required this.step,
    required this.responseApiId,
    required this.onDelete,
    required this.onClose,
  });

  final FlowStep step;
  final String? responseApiId;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  ConsumerState<_StepEditor> createState() => _StepEditorState();
}

class _StepEditorState extends ConsumerState<_StepEditor> {
  late final TextEditingController _expression;
  late final TextEditingController _target;
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    _expression = TextEditingController(text: widget.step.expression);
    _target = TextEditingController(text: widget.step.target);
    _label = TextEditingController(text: widget.step.label);
  }

  /// Persists an edited step straight to the provider, replacing it in the
  /// currently selected flow.
  void _updateStep(FlowStep updated) {
    final flows = ref.read(actionFlowsProvider);
    final flow = flows.byId(ref.read(selectedFlowProvider));
    if (flow == null) return;
    final steps = [
      for (final root in flow.steps) FlowStepTree.replace(root, updated),
    ];
    ref
        .read(actionFlowsProvider.notifier)
        .updateFlow(flow.copyWith(steps: steps));
  }

  @override
  void dispose() {
    _expression.dispose();
    _target.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final variables = ref.watch(variablesProvider);
    final apis = ref.watch(apisProvider);

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: stepKindColor(step.kind).withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(stepKindIcon(step.kind), size: 18, color: stepKindColor(step.kind)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(step.kind.label, style: AppTypography.titleMedium),
              ),
              IconButton(
                onPressed: widget.onClose,
                tooltip: 'Close',
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (step.kind == StepKind.callApi)
            AppField(
              label: 'API',
              child: AppDropdown<String>(
                value: apis.byId(step.apiId)?.id,
                hint: 'Select API',
                items: [
                  for (final api in apis)
                    DropdownMenuItem(value: api.id, child: Text(api.name)),
                ],
                onChanged: (id) {
                  final api = apis.byId(id);
                  if (api == null) return;
                  _updateStep(step.copyWith(apiId: api.id, label: api.name));
                },
              ),
            ),
          if (step.kind == StepKind.setVariable)
            AppField(
              label: 'Variable',
              child: AppDropdown<String>(
                value: variables.byId(step.variableId)?.id,
                hint: 'Select variable',
                items: [
                  for (final variable in variables)
                    DropdownMenuItem(
                      value: variable.id,
                      child: Text(
                        variable.name,
                        style: AppTypography.code,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  _updateStep(step.copyWith(variableId: id));
                },
              ),
            ),
          if (step.kind == StepKind.navigate)
            AppField(
              label: 'Target page',
              child: AppTextField(
                controller: _target,
                hintText: 'Home',
                onChanged: (value) => _updateStep(step.copyWith(target: value)),
              ),
            ),
          if (step.kind == StepKind.setVariable ||
              step.kind == StepKind.showMessage ||
              step.kind == StepKind.condition ||
              step.kind == StepKind.transform) ...[
            if (step.kind == StepKind.setVariable)
              const SizedBox(height: AppSpacing.md),
            AppField(
              label: step.kind == StepKind.setVariable ? 'Value' : 'Expression',
              helper: 'Type a value or pick one below.',
              child: AppTextField(
                controller: _expression,
                monospace: true,
                hintText: 'response.data',
                onChanged: (value) =>
                    _updateStep(step.copyWith(expression: value)),
              ),
            ),
            _ValuePicker(
              step: step,
              responseApiId: widget.responseApiId,
              onInsert: (value) {
                _expression.text = value;
                _expression.selection = TextSelection.collapsed(
                  offset: value.length,
                );
                _updateStep(step.copyWith(expression: value));
              },
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  step.enabled ? 'Step enabled' : 'Step disabled',
                  style: AppTypography.bodySmall,
                ),
              ),
              Switch(
                value: step.enabled,
                onChanged: (value) =>
                    _updateStep(step.copyWith(enabled: value)),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          TextButton.icon(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete step'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _Token {
  const _Token(this.text, this.color);

  final String text;
  final Color color;
}

/// Suggests the values available to a step, grouped by where they come from
/// and filtered by the type the step expects.
class _ValuePicker extends ConsumerWidget {
  const _ValuePicker({
    required this.step,
    required this.responseApiId,
    required this.onInsert,
  });

  final FlowStep step;
  final String? responseApiId;
  final ValueChanged<String> onInsert;

  /// The type the step's value should have, or null when anything goes.
  VariableType? _expectedType(List<AppVariable> variables) {
    return switch (step.kind) {
      StepKind.setVariable => variables.byId(step.variableId)?.type,
      StepKind.condition => VariableType.boolean,
      StepKind.showMessage => VariableType.string,
      _ => null,
    };
  }

  bool _matchesField(FieldKind kind, VariableType? expected) {
    if (expected == null || expected == VariableType.json) return true;
    return switch (expected) {
      VariableType.string => kind == FieldKind.string,
      VariableType.number => kind == FieldKind.number,
      VariableType.boolean => kind == FieldKind.boolean,
      VariableType.list => kind == FieldKind.list,
      VariableType.map || VariableType.object => kind == FieldKind.object,
      VariableType.json => true,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variables = ref.watch(variablesProvider);
    final api = ref.watch(apisProvider).byId(responseApiId);
    final schema = api?.buildSchema();
    final expected = _expectedType(variables);

    final responseFields = schema == null
        ? const <ResponseField>[]
        : [
            for (final field in schema.flatten())
              if (field.path != 'response' && _matchesField(field.kind, expected))
                field,
          ];

    final matchingVariables = [
      for (final variable in variables)
        if (expected == null ||
            expected == VariableType.json ||
            variable.type == expected)
          variable,
    ];

    final literals = switch (expected) {
      VariableType.boolean => const [
        _Token('true', AppColors.success),
        _Token('false', AppColors.error),
      ],
      null || VariableType.json => const [
        _Token('true', AppColors.success),
        _Token('false', AppColors.error),
        _Token('null', AppColors.textTertiary),
      ],
      _ => const <_Token>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (responseFields.isNotEmpty)
          _TokenGroup(
            label: 'Response · dynamic${api == null ? '' : ' · ${api.name}'}',
            tokens: [
              for (final field in responseFields)
                _Token(field.path, fieldKindColor(field.kind)),
            ],
            onInsert: onInsert,
          )
        else if (api == null)
          const _PickerHint(
            'Pick a Call API step in the On Success branch to see its response fields.',
          )
        else
          _PickerHint(
            'No ${expected == null ? '' : '${variableTypeLabel(expected)} '}response fields on ${api.name}.',
          ),
        if (matchingVariables.isNotEmpty)
          _TokenGroup(
            label: 'Variables · dynamic${expected == null ? '' : ' · ${variableTypeLabel(expected)}'}',
            tokens: [
              for (final variable in matchingVariables)
                _Token(
                  variable.name,
                  variableDisplayColor(variable.type, variable.elementType),
                ),
            ],
            onInsert: onInsert,
          ),
        if (literals.isNotEmpty)
          _TokenGroup(
            label: 'Literals · fixed',
            tokens: literals,
            onInsert: onInsert,
          ),
      ],
    );
  }
}

class _TokenGroup extends StatelessWidget {
  const _TokenGroup({
    required this.label,
    required this.tokens,
    this.onInsert,
  });

  final String label;
  final List<_Token> tokens;
  final ValueChanged<String>? onInsert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final token in tokens)
                _TokenChip(
                  token: token,
                  onTap: onInsert == null ? null : () => onInsert!(token.text),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerHint extends StatelessWidget {
  const _PickerHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.token, this.onTap});

  final _Token token;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: token.color.withValues(alpha: 0.12),
          borderRadius: AppRadius.smAll,
          border: Border.all(color: token.color.withValues(alpha: 0.35)),
        ),
        child: Text(
          token.text,
          style: AppTypography.code.copyWith(fontSize: 11, color: token.color),
        ),
      ),
    );
  }
}
