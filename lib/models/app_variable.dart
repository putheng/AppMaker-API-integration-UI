/// Types of application variables that can be bound to API responses.
enum VariableType { string, number, boolean, list, map, object, json }

/// How the initial value is edited: raw code or a structured builder.
enum InitialValueMode { builder, code }

/// A user-defined application variable, mirroring the README's variable table.
class AppVariable {
  const AppVariable({
    required this.id,
    required this.name,
    required this.type,
    this.elementType,
    this.initialValue = '',
    this.valueMode = InitialValueMode.builder,
    this.description = '',
  });

  final String id;
  final String name;
  final VariableType type;

  /// Element type when [type] is [VariableType.list], producing strict
  /// Flutter types such as `List<String>` or `List<Map<String, dynamic>>`.
  final VariableType? elementType;
  final String initialValue;

  /// Whether the initial value is edited as code or with the visual builder.
  final InitialValueMode valueMode;
  final String description;

  AppVariable copyWith({
    String? name,
    VariableType? type,
    VariableType? elementType,
    String? initialValue,
    InitialValueMode? valueMode,
    String? description,
  }) {
    return AppVariable(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      elementType: elementType ?? this.elementType,
      initialValue: initialValue ?? this.initialValue,
      valueMode: valueMode ?? this.valueMode,
      description: description ?? this.description,
    );
  }
}
