import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../network/network_debug_bus.dart';

/// A drop-in [http.BaseClient] wrapper that logs every request/response into
/// [NetworkDebugBus].
///
/// Wrap your existing [http.Client]:
/// ```dart
/// final client = DebugHttpClient(inner: http.Client());
/// // or simply:
/// final client = DebugHttpClient();
/// ```
///
/// The original response stream is re-buffered transparently so callers
/// receive a normal [http.StreamedResponse].
class DebugHttpClient extends http.BaseClient {
  final http.Client _inner;
  final NetworkDebugBus _bus;

  DebugHttpClient({http.Client? inner, NetworkDebugBus? bus})
      : _inner = inner ?? http.Client(),
        _bus = bus ?? networkDebugBus;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final start = DateTime.now().millisecondsSinceEpoch;

    final id = _bus.startRequest(
      NetworkRequest(
        method: request.method,
        uri: request.url,
        headers: Map<String, dynamic>.from(request.headers),
        body: request is http.Request ? request.body : null,
      ),
    );

    try {
      final streamed = await _inner.send(request);
      final bytes = await streamed.stream.toBytes();
      final duration = DateTime.now().millisecondsSinceEpoch - start;

      _bus.completeRequest(
        id,
        response: NetworkResponse(
          statusCode: streamed.statusCode,
          // headers: Map<String, dynamic>.from(streamed.headers),
          body: _decodeBody(bytes, streamed.headers),
        ),
        durationMs: duration,
      );

      return http.StreamedResponse(
        Stream.value(bytes),
        streamed.statusCode,
        contentLength: bytes.length,
        headers: streamed.headers,
        isRedirect: streamed.isRedirect,
        persistentConnection: streamed.persistentConnection,
        reasonPhrase: streamed.reasonPhrase,
        request: streamed.request,
      );
    } catch (e) {
      _bus.completeRequest(
        id,
        errorMessage: e.toString(),
        durationMs: DateTime.now().millisecondsSinceEpoch - start,
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  static dynamic _decodeBody(Uint8List bytes, Map<String, String> headers) {
    if (bytes.isEmpty) return null;
    try {
      final contentType = headers['content-type'] ?? '';
      final str = utf8.decode(bytes);
      if (contentType.contains('application/json')) {
        return jsonDecode(str);
      }
      return str;
    } catch (_) {
      return bytes;
    }
  }
}
