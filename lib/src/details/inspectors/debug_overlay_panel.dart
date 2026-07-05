import 'dart:async';

import 'package:flutter/material.dart';
import '../../network/network_debug_bus.dart';

part 'http_inspector_logs.dart';
part 'ws_inspector_logs.dart';

typedef OnHttpSelect = Future<void> Function(NetworkTrafficEntry entry);
typedef OnWsSelect = Future<void> Function(WsLogEvent event);

class DebugOverlayPanel extends StatelessWidget {
  final NetworkDebugBus debugBus;
  final OnHttpSelect onHttpSelect;
  final OnWsSelect? onWsSelect;

  /// When `false`, only HTTP logs are shown and the tab bar is hidden.
  final bool showWebSocketLogs;

  DebugOverlayPanel({
    super.key,
    NetworkDebugBus? debugBus,
    required this.onHttpSelect,
    this.onWsSelect,
    this.showWebSocketLogs = true,
  }) : debugBus = debugBus ?? networkDebugBus;

  @override
  Widget build(BuildContext context) {
    if (!showWebSocketLogs) {
      return _HttpInspectorLogs(debugBus: debugBus, onHttpSelect: onHttpSelect);
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const SizedBox(
                height: 32,
                child: TabBar(
                  dividerHeight: 0,
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.all(2),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white,
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  overlayColor: WidgetStatePropertyAll(Colors.transparent),
                  labelPadding: EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
                    Tab(child: Center(child: Text('HTTP'))),
                    Tab(child: Center(child: Text('WebSocket'))),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _HttpInspectorLogs(debugBus: debugBus, onHttpSelect: onHttpSelect),
                _WsInspectorLogs(debugBus: debugBus, onWsSelect: onWsSelect),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption<T> {
  final T value;
  final String label;

  const _FilterOption(this.value, this.label);
}

enum _HttpFilter { all, success, error }

class _FilterDropdown<T> extends StatefulWidget {
  final T value;
  final ValueChanged<T> onChanged;
  final List<_FilterOption<T>> options;

  const _FilterDropdown({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  State<_FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<_FilterDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleDropdown,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            offset: Offset(0, size.height + 4),
            showWhenUnlinked: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(minWidth: 100),
                decoration: BoxDecoration(
                  // color: Colors.black.withValues(alpha:0.95),
                  color: Color(0xF91E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.options.map((option) {
                    final isSelected = option.value == widget.value;
                    return InkWell(
                      onTap: () {
                        widget.onChanged(option.value);
                        _toggleDropdown();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSelected)
                              const Icon(Icons.check, size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.options.firstWhere((o) => o.value == widget.value).label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const _LogSearchField({required this.controller, this.hintText = 'Search'});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 6, right: 2),
          child: Icon(Icons.search, color: Colors.white54, size: 14),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 24,
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white70),
        ),
      ),
    );
  }
}

enum _WsFilter { all, success, error }
