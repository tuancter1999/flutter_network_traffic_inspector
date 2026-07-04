import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'network/network_debug_bus.dart';
import 'widget/detail_common.dart';

class HttpRequestDetailSheet extends StatefulWidget {
  final NetworkLogEntry entry;
  const HttpRequestDetailSheet({super.key, required this.entry});

  @override
  State<HttpRequestDetailSheet> createState() => _HttpRequestDetailSheetState();
}

class _HttpRequestDetailSheetState extends State<HttpRequestDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final status = entry.statusCode;
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final endTime = entry.durationMs != null
        ? entry.time.add(Duration(milliseconds: entry.durationMs!))
        : null;
    final info = {
      'Method': entry.request.method,
      'Status Code': status?.toString() ?? '--',
      'Duration (ms)': entry.durationMs?.toString() ?? '--',
      'URL': entry.request.uri.toString(),
      'Start Time': formatter.format(entry.time.toLocal()),
      if (endTime != null) 'End Time': formatter.format(endTime.toLocal()),
    };

    final requestHeaders = entry.request.headers;
    final requestData = entry.request.body;
    final responseData = entry.response?.body;
    final errorData = entry.errorBody ?? entry.errorMessage;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 18),
              const Text('HTTP Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              const DebugSectionTitle('Request Header'),
              DebugCodeBlock(text: _toPrettyJson(requestHeaders), filter: ''),
              const SizedBox(height: 16),
              const DebugSectionTitle('Request Body'),
              DebugCodeBlock(text: _toPrettyJson(requestData), filter: ''),
              const SizedBox(height: 16),
              const DebugSectionTitle('Response'),
              DebugCodeBlock(text: _toPrettyJson(responseData), filter: ''),
              if (errorData != null) ...[
                const SizedBox(height: 16),
                const DebugSectionTitle('Error'),
                DebugCodeBlock(text: _toPrettyJson(errorData), filter: ''),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  static String _toPrettyJson(dynamic data) {
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
}
