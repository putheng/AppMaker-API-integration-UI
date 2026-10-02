import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A saved response-to-variable mapping.
class ResponseMapping {
  const ResponseMapping({
    required this.id,
    required this.apiId,
    required this.apiName,
    required this.variableId,
    required this.expression,
    this.transform = '',
  });

  final String id;
  final String apiId;
  final String apiName;
  final String variableId;
  final String expression;
  final String transform;
}

class MappingsNotifier extends Notifier<List<ResponseMapping>> {
  @override
  List<ResponseMapping> build() => const [];

  void add(ResponseMapping mapping) => state = [...state, mapping];

  void remove(String id) {
    state = [
      for (final existing in state)
        if (existing.id != id) existing,
    ];
  }
}

final mappingsProvider =
    NotifierProvider<MappingsNotifier, List<ResponseMapping>>(
      MappingsNotifier.new,
    );

/// In-progress mapping edited on the Mapping screen.
class MappingDraft {
  const MappingDraft({
    this.apiId,
    this.sourcePath,
    this.variableId,
    this.advanced = false,
    this.transform = '',
  });

  final String? apiId;
  final String? sourcePath;
  final String? variableId;
  final bool advanced;
  final String transform;

  MappingDraft copyWith({
    String? apiId,
    String? sourcePath,
    String? variableId,
    bool? advanced,
    String? transform,
  }) {
    return MappingDraft(
      apiId: apiId ?? this.apiId,
      sourcePath: sourcePath ?? this.sourcePath,
      variableId: variableId ?? this.variableId,
      advanced: advanced ?? this.advanced,
      transform: transform ?? this.transform,
    );
  }
}

class MappingDraftNotifier extends Notifier<MappingDraft> {
  @override
  MappingDraft build() => const MappingDraft();

  void startFor(String apiId, {String? defaultSource}) {
    state = MappingDraft(apiId: apiId, sourcePath: defaultSource);
  }

  void selectSource(String path) => state = state.copyWith(sourcePath: path);

  void selectVariable(String id) => state = state.copyWith(variableId: id);

  void setAdvanced(bool value) => state = state.copyWith(advanced: value);

  void setTransform(String value) => state = state.copyWith(transform: value);

  void reset() => state = const MappingDraft();
}

final mappingDraftProvider =
    NotifierProvider<MappingDraftNotifier, MappingDraft>(
      MappingDraftNotifier.new,
    );
