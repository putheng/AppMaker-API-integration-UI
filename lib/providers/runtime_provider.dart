import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/action_flow.dart';
import 'apis_provider.dart';
import 'variables_provider.dart';

enum RuntimeLogKind { info, success, error }

class RuntimeLogEntry {
  const RuntimeLogEntry(this.message, this.kind);

  final String message;
  final RuntimeLogKind kind;
}

/// Simulated runtime state used by the Preview screen to demonstrate the
/// `API -> Response -> Variable -> UI` loop from the README.
class RuntimeState {
  const RuntimeState({
    this.values = const {},
    this.log = const [],
    this.isRunning = false,
  });

  final Map<String, Object?> values;
  final List<RuntimeLogEntry> log;
  final bool isRunning;

  RuntimeState copyWith({
    Map<String, Object?>? values,
    List<RuntimeLogEntry>? log,
    bool? isRunning,
  }) {
    return RuntimeState(
      values: values ?? this.values,
      log: log ?? this.log,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class RuntimeNotifier extends Notifier<RuntimeState> {
  @override
  RuntimeState build() => RuntimeState(values: _initialValues());

  Map<String, Object?> _initialValues() {
    final variables = ref.read(variablesProvider);
    return {
      for (final variable in variables) variable.name: _parseInitial(variable.initialValue),
    };
  }

  Object? _parseInitial(String raw) {
    final value = raw.trim();
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (value == 'null' || value.isEmpty) return null;
    return num.tryParse(value) ?? value;
  }

  void reset() {
    state = RuntimeState(values: _initialValues());
  }

  Future<void> run(ActionFlow flow) async {
    state = state.copyWith(
      isRunning: true,
      log: [RuntimeLogEntry('▶ Running "${flow.name}"', RuntimeLogKind.info)],
    );

    for (final step in flow.steps) {
      await _runStep(step, null);
    }

    state = state.copyWith(
      isRunning: false,
      log: [...state.log, const RuntimeLogEntry('✔ Flow completed', RuntimeLogKind.success)],
    );
  }

  Future<void> _runStep(FlowStep step, Map<String, dynamic>? response) async {
    if (!step.enabled) return;

    switch (step.kind) {
      case StepKind.callApi:
        final api = ref.read(apisProvider).byId(step.apiId);
        _log('↳ Call API · ${api?.name ?? 'Unknown API'}', RuntimeLogKind.info);
        await Future<void>.delayed(const Duration(milliseconds: 350));
        final decoded = api?.decodedResponse();
        if (decoded == null) {
          _log('  ✖ No sample response configured', RuntimeLogKind.error);
          return;
        }
        for (final child in step.onSuccess) {
          await _runStep(child, decoded);
        }
      case StepKind.setVariable:
        final variable = ref.read(variablesProvider).byId(step.variableId);
        final name = variable?.name ?? step.variableId ?? 'unknown';
        final value = _evaluate(step.expression, response);
        state = state.copyWith(values: {...state.values, name: value});
        _log('  ${_format(name)} = ${_format(value)}', RuntimeLogKind.success);
      case StepKind.condition:
        _log('  if (${step.expression})', RuntimeLogKind.info);
      case StepKind.navigate:
        _log('  → Navigate to ${step.target}', RuntimeLogKind.info);
      case StepKind.showMessage:
        _log('  ! Snackbar "${step.expression}"', RuntimeLogKind.info);
      case StepKind.transform:
        _log('  ⟳ Transform: ${step.expression}', RuntimeLogKind.info);
    }
  }

  Object? _evaluate(String expression, Map<String, dynamic>? response) {
    final raw = expression.trim();
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    if (raw == 'null' || raw.isEmpty) return null;

    final number = num.tryParse(raw);
    if (number != null) return number;

    if (raw.startsWith('response')) {
      final path = raw.substring('response'.length);
      return _resolvePath(response, path);
    }

    if (state.values.containsKey(raw)) return state.values[raw];
    return raw;
  }

  Object? _resolvePath(Object? root, String path) {
    final segments = path.split('.').where((segment) => segment.isNotEmpty);
    Object? current = root;
    for (final segment in segments) {
      if (current is Map) {
        current = current[segment];
      } else if (current is List) {
        final index = int.tryParse(segment);
        current = (index != null && index < current.length) ? current[index] : null;
      } else {
        return null;
      }
    }
    return current;
  }

  String _format(Object? value) {
    if (value == null) return 'null';
    if (value is List) return '[${value.length} items]';
    if (value is Map) return '{${value.length} fields}';
    return '$value';
  }

  void _log(String message, RuntimeLogKind kind) {
    state = state.copyWith(log: [...state.log, RuntimeLogEntry(message, kind)]);
  }
}

final runtimeProvider = NotifierProvider<RuntimeNotifier, RuntimeState>(
  RuntimeNotifier.new,
);
