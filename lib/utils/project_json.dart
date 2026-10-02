import '../models/action_flow.dart';
import '../models/api_definition.dart';
import '../models/app_variable.dart';
import '../models/binding.dart';
import '../models/response_field.dart';

/// Serialises the current project to the JSON DSL described in section 9
/// of the README.
Map<String, dynamic> buildProjectJson({
  required List<ApiDefinition> apis,
  required List<AppVariable> variables,
  required List<ActionFlow> flows,
  required List<WidgetBinding> bindings,
}) {
  return {
    'version': '0.1.0',
    'apis': [for (final api in apis) _apiToJson(api)],
    'variables': [for (final variable in variables) _variableToJson(variable)],
    'actions': [for (final flow in flows) _flowToJson(flow)],
    'bindings': [for (final binding in bindings) _bindingToJson(binding)],
  };
}

Map<String, dynamic> _apiToJson(ApiDefinition api) {
  return {
    'name': api.name,
    'request': {
      'method': api.method.label,
      'url': api.url,
      'headers': {
        for (final header in api.headers)
          if (header.key.isNotEmpty) header.key: header.value,
      },
      'query': {
        for (final query in api.query)
          if (query.key.isNotEmpty) query.key: query.value,
      },
      if (api.body.trim().isNotEmpty) 'body': api.body,
    },
    'response': {'schema': _schemaToJson(api.buildSchema())},
  };
}

Map<String, dynamic>? _schemaToJson(ResponseField? field) {
  if (field == null) return null;
  if (field.children.isEmpty) {
    return {'type': fieldKindName(field.kind)};
  }
  return {
    'type': fieldKindName(field.kind),
    'fields': {
      for (final child in field.children) child.name: _schemaToJson(child),
    },
  };
}

String fieldKindName(FieldKind kind) => switch (kind) {
  FieldKind.string => 'string',
  FieldKind.number => 'number',
  FieldKind.boolean => 'boolean',
  FieldKind.list => 'list',
  FieldKind.object => 'object',
  FieldKind.nullValue => 'null',
};

Map<String, dynamic> _variableToJson(AppVariable variable) {
  return {
    'name': variable.name,
    'type': variable.type.name,
    if (variable.type == VariableType.list)
      'elementType': (variable.elementType ?? VariableType.string).name,
    'initial': variable.initialValue,
  };
}

Map<String, dynamic> _flowToJson(ActionFlow flow) {
  return {
    'name': flow.name,
    'trigger': flow.trigger.name,
    'steps': [for (final step in flow.steps) _stepToJson(step)],
  };
}

Map<String, dynamic> _stepToJson(FlowStep step) {
  return {
    'type': step.kind.name,
    if (step.label.isNotEmpty) 'label': step.label,
    if (step.apiId != null) 'api': step.apiId,
    if (step.variableId != null) 'variable': step.variableId,
    if (step.expression.isNotEmpty) 'expression': step.expression,
    if (step.target.isNotEmpty) 'target': step.target,
    if (step.onSuccess.isNotEmpty)
      'on_success': [for (final child in step.onSuccess) _stepToJson(child)],
    if (step.onError.isNotEmpty)
      'on_error': [for (final child in step.onError) _stepToJson(child)],
  };
}

Map<String, dynamic> _bindingToJson(WidgetBinding binding) {
  return {
    'widget': binding.widgetName,
    'kind': binding.kind.name,
    if (binding.sourceVariableId != null) 'variable': binding.sourceVariableId,
    'fields': [
      for (final field in binding.fields)
        {'label': field.label, 'expression': field.expression},
    ],
  };
}
