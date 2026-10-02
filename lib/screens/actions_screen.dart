import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/action_flow.dart';
import '../providers/action_flows_provider.dart';
import '../providers/apis_provider.dart';
import '../providers/runtime_provider.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
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

  void _selectFlow(String id) {
    ref.read(selectedFlowProvider.notifier).select(id);
    setState(() => _selectedStepId = null);
  }

  FlowStep _newStep(StepKind kind) {
    final id = 'step_${DateTime.now().microsecondsSinceEpoch}';
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

  ActionFlow? _flow() {
    return ref
        .read(actionFlowsProvider)
        .byId(ref.read(selectedFlowProvider));
  }

  @override
  Widget build(BuildContext context) {
    final flows = ref.watch(actionFlowsProvider);
    final selectedId = ref.watch(selectedFlowProvider);
    final flow = flows.byId(selectedId);

    FlowStep? selectedStep;
    if (flow != null && _selectedStepId != null) {
      for (final step in flow.steps) {
        selectedStep = FlowStepTree.find(step, _selectedStepId!);
        if (selectedStep != null) break;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 236,
          child: _FlowList(
            flows: flows,
            selectedId: selectedId,
            onSelect: _selectFlow,
            onAdd: () {
              final id = 'flow_${DateTime.now().microsecondsSinceEpoch}';
              final newFlow = ActionFlow(
                id: id,
                name: 'New Flow',
                trigger: FlowTrigger.onTap,
                steps: const [],
              );
              ref.read(actionFlowsProvider.notifier).add(newFlow);
              _selectFlow(id);
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
                  onFlowChanged: (updated) => ref
                      .read(actionFlowsProvider.notifier)
                      .updateFlow(updated),
                  onStepChanged: (step) {
                    final updated = [
                      for (final root in flow.steps)
                        FlowStepTree.replace(root, step),
                    ];
                    ref
                        .read(actionFlowsProvider.notifier)
                        .updateFlow(flow.copyWith(steps: updated));
                  },
                  onDeleteStep: _deleteStep,
                  onClearSelection: () =>
                      setState(() => _selectedStepId = null),
                ),
        ),
      ],
    );
  }
}

class _FlowList extends StatelessWidget {
  const _FlowList({
    required this.flows,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  final List<ActionFlow> flows;
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
              final selected = flow.id == selectedId;
              return Material(
                color: selected ? AppColors.surfaceHover : AppColors.surface,
                borderRadius: AppRadius.mdAll,
                child: InkWell(
                  onTap: () => onSelect(flow.id),
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
            },
          ),
        ),
      ],
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
    required this.onRun,
  });

  final ActionFlow flow;
  final String? selectedStepId;
  final ValueChanged<FlowStep> onSelectStep;
  final ValueChanged<FlowStep> onDeleteStep;
  final ValueChanged<FlowStep> onToggleStep;
  final void Function(FlowStep parent, bool onSuccess, StepKind kind) onAddChild;
  final ValueChanged<StepKind> onAddTopLevel;
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
                  for (var index = 0; index < flow.steps.length; index++) ...[
                    if (index > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: FlowConnector(height: 16, showArrow: true),
                      ),
                    FlowStepView(
                      step: flow.steps[index],
                      selectedStepId: selectedStepId,
                      onSelect: onSelectStep,
                      onDelete: onDeleteStep,
                      onToggle: onToggleStep,
                      onAddChild: (parent, onSuccess) => _pickKind(
                        context,
                        (kind) => onAddChild(parent, onSuccess, kind),
                      ),
                    ),
                  ],
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
    required this.onFlowChanged,
    required this.onStepChanged,
    required this.onDeleteStep,
    required this.onClearSelection,
  });

  final ActionFlow flow;
  final FlowStep? selectedStep;
  final ValueChanged<ActionFlow> onFlowChanged;
  final ValueChanged<FlowStep> onStepChanged;
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
            _FlowSettings(
              key: ValueKey(flow.id),
              flow: flow,
              onChanged: onFlowChanged,
            ),
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
                onChanged: onStepChanged,
                onDelete: () => onDeleteStep(selectedStep!),
                onClose: onClearSelection,
              ),
          ],
        ),
      ),
    );
  }
}

class _FlowSettings extends StatefulWidget {
  const _FlowSettings({super.key, required this.flow, required this.onChanged});

  final ActionFlow flow;
  final ValueChanged<ActionFlow> onChanged;

  @override
  State<_FlowSettings> createState() => _FlowSettingsState();
}

class _FlowSettingsState extends State<_FlowSettings> {
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
                widget.onChanged(widget.flow.copyWith(name: value)),
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
              widget.onChanged(
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
    required this.onChanged,
    required this.onDelete,
    required this.onClose,
  });

  final FlowStep step;
  final ValueChanged<FlowStep> onChanged;
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
                  widget.onChanged(step.copyWith(apiId: api.id, label: api.name));
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
                  widget.onChanged(step.copyWith(variableId: id));
                },
              ),
            ),
          if (step.kind == StepKind.navigate)
            AppField(
              label: 'Target page',
              child: AppTextField(
                controller: _target,
                hintText: 'Home',
                onChanged: (value) => widget.onChanged(step.copyWith(target: value)),
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
              helper: 'Use response.* to read the API result.',
              child: AppTextField(
                controller: _expression,
                monospace: true,
                hintText: 'response.data',
                onChanged: (value) =>
                    widget.onChanged(step.copyWith(expression: value)),
              ),
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
                    widget.onChanged(step.copyWith(enabled: value)),
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
