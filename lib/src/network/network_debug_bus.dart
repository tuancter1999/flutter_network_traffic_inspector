import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Generic HTTP request snapshot, independent of any HTTP client library.
class DebugRequest {
  final String method;
  final Uri uri;
  final Map<String, dynamic> headers;
  final dynamic body;

  const DebugRequest({
    required this.method,
    required this.uri,
    this.headers = const {},
    this.body,
  });
}

/// Generic HTTP response snapshot, independent of any HTTP client library.
class DebugResponse {
  final int statusCode;
  final Map<String, dynamic> headers;
  final dynamic body;

  const DebugResponse({
    required this.statusCode,
    this.headers = const {},
    this.body,
  });
}

/// Represents a single HTTP request/response cycle captured by [NetworkDebugBus].
class NetworkLogEntry {
  final String id;
  final DateTime time;
  final DebugRequest request;
  final DebugResponse? response;

  /// Non-null when the request completed with a network/transport error.
  final String? errorMessage;

  /// Body from the error response, if any.
  final dynamic errorBody;

  final int? durationMs;

  const NetworkLogEntry({
    required this.id,
    required this.time,
    required this.request,
    this.response,
    this.errorMessage,
    this.errorBody,
    this.durationMs,
  });

  /// `true` when the request failed (transport error or HTTP status >= 400).
  bool get hasError =>
      errorMessage != null ||
      (response != null && response!.statusCode >= 400);

  /// Convenience accessor for the HTTP status code.
  int? get statusCode => response?.statusCode;
}

/// Represents a single WebSocket event captured by [NetworkDebugBus].
class WsLogEvent {
  final DateTime time;
  final String url;
  final String type;
  final Object? data;
  final Object? originalData;

  const WsLogEvent(
    this.time,
    this.url,
    this.type, {
    this.data,
    this.originalData,
  });

  WsLogEvent copyWithData(Object? newData, {Object? originalData}) {
    return WsLogEvent(
      time,
      url,
      type,
      data: newData,
      originalData: originalData ?? this.originalData,
    );
  }
}

/// In-memory log store for HTTP and WebSocket events.
///
/// Implements [ChangeNotifier] so widgets can rebuild reactively via
/// [AnimatedBuilder] or [ListenableBuilder].
///
/// Use the global [networkDebugBus] singleton or create a custom instance for
/// testing / isolation.
class NetworkDebugBus extends ChangeNotifier
    implements ValueListenable<NetworkDebugBus> {
  static const int _maxLengthHttp = 80;
  static const int _maxLengthWs = 250;

  final List<NetworkLogEntry> _http = <NetworkLogEntry>[];
  final List<WsLogEvent> _ws = <WsLogEvent>[];
  int _counter = 0;

  UnmodifiableListView<NetworkLogEntry> get http => UnmodifiableListView(_http);
  UnmodifiableListView<WsLogEvent> get ws => UnmodifiableListView(_ws);

  /// Records the start of an HTTP request and returns a unique [id] used to
  /// correlate the response or error via [completeRequest].
  String startRequest(DebugRequest request) {
    final id = '${_counter++}';
    _http.insert(
      0,
      NetworkLogEntry(id: id, time: DateTime.now(), request: request),
    );
    if (_http.length > _maxLengthHttp) {
      _http.removeLast();
    }
    notifyListeners();
    return id;
  }

  /// Updates the log entry identified by [id] with the final response or error.
  void completeRequest(
    String id, {
    DebugResponse? response,
    String? errorMessage,
    dynamic errorBody,
    int? durationMs,
  }) {
    final index = _http.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final old = _http[index];
    _http[index] = NetworkLogEntry(
      id: old.id,
      time: old.time,
      request: old.request,
      response: response,
      errorMessage: errorMessage,
      errorBody: errorBody,
      durationMs: durationMs,
    );
    notifyListeners();
  }

  void addWs(WsLogEvent event) {
    bool shouldRecord = true;
    if (event.type == 'recv' || event.type == 'send') {
      final data = event.data;
      if (data is String) {
        final lower = data.toLowerCase();
        if (lower.contains('"ping"') || lower.contains('"pong"')) {
          shouldRecord = false;
        } else if (lower == 'ping' || lower == 'pong') {
          shouldRecord = false;
        }
      } else if (data is Map) {
        final action =
            (data['action'] ?? data['event'])?.toString().toLowerCase();
        if (action == 'ping' || action == 'pong') {
          shouldRecord = false;
        }
      }
    }

    if (!shouldRecord) return;

    final originalData = event.data;

    Object? displayData = event.data;
    try {
      if (event.data is String) {
        final dynamic parsed = jsonDecode(event.data as String);
        if (parsed is Map && parsed.containsKey('payload')) {
          displayData = parsed['payload'];
        }
      } else if (event.data is Map) {
        final map = event.data as Map;
        if (map.containsKey('payload')) {
          displayData = map['payload'];
        }
      }
    } catch (_) {}

    _ws.insert(0, event.copyWithData(displayData, originalData: originalData));
    if (_ws.length > _maxLengthWs) {
      _ws.removeLast();
    }
    Future.microtask(notifyListeners);
  }

  void clear() {
    _http.clear();
    _ws.clear();
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) => super.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => super.removeListener(listener);

  @override
  NetworkDebugBus get value => this;
}

/// Global debug bus instance. Override in tests or pass [NetworkDebugBus] to widgets.
NetworkDebugBus networkDebugBus = NetworkDebugBus();
