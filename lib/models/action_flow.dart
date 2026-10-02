/// What starts an action flow.
enum FlowTrigger { onTap, onPageLoad, onSubmit, onLongPress, onChange }

extension FlowTriggerLabel on FlowTrigger {
  String get label => switch (this) {
    FlowTrigger.onTap => 'On Tap',
    FlowTrigger.onPageLoad => 'On Page Load',
    FlowTrigger.onSubmit => 'On Submit',
    FlowTrigger.onLongPress => 'On Long Press',
    FlowTrigger.onChange => 'On Change',
  };
}

/// The primitive step types described in section 9 of the README.
enum StepKind { callApi, setVariable, condition, navigate, showMessage, transform }

extension StepKindLabel on StepKind {
  String get label => switch (this) {
    StepKind.callApi => 'Call API',
    StepKind.setVariable => 'Set Variable',
    StepKind.condition => 'Conditional',
    StepKind.navigate => 'Navigate',
    StepKind.showMessage => 'Show Message',
    StepKind.transform => 'Transform Response',
  };
}

/// A single node in an action flow. `callApi` steps can branch into
/// `onSuccess` and `onError` child step lists.
class FlowStep {
  const FlowStep({
    required this.id,
    required this.kind,
    this.label = '',
    this.apiId,
    this.variableId,
    this.expression = '',
    this.target = '',
    this.enabled = true,
    this.onSuccess = const <FlowStep>[],
    this.onError = const <FlowStep>[],
  });

  final String id;
  final StepKind kind;
  final String label;
  final String? apiId;
  final String? variableId;
  final String expression;
  final String target;
  final bool enabled;
  final List<FlowStep> onSuccess;
  final List<FlowStep> onError;

  /// Short human-readable description shown under the step title.
  String get subtitle {
    switch (kind) {
      case StepKind.callApi:
        return label.isEmpty ? 'Select an API' : label;
      case StepKind.setVariable:
        return '$variableId  =  $expression';
      case StepKind.condition:
        return expression.isEmpty ? 'if (condition)' : expression;
      case StepKind.navigate:
        return target.isEmpty ? 'Select a page' : '→  $target';
      case StepKind.showMessage:
        return expression.isEmpty ? 'Message text' : '"$expression"';
      case StepKind.transform:
        return expression.isEmpty ? 'Filter / Map / Sort' : expression;
    }
  }

  FlowStep copyWith({
    String? label,
    String? apiId,
    String? variableId,
    String? expression,
    String? target,
    bool? enabled,
    List<FlowStep>? onSuccess,
    List<FlowStep>? onError,
  }) {
    return FlowStep(
      id: id,
      kind: kind,
      label: label ?? this.label,
      apiId: apiId ?? this.apiId,
      variableId: variableId ?? this.variableId,
      expression: expression ?? this.expression,
      target: target ?? this.target,
      enabled: enabled ?? this.enabled,
      onSuccess: onSuccess ?? this.onSuccess,
      onError: onError ?? this.onError,
    );
  }
}

/// An action flow: a trigger plus an ordered list of steps.
class ActionFlow {
  const ActionFlow({
    required this.id,
    required this.name,
    required this.trigger,
    required this.steps,
    this.description = '',
  });

  final String id;
  final String name;
  final FlowTrigger trigger;
  final List<FlowStep> steps;
  final String description;

  ActionFlow copyWith({List<FlowStep>? steps, String? name}) {
    return ActionFlow(
      id: id,
      name: name ?? this.name,
      trigger: trigger,
      steps: steps ?? this.steps,
      description: description,
    );
  }
}
