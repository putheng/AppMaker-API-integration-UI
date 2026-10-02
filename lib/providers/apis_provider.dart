import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seed_data.dart';
import '../models/api_definition.dart';

/// Owns the reusable API definitions.
class ApisNotifier extends Notifier<List<ApiDefinition>> {
  @override
  List<ApiDefinition> build() => List<ApiDefinition>.of(seedApis);

  void add(ApiDefinition api) => state = [...state, api];

  void updateApi(ApiDefinition api) {
    state = [
      for (final existing in state)
        if (existing.id == api.id) api else existing,
    ];
  }

  void remove(String id) {
    state = [
      for (final existing in state)
        if (existing.id != id) existing,
    ];
  }
}

final apisProvider = NotifierProvider<ApisNotifier, List<ApiDefinition>>(
  ApisNotifier.new,
);

/// Currently selected API in the APIs screen.
class SelectedApiNotifier extends Notifier<String?> {
  @override
  String? build() => seedApis.first.id;

  void select(String? id) => state = id;
}

final selectedApiProvider =
    NotifierProvider<SelectedApiNotifier, String?>(SelectedApiNotifier.new);

extension ApiLookup on List<ApiDefinition> {
  ApiDefinition? byId(String? id) {
    if (id == null) return null;
    for (final api in this) {
      if (api.id == id) return api;
    }
    return null;
  }
}
