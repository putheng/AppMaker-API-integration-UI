import 'package:flutter_test/flutter_test.dart';
import 'package:integration/models/action_flow.dart';
import 'package:integration/providers/action_flows_provider.dart';

void main() {
  const a = FlowStep(id: 'a', kind: StepKind.setVariable, variableId: 'x');
  const b = FlowStep(id: 'b', kind: StepKind.setVariable, variableId: 'y');
  const c = FlowStep(id: 'c', kind: StepKind.setVariable, variableId: 'z');
  const parent = FlowStep(
    id: 'p',
    kind: StepKind.callApi,
    onSuccess: [a, b, c],
  );

  test('reorderBranch moves a step to the front', () {
    final reordered = FlowStepTree.reorderBranch(parent, 'p', true, 2, 0);
    expect(reordered.onSuccess.map((s) => s.id), ['c', 'a', 'b']);
  });

  test('reorderBranch moves a step to the end', () {
    final reordered = FlowStepTree.reorderBranch(parent, 'p', true, 0, 2);
    expect(reordered.onSuccess.map((s) => s.id), ['b', 'c', 'a']);
  });

  test('reorderBranch only affects the targeted branch', () {
    final reordered = FlowStepTree.reorderBranch(parent, 'p', true, 0, 2);
    expect(reordered.onError, isEmpty);
    expect(reordered.onSuccess.map((s) => s.id), ['b', 'c', 'a']);
  });

  test('setVariable subtitle resolves the variable name', () {
    const step = FlowStep(
      id: 's',
      kind: StepKind.setVariable,
      variableId: 'var_1',
      expression: 'response.data',
    );
    expect(step.subtitleWith({'var_1': 'users'}), 'users  =  response.data');
  });

  test('responseApiFor finds the enclosing call API in either branch', () {
    const setter = FlowStep(
      id: 'set',
      kind: StepKind.setVariable,
      variableId: 'var_1',
      expression: 'response.token',
    );
    const errSetter = FlowStep(
      id: 'eset',
      kind: StepKind.setVariable,
      variableId: 'var_2',
      expression: 'response.message',
    );
    const call = FlowStep(
      id: 'call',
      kind: StepKind.callApi,
      apiId: 'api_login',
      onSuccess: [setter],
      onError: [errSetter],
    );

    expect(FlowStepTree.responseApiFor(call, 'set'), 'api_login');
    expect(FlowStepTree.responseApiFor(call, 'eset'), 'api_login');
    expect(FlowStepTree.responseApiFor(call, 'call'), isNull);
    expect(FlowStepTree.responseApiFor(setter, 'set'), isNull);
  });
}
