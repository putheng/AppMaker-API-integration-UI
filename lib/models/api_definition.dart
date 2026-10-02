import 'dart:convert';

import 'response_field.dart';

/// HTTP verbs supported by the API editor.
enum HttpMethod { get, post, put, patch, delete }

extension HttpMethodLabel on HttpMethod {
  String get label => switch (this) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.patch => 'PATCH',
    HttpMethod.delete => 'DELETE',
  };
}

/// A single editable header or query parameter row.
class KeyValuePair {
  const KeyValuePair({
    required this.id,
    this.key = '',
    this.value = '',
    this.enabled = true,
  });

  final String id;
  final String key;
  final String value;
  final bool enabled;

  KeyValuePair copyWith({String? key, String? value, bool? enabled}) {
    return KeyValuePair(
      id: id,
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// A reusable API definition: request + sample response.
class ApiDefinition {
  const ApiDefinition({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headers = const <KeyValuePair>[],
    this.query = const <KeyValuePair>[],
    this.body = '',
    this.responseJson = '',
  });

  final String id;
  final String name;
  final HttpMethod method;
  final String url;
  final List<KeyValuePair> headers;
  final List<KeyValuePair> query;
  final String body;
  final String responseJson;

  bool get hasResponse => responseJson.trim().isNotEmpty;

  /// Decodes [responseJson] and builds the schema shown in the mapper.
  ResponseField? buildSchema() {
    if (!hasResponse) return null;
    try {
      final decoded = jsonDecode(responseJson);
      return ResponseField.fromValue('response', decoded);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic>? decodedResponse() {
    if (!hasResponse) return null;
    try {
      final decoded = jsonDecode(responseJson);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      return null;
    }
  }

  ApiDefinition copyWith({
    String? name,
    HttpMethod? method,
    String? url,
    List<KeyValuePair>? headers,
    List<KeyValuePair>? query,
    String? body,
    String? responseJson,
  }) {
    return ApiDefinition(
      id: id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      query: query ?? this.query,
      body: body ?? this.body,
      responseJson: responseJson ?? this.responseJson,
    );
  }
}
