import 'package:flutter/material.dart';

import 'network/network_debug_bus.dart';

typedef OnHttpSelect = Future<void> Function(NetworkLogEntry entry);
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
      return _HttpLogsView(debugBus: debugBus, onHttpSelect: onHttpSelect);
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
                  labelStyle: TextStyle(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
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
                _HttpLogsView(debugBus: debugBus, onHttpSelect: onHttpSelect),
                _WsLogsView(debugBus: debugBus, onWsSelect: onWsSelect),
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

class _HttpLogsView extends StatelessWidget {
  final NetworkDebugBus debugBus;
  final OnHttpSelect onHttpSelect;
  const _HttpLogsView({required this.debugBus, required this.onHttpSelect});

  @override
  Widget build(BuildContext context) {
    return _HttpLogsStyledList(debugBus: debugBus, onHttpSelect: onHttpSelect);
  }
}

enum _HttpFilter { all, success, error }

class _HttpLogsStyledList extends StatefulWidget {
  final NetworkDebugBus debugBus;
  final OnHttpSelect onHttpSelect;
  const _HttpLogsStyledList({required this.debugBus, required this.onHttpSelect});

  @override
  State<_HttpLogsStyledList> createState() => _HttpLogsStyledListState();
}

class _HttpLogsStyledListState extends State<_HttpLogsStyledList> {
  _HttpFilter _filter = _HttpFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _FilterDropdown<_HttpFilter>(
                value: _filter,
                onChanged: (value) {
                  setState(() => _filter = value);
                },
                options: const [
                  _FilterOption(_HttpFilter.all, 'All'),
                  _FilterOption(_HttpFilter.success, 'Success'),
                  _FilterOption(_HttpFilter.error, 'Error'),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LogSearchField(
                  controller: _searchController,
                  hintText: 'Search URL',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.debugBus,
            builder: (context, _) {
              final filtered = widget.debugBus.http.where((e) {
                final status = e.response?.statusCode;
                bool match = true;
                switch (_filter) {
                  case _HttpFilter.all:
                    match = true;
                    break;
                  case _HttpFilter.success:
                    match = status != null && status >= 200 && status < 400;
                    break;
                  case _HttpFilter.error:
                    match = e.hasError;
                    break;
                }
                if (!match) return false;
                if (_searchText.isEmpty) return true;
                final url = e.request.uri.toString().toLowerCase();
                return url.contains(_searchText);
              }).toList();
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No HTTP logs', style: TextStyle(color: Colors.white70)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemBuilder: (_, i) => Theme(
                  data: Theme.of(context).copyWith(
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                  child: _HttpLogTile(entry: filtered[i], onTap: widget.onHttpSelect),
                ),
                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                itemCount: filtered.length,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HttpLogTile extends StatelessWidget {
  final NetworkLogEntry entry;
  final OnHttpSelect onTap;
  const _HttpLogTile({required this.entry, required this.onTap});

  Color _statusColor(int? status, bool hasError) {
    if (hasError) return Colors.redAccent;
    if (status == null) return Colors.white70;
    if (status >= 200 && status < 300) return Colors.greenAccent;
    if (status >= 300 && status < 400) return Colors.lightBlueAccent;
    if (status >= 400 && status < 500) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final method = entry.request.method;
    final url = entry.request.uri.toString();
    final status = entry.statusCode;
    final hasError = entry.hasError;
    final color = _statusColor(status, hasError);
    final durationMs = entry.durationMs;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Row(
        children: [
          _pill(method, Colors.deepPurpleAccent),
          const SizedBox(width: 6),
          _pill(status?.toString() ?? (hasError ? 'ERR' : '...'), color),
          if (durationMs != null) ...[
            const SizedBox(width: 6),
            _pill('${durationMs}ms', Colors.white70),
          ],
        ],
      ),
      subtitle: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
      onTap: () => onTap(entry),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.2),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

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
                  color: Colors.black.withValues(alpha:0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
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
          padding: EdgeInsets.only(left: 4, right: 2),
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

class _WsLogsView extends StatefulWidget {
  final NetworkDebugBus debugBus;
  final OnWsSelect? onWsSelect;
  const _WsLogsView({required this.debugBus, this.onWsSelect});

  @override
  State<_WsLogsView> createState() => _WsLogsViewState();
}

class _WsLogsViewState extends State<_WsLogsView> {
  _WsFilter _filter = _WsFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _FilterDropdown<_WsFilter>(
                value: _filter,
                onChanged: (value) {
                  setState(() => _filter = value);
                },
                options: const [
                  _FilterOption(_WsFilter.all, 'All'),
                  _FilterOption(_WsFilter.success, 'Success'),
                  _FilterOption(_WsFilter.error, 'Error'),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LogSearchField(
                  controller: _searchController,
                  hintText: 'Search URL / Data',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: AnimatedBuilder(
          animation: widget.debugBus,
          builder: (context, _) {
            final items = widget.debugBus.ws.where((e) {
              final matchesStatus = switch (_filter) {
                _WsFilter.all => true,
                _WsFilter.success => e.type != 'error',
                _WsFilter.error => e.type == 'error',
              };
              if (!matchesStatus) return false;

              if (_searchText.isEmpty) return true;
              final url = e.url.toLowerCase();
              final data = e.data?.toString().toLowerCase() ?? '';
              return url.contains(_searchText) || data.contains(_searchText);
            }).toList();
            if (items.isEmpty) {
              return const Center(child: Text('No WS logs', style: TextStyle(color: Colors.white70)));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemBuilder: (_, i) {
                final e = items[i];
                final Color typeColor = _wsTypeColor(e.type);
                return Theme(
                  data: Theme.of(context).copyWith(
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Row(
                      children: [
                        _pill(e.type.toUpperCase(), typeColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    subtitle: e.data != null
                        ? Text(
                            '${e.data}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54),
                          )
                        : null,
                    onTap: () async {
                      if (widget.onWsSelect != null) {
                        await widget.onWsSelect!(e);
                      }
                    },
                  ),
                );
              },
                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                itemCount: items.length,
              );
            },
          ),
        ),
      ],
    );
  }

  Color _wsTypeColor(String type) {
    switch (type) {
      case 'send':
        return Colors.orangeAccent;
      case 'recv':
        return Colors.lightBlueAccent;
      case 'connect':
        return Colors.greenAccent;
      case 'close':
        return Colors.white70;
      case 'error':
        return Colors.redAccent;
      case 'sub':
        return Colors.purpleAccent;
      case 'unsub':
        return Colors.pinkAccent;
      default:
        return Colors.white70;
    }
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.2),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 10),
      ),
    );
  }
}

