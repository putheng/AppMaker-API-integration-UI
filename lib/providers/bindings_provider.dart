import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seed_data.dart';
import '../models/binding.dart';
import 'variables_provider.dart';

/// Owns widget-to-variable bindings.
class BindingsNotifier extends Notifier<List<WidgetBinding>> {
  @override
  List<WidgetBinding> build() => List<WidgetBinding>.of(seedBindings);

  void add(WidgetBinding binding) => state = [...state, binding];

  void updateBinding(WidgetBinding binding) {
    state = [
      for (final existing in state)
        if (existing.id == binding.id) binding else existing,
    ];
  }

  void remove(String id) {
    state = [
      for (final existing in state)
        if (existing.id != id) existing,
    ];
  }
}

final bindingsProvider =
    NotifierProvider<BindingsNotifier, List<WidgetBinding>>(
      BindingsNotifier.new,
    );

/// Convenience provider: bindings paired with their resolved variable.
class ResolvedBinding {
  const ResolvedBinding({required this.binding, this.variableName, this.sample});

  final WidgetBinding binding;
  final String? variableName;
  final String? sample;
}

final resolvedBindingsProvider = Provider<List<ResolvedBinding>>((ref) {
  final bindings = ref.watch(bindingsProvider);
  final variables = ref.watch(variablesProvider);

  return [
    for (final binding in bindings)
      ResolvedBinding(
        binding: binding,
        variableName: variables.byId(binding.sourceVariableId)?.name,
        sample: binding.fields.isEmpty ? null : binding.fields.first.expression,
      ),
  ];
});
