import 'package:flutter/material.dart';
import '../network/network_debug_bus.dart';
import '../helpers/network_traffic_helper.dart';
import 'widgets/detail_common.dart';

class WsEntryDetailSheet extends StatefulWidget {
  final WsLogEvent event;
  const WsEntryDetailSheet({super.key, required this.event});

  @override
  State<WsEntryDetailSheet> createState() => _WsEntryDetailSheetState();
}

class _WsEntryDetailSheetState extends State<WsEntryDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final info = <String, String>{
      'Type': e.type.toUpperCase(),
      'URL': e.url,
      'Time': widget.event.time.toLocal().toString(),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 18),
              const Text('WebSocket Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const DebugSectionTitle('Info'),
              DebugCodeBlock(text: NetworkTrafficHelper.toPrettyJson(info), filter: ''),
              const SizedBox(height: 16),
              const DebugSectionTitle('Data'),
              DebugCodeBlock(text: NetworkTrafficHelper.toPrettyJson(e.originalData ?? e.data), filter: ''),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
