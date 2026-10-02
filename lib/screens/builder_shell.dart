import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/action_flows_provider.dart';
import '../providers/apis_provider.dart';
import '../providers/bindings_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/runtime_provider.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
import '../utils/project_json.dart';
import '../widgets/common/badges.dart';
import 'actions_screen.dart';
import 'apis_screen.dart';
import 'bindings_screen.dart';
import 'mapping_screen.dart';
import 'variables_screen.dart';

class BuilderShell extends ConsumerWidget {
  const BuilderShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(builderSectionProvider);

    return Scaffold(
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: Row(
              children: [
                const _Sidebar(),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppDurations.normal,
                    child: KeyedSubtree(
                      key: ValueKey(section),
                      child: _sectionFor(section),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionFor(BuilderSection section) => switch (section) {
    BuilderSection.variables => const VariablesScreen(),
    BuilderSection.apis => const ApisScreen(),
    BuilderSection.actions => const ActionsScreen(),
    BuilderSection.mapping => const MappingScreen(),
    BuilderSection.bindings => const BindingsScreen(),
  };
}

IconData sectionIcon(BuilderSection section) => switch (section) {
  BuilderSection.variables => Icons.data_object_outlined,
  BuilderSection.apis => Icons.cloud_outlined,
  BuilderSection.actions => Icons.account_tree_outlined,
  BuilderSection.mapping => Icons.transform,
  BuilderSection.bindings => Icons.widgets_outlined,
};

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(builderSectionProvider);
    final variables = ref.watch(variablesProvider);
    final apis = ref.watch(apisProvider);

    return Container(
      width: 236,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: _Brand(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('BUILDER', style: AppTypography.labelSmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final section in BuilderSection.values)
            _SidebarItem(
              section: section,
              selected: section == selected,
              onTap: () =>
                  ref.read(builderSectionProvider.notifier).select(section),
            ),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROJECT', style: AppTypography.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                _StatRow(label: 'APIs', value: '${apis.length}'),
                _StatRow(label: 'Variables', value: '${variables.length}'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 7,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Draft saved', style: AppTypography.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.mdAll,
          ),
          child: const Icon(Icons.hub_outlined, size: 18, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AppMaker',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge,
              ),
              Text(
                'Visual builder',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final BuilderSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      child: Material(
        color: selected ? AppColors.primarySubtle : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  sectionIcon(section),
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    section.label,
                    style: AppTypography.labelLarge.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(builderSectionProvider);
    final runtime = ref.watch(runtimeProvider);

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(section.label, style: AppTypography.headlineSmall),
                  const SizedBox(width: AppSpacing.sm),
                  TagChip(
                    label: 'DRAFT',
                    color: AppColors.warning,
                    dense: true,
                  ),
                ],
              ),
              Text(section.description, style: AppTypography.bodySmall),
            ],
          ),
          const Spacer(),
          if (runtime.isRunning) ...[
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSpacing.sm),
                Text('Running…'),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          OutlinedButton.icon(
            onPressed: () => _showJson(context, ref),
            icon: const Icon(Icons.code, size: 16),
            label: const Text('View JSON'),
          ),
        ],
      ),
    );
  }

  void _showJson(BuildContext context, WidgetRef ref) {
    final json = buildProjectJson(
      apis: ref.read(apisProvider),
      variables: ref.read(variablesProvider),
      flows: ref.read(actionFlowsProvider),
      bindings: ref.read(bindingsProvider),
    );
    final pretty = const JsonEncoder.withIndent('  ').convert(json);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Project JSON DSL'),
        content: SizedBox(
          width: 620,
          height: 480,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SingleChildScrollView(
              child: SelectableText(pretty, style: AppTypography.code),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
