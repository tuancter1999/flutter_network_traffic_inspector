import 'dart:io';
import 'package:network_traffic_inspector/network_traffic_inspector.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final _navigatorKey = GlobalKey<NavigatorState>();

// ── HTTP clients ──────────────────────────────────────────────────────────────

late final Dio _dio;
late final DebugHttpClient _httpClient;

void main() {
  _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
  if (kDebugMode) {
    _dio.interceptors.add(NetworkTrafficInterceptor());
  }

  _httpClient = DebugHttpClient(inner: http.Client());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DebugOverlayHost(
      // Remove or set to false in release builds.
      enabled: kDebugMode,
      navigatorKey: _navigatorKey,
      overlayBuilder: (_) => DraggableDebugOverlay(
        navigatorKey: _navigatorKey,
        // Enable the WebSocket tab in the overlay panel.
        showWebSocketLogs: true,
      ),
      child: MaterialApp(
        title: 'network_traffic_inspector example',
        navigatorKey: _navigatorKey,
        home: const _HomePage(),
      ),
    );
  }
}

// ── Home page ─────────────────────────────────────────────────────────────────

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  // ── WebSocket state ────────────────────────────────────────────────────────

  // Public echo server — reflects every message back to the sender.
  static const _wsUrl = 'wss://ws.postman-echo.com/raw';

  WebSocket? _socket;
  bool get _connected => _socket != null;

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  Future<void> _dioPosts() async {
    try {
      await _dio.get('/posts');
    } catch (_) {}
  }

  Future<void> _dioNotFound() async {
    try {
      await _dio.get('/not-found');
    } catch (_) {}
  }

  Future<void> _httpGet() async {
    try {
      await _httpClient
          .get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1'));
    } catch (_) {}
  }

  Future<void> _httpPost() async {
    try {
      await _httpClient.post(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
        headers: {'Content-Type': 'application/json'},
        body: '{"title":"foo","body":"bar","userId":1}',
      );
    } catch (_) {}
  }

  // ── WebSocket helpers ──────────────────────────────────────────────────────

  Future<void> _wsConnect() async {
    if (_connected) return;
    try {
      final ws = await WebSocket.connect(_wsUrl);
      // Log the successful connection.
      networkDebugBus.addWs(WsLogEvent(DateTime.now(), _wsUrl, 'connect'));

      ws.listen(
        (data) {
          // Log every incoming message.
          networkDebugBus.addWs(
            WsLogEvent(DateTime.now(), _wsUrl, 'recv', data: data),
          );
        },
        onError: (Object error) {
          networkDebugBus.addWs(
            WsLogEvent(DateTime.now(), _wsUrl, 'error',
                data: error.toString()),
          );
          if (mounted) setState(() => _socket = null);
        },
        onDone: () {
          // Log the close event (fires whether we close or the server does).
          networkDebugBus.addWs(WsLogEvent(DateTime.now(), _wsUrl, 'close'));
          if (mounted) setState(() => _socket = null);
        },
      );

      setState(() => _socket = ws);
    } catch (e) {
      networkDebugBus.addWs(
        WsLogEvent(DateTime.now(), _wsUrl, 'error', data: e.toString()),
      );
    }
  }

  void _wsSendText() {
    if (!_connected) return;
    const payload = 'Hello from network_traffic_inspector!';
    _socket!.add(payload);
    // Log the outgoing message immediately after sending.
    networkDebugBus.addWs(
      WsLogEvent(DateTime.now(), _wsUrl, 'send', data: payload),
    );
  }

  void _wsSendJson() {
    if (!_connected) return;
    const payload =
        '{"event":"greeting","payload":{"text":"Hello","from":"flutter"}}';
    _socket!.add(payload);
    networkDebugBus.addWs(
      WsLogEvent(DateTime.now(), _wsUrl, 'send', data: payload),
    );
  }

  Future<void> _wsDisconnect() async {
    await _socket?.close();
    // onDone fires automatically and clears _socket.
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('network_traffic_inspector example')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const Text(
                'Tap any button, then tap the eye icon to inspect logs.',
                textAlign: TextAlign.center,
              ),

              // ── Dio ────────────────────────────────────────────────────────
              const SizedBox(height: 28),
              const _SectionHeader('Dio (HTTP)'),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: _dioPosts,
                  child: const Text('GET /posts  (200)')),
              const SizedBox(height: 8),
              FilledButton.tonal(
                  onPressed: _dioNotFound,
                  child: const Text('GET /not-found  (404)')),

              // ── package:http ───────────────────────────────────────────────
              const SizedBox(height: 28),
              const _SectionHeader('package:http'),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: _httpGet,
                  child: const Text('GET /todos/1  (200)')),
              const SizedBox(height: 8),
              FilledButton.tonal(
                  onPressed: _httpPost,
                  child: const Text('POST /posts  (201)')),

              // ── WebSocket ──────────────────────────────────────────────────
              const SizedBox(height: 28),
              const _SectionHeader('WebSocket (echo server)'),
              const SizedBox(height: 4),
              Text(
                _wsUrl,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _StatusChip(connected: _connected),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _connected ? null : _wsConnect,
                icon: const Icon(Icons.wifi),
                label: const Text('Connect'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _connected ? _wsSendText : null,
                icon: const Icon(Icons.send),
                label: const Text('Send text message'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _connected ? _wsSendJson : null,
                icon: const Icon(Icons.data_object),
                label: const Text('Send JSON message'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _connected ? _wsDisconnect : null,
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      '— $title —',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.circle,
        size: 12,
        color: connected ? Colors.green : Colors.grey,
      ),
      label: Text(connected ? 'Connected' : 'Disconnected'),
      side: BorderSide.none,
      backgroundColor: connected
          ? Colors.green.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
    );
  }
}
