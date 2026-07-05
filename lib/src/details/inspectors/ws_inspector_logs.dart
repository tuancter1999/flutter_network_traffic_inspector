part of 'debug_overlay_panel.dart';

class _WsInspectorLogs extends StatefulWidget {
  final NetworkDebugBus debugBus;
  final OnWsSelect? onWsSelect;
  const _WsInspectorLogs({required this.debugBus, this.onWsSelect});

  @override
  State<_WsInspectorLogs> createState() => __WsInspectorLogsState();
}

class __WsInspectorLogsState extends State<_WsInspectorLogs> {
  _WsFilter _filter = _WsFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        _buildFilterHeader(),
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
              return _buildList(items);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Padding(
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
    );
  }

  Widget _buildList(List<WsLogEvent> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No WS logs',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemBuilder: (_, i) {
        final e = items[i];
        final Color typeColor = _wsTypeColor(e.type);
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          title: Row(
            children: [
              _pill(e.type.toUpperCase(), typeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: e.data != null ? Text(
            '${e.data}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w400),
          ) : null,
          onTap: () async {
            if (widget.onWsSelect != null) {
              await widget.onWsSelect!(e);
            }
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
      itemCount: items.length,
    );
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

  void _onSearchChange() {
    setState(() {
      _searchText = _searchController.text.trim().toLowerCase();
    });
  }
}
