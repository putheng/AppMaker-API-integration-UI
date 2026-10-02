/// The kind of value found in an API response schema.
enum FieldKind { string, number, boolean, list, object, nullValue }

/// A single node in the response schema tree shown in the visual mapper.
class ResponseField {
  const ResponseField({
    required this.name,
    required this.path,
    required this.kind,
    this.preview,
    this.children = const <ResponseField>[],
  });

  final String name;

  /// Dot-notation path, e.g. `response.data`.
  final String path;
  final FieldKind kind;

  /// A short human-readable preview of the value.
  final String? preview;
  final List<ResponseField> children;

  bool get isContainer => kind == FieldKind.object || kind == FieldKind.list;

  /// Builds a schema tree from a decoded JSON value.
  factory ResponseField.fromValue(
    String name,
    Object? value, {
    String path = '',
  }) {
    final fullPath = path.isEmpty ? name : '$path.$name';

    if (value is Map) {
      return ResponseField(
        name: name,
        path: fullPath,
        kind: FieldKind.object,
        preview: '{${value.length}}',
        children: [
          for (final entry in value.entries)
            ResponseField.fromValue(
              entry.key.toString(),
              entry.value,
              path: fullPath,
            ),
        ],
      );
    }

    if (value is List) {
      final children = <ResponseField>[];
      if (value.isNotEmpty && value.first is Map) {
        final first = value.first as Map;
        for (final entry in first.entries) {
          children.add(
            ResponseField.fromValue(
              entry.key.toString(),
              entry.value,
              path: fullPath,
            ),
          );
        }
      }
      return ResponseField(
        name: name,
        path: fullPath,
        kind: FieldKind.list,
        preview: '[${value.length}]',
        children: children,
      );
    }

    if (value == null) {
      return ResponseField(
        name: name,
        path: fullPath,
        kind: FieldKind.nullValue,
        preview: 'null',
      );
    }

    if (value is bool) {
      return ResponseField(
        name: name,
        path: fullPath,
        kind: FieldKind.boolean,
        preview: '$value',
      );
    }

    if (value is num) {
      return ResponseField(
        name: name,
        path: fullPath,
        kind: FieldKind.number,
        preview: '$value',
      );
    }

    return ResponseField(
      name: name,
      path: fullPath,
      kind: FieldKind.string,
      preview: '"$value"',
    );
  }

  /// Returns a flat list of every path in the tree (depth-first).
  List<ResponseField> flatten() {
    return [
      this,
      for (final child in children) ...child.flatten(),
    ];
  }
}
