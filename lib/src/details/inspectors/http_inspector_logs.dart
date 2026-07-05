part of 'debug_overlay_panel.dart';

class _HttpInspectorLogs extends StatefulWidget {
  final NetworkDebugBus debugBus;
  final OnHttpSelect onHttpSelect;
  const _HttpInspectorLogs({super.key, required this.debugBus, required this.onHttpSelect});

  @override
  State<_HttpInspectorLogs> createState() => _HttpInspectorLogsState();
}

class _HttpInspectorLogsState extends State<_HttpInspectorLogs> {
  final TextEditingController _searchController = TextEditingController();
  _HttpFilter _filter = _HttpFilter.all;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onChangeSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onChangeSearch);
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
              return _buildList(filtered);
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
    );
  }

  Widget _buildList(List<NetworkTrafficEntry> filtered) {
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No HTTP logs',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemBuilder: (_, i) => _HttpLogTile(entry: filtered[i], onTap: widget.onHttpSelect),
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
      itemCount: filtered.length,
    );
  }

  void _onChangeSearch() {
    setState(() {
      _searchText = _searchController.text.trim().toLowerCase();
    });
  }
}

class _HttpLogTile extends StatelessWidget {
  final NetworkTrafficEntry entry;
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
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
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
      subtitle: Text(
        url,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
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
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
