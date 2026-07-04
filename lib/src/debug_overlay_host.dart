import 'package:flutter/material.dart';

/// Inserts a floating [overlayBuilder] into the navigator overlay when [enabled].
class DebugOverlayHost extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetBuilder overlayBuilder;

  const DebugOverlayHost({
    super.key,
    required this.child,
    required this.enabled,
    required this.navigatorKey,
    required this.overlayBuilder,
  });

  @override
  State<DebugOverlayHost> createState() => _DebugOverlayHostState();
}

class _DebugOverlayHostState extends State<DebugOverlayHost> {
  OverlayEntry? _entry;

  void _insertOverlay() {
    if (_entry != null) return;
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _insertOverlay());
      return;
    }
    _entry = OverlayEntry(
      builder: (context) => widget.overlayBuilder(context),
    );
    overlay.insert(_entry!);
  }

  void _markOverlayNeedsBuild() {
    _entry?.markNeedsBuild();
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _refreshOverlay(bool enabled) {
    if (enabled) {
      _insertOverlay();
    } else {
      _removeOverlay();
    }
  }

  @override
  void didUpdateWidget(DebugOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _refreshOverlay(widget.enabled);
    } else if (widget.enabled) {
      _markOverlayNeedsBuild();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshOverlay(widget.enabled);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}
