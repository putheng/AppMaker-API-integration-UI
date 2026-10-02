import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_definition.dart';

/// Result of a (simulated) API test call.
class ApiTestState {
  const ApiTestState({
    this.isLoading = false,
    this.response,
    this.error,
    this.statusCode,
    this.latencyMs,
  });

  const ApiTestState.loading() : this(isLoading: true);

  final bool isLoading;
  final Map<String, dynamic>? response;
  final String? error;
  final int? statusCode;
  final int? latencyMs;

  bool get isSuccess => response != null && !isLoading;
  bool get isError => error != null && !isLoading;
}

/// Runs API tests and keys results by API id.
class ApiTestNotifier extends Notifier<Map<String, ApiTestState>> {
  @override
  Map<String, ApiTestState> build() => const {};

  Future<void> run(ApiDefinition api) async {
    state = {...state, api.id: const ApiTestState.loading()};
    final started = DateTime.now();
    await Future<void>.delayed(const Duration(milliseconds: 750));
    final latency = DateTime.now().difference(started).inMilliseconds;
    final decoded = api.decodedResponse();

    if (decoded == null) {
      state = {
        ...state,
        api.id: ApiTestState(
          error: 'No response configured. Add a sample response to test.',
          latencyMs: latency,
        ),
      };
      return;
    }

    state = {
      ...state,
      api.id: ApiTestState(
        response: decoded,
        statusCode: 200,
        latencyMs: latency,
      ),
    };
  }

  void reset(String apiId) {
    state = {...state}..remove(apiId);
  }
}

final apiTestProvider =
    NotifierProvider<ApiTestNotifier, Map<String, ApiTestState>>(
      ApiTestNotifier.new,
    );
