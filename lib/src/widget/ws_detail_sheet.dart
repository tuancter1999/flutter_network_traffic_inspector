import 'dart:convert';

import 'package:flutter/material.dart';

import '../network/network_debug_bus.dart';
import 'detail_common.dart';

class WsDetailSheet extends StatefulWidget {
  final WsLogEvent event;
  const WsDetailSheet({super.key, required this.event});

  @override
  State<WsDetailSheet> createState() => _WsDetailSheetState();
}

class _WsDetailSheetState extends State<WsDetailSheet> {
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
              DebugCodeBlock(text: _toPrettyJson(info), filter: ''),
              const SizedBox(height: 16),
              const DebugSectionTitle('Data'),
              DebugCodeBlock(text: _toPrettyJson(e.originalData ?? e.data), filter: ''),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

String _toPrettyJson(dynamic data) {
  if (data == null) return '{}';
  try {
    if (data is String) {
      final decoded = jsonDecode(data);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    }
    if (data is Map || data is List) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return data.toString();
  } catch (_) {
    return data.toString();
  }
}
