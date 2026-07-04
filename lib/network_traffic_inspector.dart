/// A draggable, floating HTTP & WebSocket debug overlay for Flutter apps.
///
/// Usage:
/// ```dart
/// // 1. Wrap your app's navigator with DebugOverlayHost
/// DebugOverlayHost(
///   enabled: isDebugMode,
///   navigatorKey: navigatorKey,
///   overlayBuilder: (_) => DraggableDebugOverlay(navigatorKey: navigatorKey),
///   child: child,
/// );
///
/// // 2. Add DebugLogInterceptor to Dio
/// dio.interceptors.add(DebugLogInterceptor());
/// ```
library network_traffic_inspector;

export 'src/debug_overlay_host.dart';
export 'src/draggable_debug_overlay.dart';
export 'src/debug_overlay_panel.dart';
export 'src/network/network_debug_bus.dart';
export 'src/http_request_detail_sheet.dart';
export 'src/widget/ws_detail_sheet.dart';
export 'src/widget/detail_common.dart';
export 'src/dio_interceptor.dart';
export 'src/http_client.dart';
