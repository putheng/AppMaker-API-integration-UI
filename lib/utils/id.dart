import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Generates a unique id, optionally namespaced with [prefix].
String newId([String prefix = 'id']) => '${prefix}_${_uuid.v4()}';
