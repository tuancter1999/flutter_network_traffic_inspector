import 'package:dio/dio.dart';

import 'network/network_debug_bus.dart';

/// Dio interceptor that feeds HTTP requests/responses into [NetworkDebugBus].
///
/// Add to your [Dio] instance during app initialisation:
/// ```dart
/// dio.interceptors.add(DebugLogInterceptor());
/// ```
class DebugLogInterceptor extends Interceptor {
  final NetworkDebugBus _bus;

  /// Creates an interceptor that logs to [bus].
  /// Defaults to the global [networkDebugBus] singleton.
  DebugLogInterceptor({NetworkDebugBus? bus}) : _bus = bus ?? networkDebugBus;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final start = DateTime.now().millisecondsSinceEpoch;
    final id = _bus.startRequest(
      DebugRequest(
        method: options.method,
        uri: options.uri,
        headers: Map<String, dynamic>.from(options.headers),
        body: options.data,
      ),
    );
    options.extra['__debug_id'] = id;
    options.extra['__start'] = start;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra['__debug_id'] as String?;
    final start = response.requestOptions.extra['__start'] as int?;
    final duration =
        start != null ? DateTime.now().millisecondsSinceEpoch - start : null;
    if (id != null) {
      _bus.completeRequest(
        id,
        response: DebugResponse(
          statusCode: response.statusCode ?? 0,
          headers: _dioHeadersToMap(response.headers),
          body: response.data,
        ),
        durationMs: duration,
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.extra['__debug_id'] as String?;
    final start = err.requestOptions.extra['__start'] as int?;
    final duration =
        start != null ? DateTime.now().millisecondsSinceEpoch - start : null;
    if (id != null) {
      _bus.completeRequest(
        id,
        response: err.response != null
            ? DebugResponse(
                statusCode: err.response!.statusCode ?? 0,
                headers: _dioHeadersToMap(err.response!.headers),
                body: err.response!.data,
              )
            : null,
        errorMessage: err.message,
        durationMs: duration,
      );
    }
    super.onError(err, handler);
  }

  static Map<String, dynamic> _dioHeadersToMap(Headers headers) {
    return headers.map.map(
      (k, v) => MapEntry(k, v.length == 1 ? v.first : v),
    );
  }
}
