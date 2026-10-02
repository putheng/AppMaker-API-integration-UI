import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seed_data.dart';
import '../models/action_flow.dart';

/// Owns the action flows (triggers + steps).
class ActionFlowsNotifier extends Notifier<List<ActionFlow>> {
  @override
  List<ActionFlow> build() => List<ActionFlow>.of(seedFlows);

  void updateFlow(ActionFlow flow) {
    state = [
      for (final existing in state)
        if (existing.id == flow.id) flow else existing,
    ];
  }

  void add(ActionFlow flow) => state = [...state, flow];

  void remove(String id) {
    state = [
      for (final existing in state)
        if (existing.id != id) existing,
    ];
  }
}

final actionFlowsProvider =
    NotifierProvider<ActionFlowsNotifier, List<ActionFlow>>(
      ActionFlowsNotifier.new,
    );

/// Currently selected action flow in the Actions screen.
class SelectedFlowNotifier extends Notifier<String?> {
  @override
  String? build() => seedFlows.first.id;

  void select(String id) => state = id;
}

final selectedFlowProvider = NotifierProvider<SelectedFlowNotifier, String?>(
  SelectedFlowNotifier.new,
);

extension FlowLookup on List<ActionFlow> {
  ActionFlow? byId(String? id) {
    if (id == null) return null;
    for (final flow in this) {
      if (flow.id == id) return flow;
    }
    return null;
  }
}

/// Depth-first helpers for editing nested flow steps.
abstract final class FlowStepTree {
  static FlowStep? find(FlowStep node, String id) {
    if (node.id == id) return node;
    for (final child in [...node.onSuccess, ...node.onError]) {
      final match = find(child, id);
      if (match != null) return match;
    }
    return null;
  }

  static FlowStep replace(FlowStep node, FlowStep updated) {
    if (node.id == updated.id) return updated;
    return node.copyWith(
      onSuccess: [for (final c in node.onSuccess) replace(c, updated)],
      onError: [for (final c in node.onError) replace(c, updated)],
    );
  }

  static FlowStep remove(FlowStep node, String id) {
    return node.copyWith(
      onSuccess: [
        for (final c in node.onSuccess)
          if (c.id != id) remove(c, id),
      ],
      onError: [
        for (final c in node.onError)
          if (c.id != id) remove(c, id),
      ],
    );
  }

  static FlowStep addChild(
    FlowStep root,
    String parentId,
    FlowStep child, {
    required bool onSuccess,
  }) {
    if (root.id == parentId) {
      return onSuccess
          ? root.copyWith(onSuccess: [...root.onSuccess, child])
          : root.copyWith(onError: [...root.onError, child]);
    }
    return root.copyWith(
      onSuccess: [
        for (final c in root.onSuccess)
          addChild(c, parentId, child, onSuccess: onSuccess),
      ],
      onError: [
        for (final c in root.onError)
          addChild(c, parentId, child, onSuccess: onSuccess),
      ],
    );
  }
}
