import 'dart:math';
import 'package:flutter/material.dart';
import 'inspectors/debug_overlay_panel.dart';
import 'network_traffic_entry_detail.dart';
import '../network/network_debug_bus.dart';
import 'ws_entry_detail_sheet.dart';

/// Draggable floating overlay with an expandable, draggable panel.
class DraggableDebugOverlay extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final NetworkDebugBus debugBus;
  final VoidCallback? onDisable;
  /// When `false`, the overlay panel shows HTTP logs only (no WebSocket tab).
  final bool showWebSocketLogs;
  final double floatingSize;
  final Color floatingColor;
  final Color floatingIconColor;

  DraggableDebugOverlay({
    super.key,
    required this.navigatorKey,
    NetworkDebugBus? debugBus,
    this.onDisable,
    this.showWebSocketLogs = true,
    this.floatingSize = 46,
    this.floatingColor = const Color(0xFF4A4A4A),
    this.floatingIconColor = Colors.white,
  }) : debugBus = debugBus ?? networkDebugBus;

  @override
  State<DraggableDebugOverlay> createState() => _DraggableDebugOverlayState();
}

class _DraggableDebugOverlayState extends State<DraggableDebugOverlay> with SingleTickerProviderStateMixin {
  late Offset _floatingOffset;
  bool _panelVisible = false;
  bool _detailVisible = false;
  Offset _panelOffset = const Offset(12, 120);
  double _panelHeight = 360;

  static const double _panelEdgePadding = 12;
  static const double _eyeEdgePadding = 0;

  @override
  void initState() {
    super.initState();
    _floatingOffset = const Offset(0, 200);
  }

  BuildContext get _sheetContext => widget.navigatorKey.currentContext ?? context;

  Future<void> _openHttpDetail(NetworkTrafficEntry entry) async {
    setState(() {
      _panelVisible = false;
      _detailVisible = true;
    });

    final ctx = _sheetContext;
    await showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(ctx).size.height - 50.0) * 0.95,
      ),
      builder: (_) => NetworkTrafficEntryDetail(entry: entry),
    );

    if (!mounted) return;
    setState(() {
      _detailVisible = false;
    });
  }

  Future<void> _openWsDetail(WsLogEvent event) async {
    setState(() {
      _panelVisible = false;
      _detailVisible = true;
    });

    final ctx = _sheetContext;
    await showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(ctx).size.height - 50.0) * 0.95,
      ),
      builder: (_) => WsEntryDetailSheet(event: event),
    );

    if (!mounted) return;
    setState(() {
      _detailVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewPadding = MediaQuery.of(context).padding;
        final safeTop = max(_panelEdgePadding, viewPadding.top + 8);
        final eyeMaxX = constraints.maxWidth - widget.floatingSize - _eyeEdgePadding;
        final eyeMaxY = constraints.maxHeight - widget.floatingSize - _eyeEdgePadding;
        final panelMaxY = constraints.maxHeight - _panelHeight - _panelEdgePadding;
        final clamped = Offset(
          _floatingOffset.dx.clamp(_eyeEdgePadding, eyeMaxX),
          _floatingOffset.dy.clamp(safeTop, eyeMaxY),
        );
        if (clamped != _floatingOffset) {
          _floatingOffset = clamped;
        }

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const IgnorePointer(ignoring: true, child: SizedBox.expand()),
              if (_panelVisible) Positioned(
                left: _panelOffset.dx,
                top: _panelOffset.dy,
                width: constraints.maxWidth - (_panelEdgePadding * 2),
                child: _MovableOverlayPanel(
                  height: _panelHeight,
                  onDrag: (delta) {
                    setState(() {
                      final next = _panelOffset + delta;
                      _panelOffset = Offset(
                        next.dx.clamp(_panelEdgePadding, _panelEdgePadding),
                        next.dy.clamp(safeTop, panelMaxY),
                      );
                    });
                  },
                  onResize: (deltaDy) {
                    setState(() {
                      _panelHeight = (_panelHeight + deltaDy)
                          .clamp(220.0, constraints.maxHeight * 0.85);
                    });
                  },
                  onClose: () => setState(() {
                    final eyeMaxYForClose = constraints.maxHeight - widget.floatingSize - _eyeEdgePadding;
                    _floatingOffset = Offset(
                      _floatingOffset.dx,
                      _panelOffset.dy.clamp(safeTop, eyeMaxYForClose),
                    );
                    _panelVisible = false;
                    _detailVisible = false;
                  }),
                  onDisableDebug: () {
                    widget.onDisable?.call();
                    setState(() {
                      _panelVisible = false;
                      _detailVisible = false;
                    });
                  },
                  onClearLogs: widget.debugBus.clear,
                  child: DebugOverlayPanel(
                    debugBus: widget.debugBus,
                    onHttpSelect: _openHttpDetail,
                    onWsSelect: _openWsDetail,
                    showWebSocketLogs: widget.showWebSocketLogs,
                  ),
                ),
              ),
              if (!_panelVisible && !_detailVisible) Positioned(
                left: _floatingOffset.dx,
                top: _floatingOffset.dy,
                child: _FloatingButton(
                  diameter: widget.floatingSize,
                  background: widget.floatingColor,
                  iconColor: widget.floatingIconColor,
                  onTap: () {
                    setState(() {
                      final desiredTop = (_floatingOffset.dy - 60).clamp(safeTop, panelMaxY);
                      _panelOffset = Offset(_panelEdgePadding, desiredTop.toDouble());
                      _panelVisible = true;
                    });
                  },
                  onDragUpdate: (details) {
                    setState(() {
                      _floatingOffset += details.delta;
                    });
                  },
                  onDragEnd: () {
                    final shouldSnapLeft = _floatingOffset.dx < constraints.maxWidth / 2;
                    final snappedX = shouldSnapLeft
                      ? _eyeEdgePadding
                      : max(_eyeEdgePadding, eyeMaxX);
                    setState(() {
                      _floatingOffset = Offset(snappedX, _floatingOffset.dy.clamp(safeTop, eyeMaxY));
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MovableOverlayPanel extends StatelessWidget {
  final double height;
  final Widget child;
  final VoidCallback onClose;
  final ValueChanged<Offset> onDrag;
  final ValueChanged<double> onResize;
  final VoidCallback onDisableDebug;
  final VoidCallback onClearLogs;

  const _MovableOverlayPanel({
    required this.height,
    required this.child,
    required this.onClose,
    required this.onDrag,
    required this.onResize,
    required this.onDisableDebug,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => onDrag(d.delta),
      child: Material(
        color: const Color(0xF21E1E1E),
        elevation: 8,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 220, maxHeight: height),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onDisableDebug,
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'HTTP Requests',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_fullscreen, color: Colors.white70, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  ),
                ],
              ),
              Expanded(child: child),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => onResize(d.delta.dy),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: SizedBox(width: 38, height: 4),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClearLogs,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Icon(Icons.delete_outline, color: Colors.white70, size: 18),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final double diameter;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;

  const _FloatingButton({
    required this.diameter,
    required this.background,
    required this.iconColor,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onDragUpdate,
      onPanEnd: (_) => onDragEnd(),
      onTap: onTap,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: background.withValues(alpha:0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.remove_red_eye_rounded, color: iconColor),
      ),
    );
  }
}
