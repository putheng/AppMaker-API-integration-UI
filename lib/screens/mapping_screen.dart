import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_definition.dart';
import '../models/app_variable.dart';
import '../models/response_field.dart';
import '../providers/api_test_provider.dart';
import '../providers/apis_provider.dart';
import '../providers/mapping_provider.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
import '../utils/id.dart';
import '../widgets/common/badges.dart';
import '../widgets/common/fields.dart';
import '../widgets/common/panel.dart';
import '../widgets/response/response_tree.dart';

class MappingScreen extends ConsumerStatefulWidget {
  const MappingScreen({super.key});

  @override
  ConsumerState<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends ConsumerState<MappingScreen> {
  final TextEditingController _transform = TextEditingController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(mappingDraftProvider);
      if (draft.apiId == null) {
        final selectedId = ref.read(selectedApiProvider);
        final apis = ref.read(apisProvider);
        final api = apis.byId(selectedId) ?? (apis.isEmpty ? null : apis.first);
        if (api != null) {
          final schema = api.buildSchema();
          ref
              .read(mappingDraftProvider.notifier)
              .startFor(api.id, defaultSource: _defaultPath(schema));
        }
      }
    });
  }

  String? _defaultPath(ResponseField? schema) {
    if (schema == null) return null;
    for (final field in schema.flatten()) {
      if (field.kind == FieldKind.list) return field.path;
    }
    return schema.path;
  }

  /// Loads the live sample response for [api] and refreshes the mapper tree.
  Future<void> _run(ApiDefinition api) async {
    await ref.read(apiTestProvider.notifier).run(api);
    final state = ref.read(apiTestProvider)[api.id];
    if (state?.response == null) return;

    final schema = ResponseField.fromValue('response', state!.response);
    final draft = ref.read(mappingDraftProvider);
    final sourceValid =
        draft.sourcePath != null &&
        schema.flatten().any((field) => field.path == draft.sourcePath);

    if (draft.apiId == api.id && !sourceValid) {
      final path = _defaultPath(schema);
      if (path != null) {
        ref.read(mappingDraftProvider.notifier).selectSource(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apis = ref.watch(apisProvider);
    final variables = ref.watch(variablesProvider);
    final draft = ref.watch(mappingDraftProvider);
    final mappings = ref.watch(mappingsProvider);
    final test = ref.watch(apiTestProvider)[draft.apiId];

    final api = apis.byId(draft.apiId);
    final schema = test?.response != null
        ? ResponseField.fromValue('response', test!.response)
        : api?.buildSchema();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
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
                    const Expanded(
                      child: PanelHeader(
                        title: 'Response mapper',
                        subtitle: 'Pick a response field to bind it to a variable.',
                        icon: Icons.transform,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppDropdown<String>(
                        value: api?.id,
                        hint: 'Select API',
                        items: [
                          for (final a in apis)
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                        ],
                        onChanged: (id) {
                          final selected = apis.byId(id);
                          if (selected == null) return;
                          _transform.clear();
                          ref
                              .read(mappingDraftProvider.notifier)
                              .startFor(
                                selected.id,
                                defaultSource: _defaultPath(
                                  selected.buildSchema(),
                                ),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      key: const ValueKey('mappingRunButton'),
                      height: AppSpacing.control,
                      child: FilledButton.icon(
                        onPressed: api == null || (test?.isLoading ?? false)
                            ? null
                            : () => _run(api),
                        icon: (test?.isLoading ?? false)
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow, size: 16),
                        label: Text(
                          (test?.isLoading ?? false) ? 'Loading' : 'Run',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (test != null && !test.isLoading) ...[
                        _LoadStatus(test: test),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Expanded(
                        child: schema == null
                            ? Center(
                                child: Text(
                                  'This API has no sample response to map. Run the API first.',
                                  style: AppTypography.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : AppPanel(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: SingleChildScrollView(
                                  child: ResponseTreeView(
                                    root: schema,
                                    selectedPath: draft.sourcePath,
                                    onSelect: (field) => ref
                                        .read(mappingDraftProvider.notifier)
                                        .selectSource(field.path),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 400,
          child: Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('Store in variable'),
                  const SizedBox(height: AppSpacing.md),
                  AppPanel(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppField(
                          label: 'Variable',
                          child: AppDropdown<String>(
                            value: variables.byId(draft.variableId)?.id,
                            hint: 'Select variable',
                            items: [
                              for (final variable in variables)
                                DropdownMenuItem(
                                  value: variable.id,
                                  child: Row(
                                    children: [
                                      Text(
                                        variable.name,
                                        style: AppTypography.code,
                                      ),
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
                            onChanged: (id) {
                              if (id == null) return;
                              ref
                                  .read(mappingDraftProvider.notifier)
                                  .selectVariable(id);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppField(
                          label: 'Value',
                          helper: 'Derived from the selected response field.',
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
                                  Icons.subdirectory_arrow_right,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    draft.sourcePath ?? 'response.field',
                                    style: AppTypography.code.copyWith(
                                      color: draft.sourcePath == null
                                          ? AppColors.textTertiary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Advanced transform',
                                style: AppTypography.labelMedium,
                              ),
                            ),
                            Switch(
                              value: draft.advanced,
                              onChanged: (value) => ref
                                  .read(mappingDraftProvider.notifier)
                                  .setAdvanced(value),
                            ),
                          ],
                        ),
                        if (draft.advanced) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              for (final op in const ['Filter', 'Map', 'Sort'])
                                ActionChip(
                                  label: Text(op),
                                  onPressed: () {
                                    final next = draft.transform.isEmpty
                                        ? '$op()'
                                        : '${draft.transform} → $op()';
                                    _transform.text = next;
                                    ref
                                        .read(mappingDraftProvider.notifier)
                                        .setTransform(next);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            controller: _transform,
                            monospace: true,
                            hintText: 'filter(price > 100) → sort(price DESC)',
                            onChanged: (value) => ref
                                .read(mappingDraftProvider.notifier)
                                .setTransform(value),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: () => _save(draft, apis, variables),
                          child: const Text('Save mapping'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionLabel('Saved mappings (${mappings.length})'),
                  const SizedBox(height: AppSpacing.md),
                  if (mappings.isEmpty)
                    Text(
                      'No mappings yet. Map a response field to a variable to create one.',
                      style: AppTypography.bodySmall,
                    )
                  else
                    for (final mapping in mappings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppPanel(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variables.byId(mapping.variableId)?.name ??
                                          'variable',
                                      style: AppTypography.code.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${mapping.apiName}  ·  ${mapping.expression}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => ref
                                    .read(mappingsProvider.notifier)
                                    .remove(mapping.id),
                                icon: const Icon(Icons.close, size: 15),
                                color: AppColors.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _save(
    MappingDraft draft,
    List<ApiDefinition> apis,
    List<AppVariable> variables,
  ) {
    final api = apis.byId(draft.apiId);
    final variable = variables.byId(draft.variableId);

    if (api == null || variable == null || draft.sourcePath == null) {
      _snack('Select an API, a field and a variable first.', isError: true);
      return;
    }

    ref.read(mappingsProvider.notifier).add(
          ResponseMapping(
            id: newId('map'),
            apiId: api.id,
            apiName: api.name,
            variableId: variable.id,
            expression: draft.sourcePath!,
            transform: draft.transform,
          ),
        );
    _snack('${variable.name} = ${draft.sourcePath}');
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.surfaceElevated,
      ),
    );
  }
}

class _LoadStatus extends StatelessWidget {
  const _LoadStatus({required this.test});

  final ApiTestState test;

  @override
  Widget build(BuildContext context) {
    final success = test.isSuccess;
    final color = success ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            success
                ? 'Sample response loaded · ${test.statusCode} OK'
                : 'Failed to load sample response',
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
          const Spacer(),
          if (test.latencyMs != null)
            Text('${test.latencyMs} ms', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
