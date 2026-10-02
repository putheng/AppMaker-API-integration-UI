/// Types of application variables that can be bound to API responses.
enum VariableType { string, number, boolean, list, map, object, json }

/// Where a variable lives and how long it survives.
enum VariableScope { global, page, session }

/// A user-defined application variable, mirroring the README's variable table.
class AppVariable {
  const AppVariable({
    required this.id,
    required this.name,
    required this.type,
    this.elementType,
    this.initialValue = '',
    this.scope = VariableScope.global,
    this.description = '',
  });

  final String id;
  final String name;
  final VariableType type;

  /// Element type when [type] is [VariableType.list], producing strict
  /// Flutter types such as `List<String>` or `List<Map<String, dynamic>>`.
  final VariableType? elementType;
  final String initialValue;
  final VariableScope scope;
  final String description;

  AppVariable copyWith({
    String? name,
    VariableType? type,
    VariableType? elementType,
    String? initialValue,
    VariableScope? scope,
    String? description,
  }) {
    return AppVariable(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      elementType: elementType ?? this.elementType,
      initialValue: initialValue ?? this.initialValue,
      scope: scope ?? this.scope,
      description: description ?? this.description,
    );
  }
}
