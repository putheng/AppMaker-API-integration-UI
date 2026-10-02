import 'dart:convert';

import '../utils/id.dart';
import 'app_variable.dart';

/// Kinds of values in the structured initial-value builder.
enum ValueKind { text, number, boolean, map, list, nullValue }

String _newId() => newId('vn');

/// An immutable node in the structured initial-value tree.
class ValueNode {
  const ValueNode({
    required this.id,
    required this.kind,
    this.key = '',
    this.value,
    this.children = const <ValueNode>[],
  });

  final String id;
  final ValueKind kind;
  final String key;
  final Object? value;
  final List<ValueNode> children;

  bool get isContainer => kind == ValueKind.map || kind == ValueKind.list;

  ValueNode copyWith({
    String? key,
    ValueKind? kind,
    Object? value,
    List<ValueNode>? children,
  }) {
    return ValueNode(
      id: id,
      key: key ?? this.key,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      children: children ?? this.children,
    );
  }

  // --- Construction ---------------------------------------------------------

  static ValueNode empty(ValueKind kind, {String key = ''}) {
    return ValueNode(
      id: _newId(),
      key: key,
      kind: kind,
      value: switch (kind) {
        ValueKind.number => 0,
        ValueKind.boolean => false,
        ValueKind.text => '',
        _ => null,
      },
    );
  }

  /// Builds a tree from a decoded JSON value.
  factory ValueNode.fromJson({required String key, required Object? json}) {
    if (json is Map) {
      return ValueNode(
        id: _newId(),
        key: key,
        kind: ValueKind.map,
        children: [
          for (final entry in json.entries)
            ValueNode.fromJson(key: entry.key.toString(), json: entry.value),
        ],
      );
    }
    if (json is List) {
      return ValueNode(
        id: _newId(),
        key: key,
        kind: ValueKind.list,
        children: [
          for (var i = 0; i < json.length; i++)
            ValueNode.fromJson(key: '$i', json: json[i]),
        ],
      );
    }
    if (json is bool) {
      return ValueNode(
        id: _newId(),
        key: key,
        kind: ValueKind.boolean,
        value: json,
      );
    }
    if (json is num) {
      return ValueNode(
        id: _newId(),
        key: key,
        kind: ValueKind.number,
        value: json,
      );
    }
    if (json == null) {
      return ValueNode(id: _newId(), key: key, kind: ValueKind.nullValue);
    }
    return ValueNode(
      id: _newId(),
      key: key,
      kind: ValueKind.text,
      value: json.toString(),
    );
  }

  /// Parses the raw [initialValue] string into a builder tree based on [type].
  static ValueNode parse(String initialValue, VariableType type) {
    final text = initialValue.trim();

    switch (type) {
      case VariableType.string:
        return ValueNode(
          id: _newId(),
          kind: ValueKind.text,
          value: initialValue,
        );
      case VariableType.number:
        return ValueNode(
          id: _newId(),
          kind: ValueKind.number,
          value: num.tryParse(text) ?? 0,
        );
      case VariableType.boolean:
        return ValueNode(
          id: _newId(),
          kind: ValueKind.boolean,
          value: text == 'true',
        );
      case VariableType.list:
      case VariableType.map:
      case VariableType.object:
      case VariableType.json:
        if (text.isEmpty) return empty(_rootKindFor(type));
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map || decoded is List) {
            return ValueNode.fromJson(key: '', json: decoded);
          }
        } on FormatException {
          // fall through to an empty container
        }
        return empty(_rootKindFor(type));
    }
  }

  static ValueKind _rootKindFor(VariableType type) => switch (type) {
    VariableType.list => ValueKind.list,
    VariableType.map || VariableType.object || VariableType.json =>
      ValueKind.map,
    _ => ValueKind.text,
  };

  // --- Encoding -------------------------------------------------------------

  Object? toJson() {
    return switch (kind) {
      ValueKind.text => value?.toString() ?? '',
      ValueKind.number => value is num ? value : num.tryParse('${value ?? 0}') ?? 0,
      ValueKind.boolean => value == true,
      ValueKind.nullValue => null,
      ValueKind.map => {
        for (final child in children) child.key: child.toJson(),
      },
      ValueKind.list => [for (final child in children) child.toJson()],
    };
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  // --- Tree operations ------------------------------------------------------

  static ValueNode update(
    ValueNode node,
    String id,
    ValueNode Function(ValueNode) change,
  ) {
    if (node.id == id) return change(node);
    return node.copyWith(
      children: [for (final child in node.children) update(child, id, change)],
    );
  }

  static ValueNode addChild(ValueNode root, String parentId, ValueNode child) {
    if (root.id == parentId) {
      return root.copyWith(children: [...root.children, child]);
    }
    return root.copyWith(
      children: [
        for (final node in root.children) addChild(node, parentId, child),
      ],
    );
  }

  static ValueNode remove(ValueNode root, String id) {
    return root.copyWith(
      children: [
        for (final child in root.children)
          if (child.id != id) remove(child, id),
      ],
    );
  }

  static ValueNode? find(ValueNode root, String id) {
    if (root.id == id) return root;
    for (final child in root.children) {
      final match = find(child, id);
      if (match != null) return match;
    }
    return null;
  }
}
