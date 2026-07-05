# network_traffic_inspector

A draggable, floating HTTP & WebSocket debug overlay for Flutter apps.  
Inspect live network traffic directly on device — no proxy or desktop tool required.

---

## Features

- 🔍 **Live HTTP log** — method, status, duration, URL, request/response body
- 🔌 **WebSocket log** — connect, send, recv, close, error events
- 🖱️ **Draggable & resizable** panel that snaps to screen edges
- 🔎 **Filter & search** logs by status (success / error) and URL keyword
- 📋 **Copy** any request/response body to clipboard
- 🛑 **Disable** overlay from within the panel
- ⚡ Zero build-time code-gen required

---

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  network_traffic_inspector: ^1.0.0
```

---

## Usage

### 1. Wrap your navigator with `DebugOverlayHost`

```dart
import 'package:network_traffic_inspector/network_traffic_inspector.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const HomePage(),
      builder: (context, child) => DebugOverlayHost(
        enabled: kDebugMode,          // show only in debug builds
        navigatorKey: navigatorKey,
        child: child,
      ),
    );
  }
}
```

### 2. Add `DebugLogInterceptor` to Dio

```dart
import 'package:network_traffic_inspector/network_traffic_inspector.dart';

final dio = Dio();

if (kDebugMode) {
  dio.interceptors.add(DebugLogInterceptor());
}
```

### 3. Log WebSocket events (optional)

```dart
import 'package:network_traffic_inspector/network_traffic_inspector.dart';

// anywhere you open / receive / close a WebSocket:
networkDebugBus.addWs(WsLogEvent(DateTime.now(), url, 'connect'));
networkDebugBus.addWs(WsLogEvent(DateTime.now(), url, 'recv', data: payload));
networkDebugBus.addWs(WsLogEvent(DateTime.now(), url, 'close'));
```

---

## API reference

| Class / symbol | Description |
|---|---|
| `DebugOverlayHost` | Inserts the overlay into the navigator's `Overlay` |
| `DraggableDebugOverlay` | The floating eye-button + resizable log panel |
| `DebugOverlayPanel` | The tabbed HTTP / WebSocket log list (embeddable) |
| `DebugLogInterceptor` | Dio interceptor that feeds requests into `NetworkDebugBus` |
| `NetworkDebugBus` | In-memory log store; extends `ChangeNotifier` |
| `networkDebugBus` | Global singleton (override in tests) |
| `NetworkLogEntry` | HTTP request/response snapshot |
| `WsLogEvent` | Single WebSocket event |

---

## Additional information

- The overlay is completely removed from the widget tree when `enabled = false`.
- `NetworkDebugBus` caps HTTP logs at **80** entries and WebSocket logs at **250** entries (oldest dropped first).
- Ping/pong frames are filtered out automatically.
