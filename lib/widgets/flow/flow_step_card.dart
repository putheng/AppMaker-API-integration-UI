import 'package:flutter/material.dart';

import '../../models/action_flow.dart';
import '../../theme/theme.dart';
import '../common/panel.dart';
import 'flow_connector.dart';

IconData stepKindIcon(StepKind kind) => switch (kind) {
  StepKind.callApi => Icons.cloud_download_outlined,
  StepKind.setVariable => Icons.save_outlined,
  StepKind.condition => Icons.call_split,
  StepKind.navigate => Icons.north_east,
  StepKind.showMessage => Icons.chat_bubble_outline,
  StepKind.transform => Icons.auto_fix_high_outlined,
};

Color stepKindColor(StepKind kind) => switch (kind) {
  StepKind.callApi => AppColors.primary,
  StepKind.setVariable => AppColors.info,
  StepKind.condition => AppColors.warning,
  StepKind.navigate => AppColors.success,
  StepKind.showMessage => AppColors.warning,
  StepKind.transform => const Color(0xFFA78BFA),
};

/// Recursive renderer for a single action-flow step.
class FlowStepView extends StatelessWidget {
  const FlowStepView({
    super.key,
    required this.step,
    required this.selectedStepId,
    required this.onSelect,
    required this.onDelete,
    required this.onToggle,
    required this.onAddChild,
    this.depth = 0,
  });

  final FlowStep step;
  final String? selectedStepId;
  final ValueChanged<FlowStep> onSelect;
  final ValueChanged<FlowStep> onDelete;
  final ValueChanged<FlowStep> onToggle;
  final void Function(FlowStep parent, bool onSuccess) onAddChild;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final color = stepKindColor(step.kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepCard(
          step: step,
          color: color,
          selected: selectedStepId == step.id,
          onSelect: () => onSelect(step),
          onDelete: () => onDelete(step),
          onToggle: () => onToggle(step),
        ),
        if (step.kind == StepKind.callApi) ...[
          const SizedBox(height: AppSpacing.sm),
          _BranchSection(
            label: 'On Success',
            color: AppColors.success,
            steps: step.onSuccess,
            selectedStepId: selectedStepId,
            onSelect: onSelect,
            onDelete: onDelete,
            onToggle: onToggle,
            onAddChild: onAddChild,
            onAdd: () => onAddChild(step, true),
            depth: depth + 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BranchSection(
            label: 'On Error',
            color: AppColors.error,
            steps: step.onError,
            selectedStepId: selectedStepId,
            onSelect: onSelect,
            onDelete: onDelete,
            onToggle: onToggle,
            onAddChild: onAddChild,
            onAdd: () => onAddChild(step, false),
            depth: depth + 1,
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.color,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onToggle,
  });

  final FlowStep step;
  final Color color;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppRadius.lgAll,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceHover : AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: step.enabled ? color : AppColors.textDisabled,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    stepKindIcon(step.kind),
                    size: 17,
                    color: step.enabled ? color : AppColors.textDisabled,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      step.label.isEmpty ? step.kind.label : step.label,
                      style: AppTypography.titleSmall.copyWith(
                        color: step.enabled
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.code.copyWith(
                        color: step.enabled
                            ? AppColors.textSecondary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggle,
                tooltip: step.enabled ? 'Disable step' : 'Enable step',
                icon: Icon(
                  step.enabled
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 16,
                ),
                color: AppColors.textTertiary,
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete step',
                icon: const Icon(Icons.delete_outline, size: 16),
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchSection extends StatelessWidget {
  const _BranchSection({
    required this.label,
    required this.color,
    required this.steps,
    required this.selectedStepId,
    required this.onSelect,
    required this.onDelete,
    required this.onToggle,
    required this.onAddChild,
    required this.onAdd,
    required this.depth,
  });

  final String label;
  final Color color;
  final List<FlowStep> steps;
  final String? selectedStepId;
  final ValueChanged<FlowStep> onSelect;
  final ValueChanged<FlowStep> onDelete;
  final ValueChanged<FlowStep> onToggle;
  final void Function(FlowStep parent, bool onSuccess) onAddChild;
  final VoidCallback onAdd;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: color.withValues(alpha: 0.05),
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Add step'),
              ),
            ],
          ),
          if (steps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No steps. Add one to handle this path.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            for (var index = 0; index < steps.length; index++) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: FlowConnector(height: 12, showArrow: true),
                ),
              FlowStepView(
                step: steps[index],
                selectedStepId: selectedStepId,
                onSelect: onSelect,
                onDelete: onDelete,
                onToggle: onToggle,
                onAddChild: onAddChild,
                depth: depth + 1,
              ),
            ],
        ],
      ),
    );
  }
}
