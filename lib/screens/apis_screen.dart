import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_definition.dart';
import '../models/response_field.dart';
import '../providers/api_test_provider.dart';
import '../providers/apis_provider.dart';
import '../providers/mapping_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/variables_provider.dart';
import '../theme/theme.dart';
import '../utils/id.dart';
import '../widgets/common/badges.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/fields.dart';
import '../widgets/common/key_value_editor.dart';
import '../widgets/common/panel.dart';
import '../widgets/response/response_tree.dart';
import '../models/app_variable.dart';

KeyValuePair _newPair() => KeyValuePair(id: newId('kv'));

class ApisScreen extends ConsumerWidget {
  const ApisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref
        .watch(apisProvider)
        .byId(ref.watch(selectedApiProvider));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(width: 264, child: _ApiList()),
        const VerticalDivider(width: 1),
        if (selected == null)
          const Expanded(
            child: EmptyState(
              icon: Icons.cloud_outlined,
              title: 'No API selected',
              message: 'Select an API definition or create a new one.',
            ),
          )
        else ...[
          Expanded(
            flex: 5,
            child: _ApiEditor(key: ValueKey(selected.id), api: selected),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 400,
            child: _ResponsePanel(
              key: ValueKey('response_${selected.id}'),
              api: selected,
            ),
          ),
        ],
      ],
    );
  }
}

class _ApiList extends ConsumerWidget {
  const _ApiList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apis = ref.watch(apisProvider);
    final selectedId = ref.watch(selectedApiProvider);

    void addApi() {
      final api = ApiDefinition(
        id: newId('api'),
        name: 'New API',
        method: HttpMethod.get,
        url: 'https://api.example.com/resource',
      );
      ref.read(apisProvider.notifier).add(api);
      ref.read(selectedApiProvider.notifier).select(api.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PanelHeader(
            title: 'API definitions',
            subtitle: '${apis.length} endpoints',
            onAdd: addApi,
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
            itemCount: apis.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final api = apis[index];
              final selected = api.id == selectedId;
              return Material(
                color: selected ? AppColors.surfaceHover : AppColors.surface,
                borderRadius: AppRadius.mdAll,
                child: InkWell(
                  onTap: () =>
                      ref.read(selectedApiProvider.notifier).select(api.id),
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
                        Row(
                          children: [
                            MethodChip(api.method, dense: true),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                api.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          api.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.code.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
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
}

class _ApiEditor extends ConsumerStatefulWidget {
  const _ApiEditor({super.key, required this.api});

  final ApiDefinition api;

  @override
  ConsumerState<_ApiEditor> createState() => _ApiEditorState();
}

class _ApiEditorState extends ConsumerState<_ApiEditor> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.api.name);
    _url = TextEditingController(text: widget.api.url);
    _body = TextEditingController(text: widget.api.body);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _body.dispose();
    super.dispose();
  }

  ApiDefinition get _api => widget.api;

  void _push(ApiDefinition api) =>
      ref.read(apisProvider.notifier).updateApi(api);

  void _delete() {
    ref.read(apisProvider.notifier).remove(widget.api.id);
    final remaining = ref.read(apisProvider);
    ref
        .read(selectedApiProvider.notifier)
        .select(remaining.isEmpty ? null : remaining.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final api = _api;
    final showBody = api.method != HttpMethod.get;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'API name',
                  child: AppTextField(
                    controller: _name,
                    onChanged: (value) => _push(api.copyWith(name: value)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: _delete,
                tooltip: 'Delete API',
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 130,
                child: AppField(
                  label: 'Method',
                  child: AppDropdown<HttpMethod>(
                    value: api.method,
                    items: [
                      for (final method in HttpMethod.values)
                        DropdownMenuItem(
                          value: method,
                          child: MethodChip(method, dense: true),
                        ),
                    ],
                    onChanged: (method) {
                      if (method != null) _push(api.copyWith(method: method));
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppField(
                  label: 'URL',
                  child: AppTextField(
                    controller: _url,
                    monospace: true,
                    hintText: 'https://api.example.com/resource',
                    onChanged: (value) => _push(api.copyWith(url: value)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionLabel('Headers'),
          const SizedBox(height: AppSpacing.sm),
          KeyValueEditor(
            pairs: api.headers,
            keyHint: 'Authorization',
            valueHint: 'Bearer {{authToken}}',
            onChanged: (pairs) => _push(api.copyWith(headers: pairs)),
            onAdd: () => _push(api.copyWith(headers: [...api.headers, _newPair()])),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Query parameters'),
          const SizedBox(height: AppSpacing.sm),
          KeyValueEditor(
            pairs: api.query,
            keyHint: 'category',
            valueHint: '{{selectedCategory}}',
            onChanged: (pairs) => _push(api.copyWith(query: pairs)),
            onAdd: () => _push(api.copyWith(query: [...api.query, _newPair()])),
          ),
          if (showBody) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Body'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _body,
              maxLines: 8,
              minLines: 6,
              monospace: true,
              hintText: '{\n  "key": "{{value}}"\n}',
              onChanged: (value) => _push(api.copyWith(body: value)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResponsePanel extends ConsumerStatefulWidget {
  const _ResponsePanel({super.key, required this.api});

  final ApiDefinition api;

  @override
  ConsumerState<_ResponsePanel> createState() => _ResponsePanelState();
}

class _ResponsePanelState extends ConsumerState<_ResponsePanel> {
  late final TextEditingController _sample;

  @override
  void initState() {
    super.initState();
    _sample = TextEditingController(text: widget.api.responseJson);
  }

  @override
  void dispose() {
    _sample.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    final test = ref.watch(apiTestProvider)[api.id];
    final schema = api.buildSchema();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Response', style: AppTypography.titleMedium),
              ),
              FilledButton.icon(
                onPressed: test?.isLoading ?? false
                    ? null
                    : () => ref.read(apiTestProvider.notifier).run(api),
                icon: (test?.isLoading ?? false)
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow, size: 16),
                label: Text((test?.isLoading ?? false) ? 'Testing' : 'Test API'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (test != null && !test.isLoading) _StatusBar(test: test),
          if (test != null && !test.isLoading)
            const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (test?.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorSubtle,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              test!.error!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SectionLabel('Sample response'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _sample,
                    maxLines: 7,
                    minLines: 5,
                    monospace: true,
                    onChanged: (value) => ref
                        .read(apisProvider.notifier)
                        .updateApi(api.copyWith(responseJson: value)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionLabel(
                    'Schema',
                    trailing: TextButton.icon(
                      onPressed: schema == null ? null : () => _createFromResponse(api, schema),
                      icon: const Icon(Icons.add_circle_outline, size: 15),
                      label: const Text('Create variable'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppPanel(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: schema == null
                        ? Text(
                            'Add a valid JSON sample to inspect the response shape.',
                            style: AppTypography.bodySmall,
                          )
                        : ResponseTreeView(root: schema),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createFromResponse(ApiDefinition api, ResponseField schema) {
    final path = _bestSourcePath(schema);
    final variableName = _variableNameFor(api);

    final type = _typeForPath(schema, path);
    final variable = AppVariable(
      id: newId('var'),
      name: variableName,
      type: type,
      elementType: type == VariableType.list
          ? _elementTypeForPath(schema, path)
          : null,
      initialValue: type == VariableType.list ? '[]' : 'null',
      description: 'Created from ${api.name} response',
    );
    ref.read(variablesProvider.notifier).add(variable);
    ref
        .read(mappingDraftProvider.notifier)
        .startFor(api.id, defaultSource: path);
    ref
        .read(mappingDraftProvider.notifier)
        .selectVariable(variable.id);
    ref.read(builderSectionProvider.notifier).select(BuilderSection.mapping);
  }

  String _bestSourcePath(ResponseField schema) {
    for (final field in schema.flatten()) {
      if (field.kind == FieldKind.list) return field.path;
    }
    for (final field in schema.flatten()) {
      if (field.children.isEmpty) return field.path;
    }
    return schema.path;
  }

  VariableType _typeForPath(ResponseField schema, String path) {
    for (final field in schema.flatten()) {
      if (field.path != path) continue;
      return switch (field.kind) {
        FieldKind.list => VariableType.list,
        FieldKind.object => VariableType.object,
        FieldKind.number => VariableType.number,
        FieldKind.boolean => VariableType.boolean,
        FieldKind.nullValue => VariableType.json,
        FieldKind.string => VariableType.string,
      };
    }
    return VariableType.json;
  }

  /// Infers the `List<...>` element type from a list field's element shape.
  VariableType _elementTypeForPath(ResponseField schema, String path) {
    for (final field in schema.flatten()) {
      if (field.path != path) continue;
      if (field.kind != FieldKind.list) return VariableType.string;
      if (field.children.isEmpty) return VariableType.string;
      return VariableType.map;
    }
    return VariableType.string;
  }

  String _variableNameFor(ApiDefinition api) {
    final words = api.name
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'responseData';
    final first = words.first[0].toLowerCase() + words.first.substring(1);
    final rest = words
        .skip(1)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase());
    return [first, ...rest].join();
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.test});

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
            success ? '${test.statusCode} OK' : 'Request failed',
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
