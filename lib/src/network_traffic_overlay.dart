import 'package:flutter/material.dart';
import 'details/draggable_debug_overlay.dart';

/// Inserts a floating overlay into the navigator overlay when [enabled].
///
/// [navigatorKey] must be the same key assigned to your app's
/// `MaterialApp.navigatorKey`, so this widget can locate that Navigator's
/// Overlay — and so [DraggableDebugOverlay] can push bottom sheets via that
/// same Navigator (`showModalBottomSheet` requires a context that is a
/// descendant of a real `Navigator`; a bare `Overlay` is not enough):
///
/// ```dart
/// final navigatorKey = GlobalKey<NavigatorState>();
///
/// MaterialApp(
///   navigatorKey: navigatorKey,
///   builder: (context, child) => NetworkTrafficOverlay(
///     enabled: kDebugMode,
///     navigatorKey: navigatorKey,
///     child: child,
///   ),
/// );
/// ```
class NetworkTrafficOverlay extends StatefulWidget {
  final bool enabled;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget? child;

  const NetworkTrafficOverlay({
    super.key,
    required this.enabled,
    required this.navigatorKey,
    required this.child,
  });

  @override
  State<NetworkTrafficOverlay> createState() => _NetworkTrafficOverlayState();
}

class _NetworkTrafficOverlayState extends State<NetworkTrafficOverlay> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOverlay(widget.enabled);
    });
  }

  @override
  void didUpdateWidget(NetworkTrafficOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _refreshOverlay(widget.enabled);
    } else if (widget.enabled) {
      _markOverlayNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox();

  void _insertOverlay() {
    if (_overlayEntry != null) return; // skip when overlay entry is displayed
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _overlayEntry = OverlayEntry(
      builder: (c) => DraggableDebugOverlay(
        navigatorKey: widget.navigatorKey,
        // Enable the WebSocket tab in the overlay panel.
        showWebSocketLogs: true,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _refreshOverlay(bool enabled) {
    if (enabled) {
      _insertOverlay();
    } else {
      _removeOverlay();
    }
  }
}
