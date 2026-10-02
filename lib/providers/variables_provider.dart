import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seed_data.dart';
import '../models/app_variable.dart';

/// Owns the list of user-defined application variables.
class VariablesNotifier extends Notifier<List<AppVariable>> {
  @override
  List<AppVariable> build() => List<AppVariable>.of(seedVariables);

  void add(AppVariable variable) => state = [...state, variable];

  void updateVariable(AppVariable variable) {
    state = [
      for (final existing in state)
        if (existing.id == variable.id) variable else existing,
    ];
  }

  void remove(String id) {
    state = [
      for (final existing in state)
        if (existing.id != id) existing,
    ];
  }
}

final variablesProvider =
    NotifierProvider<VariablesNotifier, List<AppVariable>>(
      VariablesNotifier.new,
    );

extension VariableLookup on List<AppVariable> {
  AppVariable? byId(String? id) {
    if (id == null) return null;
    for (final variable in this) {
      if (variable.id == id) return variable;
    }
    return null;
  }

  AppVariable? byName(String? name) {
    if (name == null) return null;
    for (final variable in this) {
      if (variable.name == name) return variable;
    }
    return null;
  }
}
