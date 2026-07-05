import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/detail_common.dart';
import '../network/network_debug_bus.dart';
import '../helpers/network_traffic_helper.dart';

class NetworkTrafficEntryDetail extends StatefulWidget {
  final NetworkTrafficEntry entry;

  const NetworkTrafficEntryDetail({super.key, required this.entry});

  @override
  State<NetworkTrafficEntryDetail> createState() => _NetworkTrafficEntryDetailState();
}

class _NetworkTrafficEntryDetailState extends State<NetworkTrafficEntryDetail> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 18),
          const Text(
            'HTTP Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const DebugSectionTitle('Info'),
        DebugCodeBlock(text: NetworkTrafficHelper.toPrettyJson(info), filter: ''),
        const SizedBox(height: 12),
        const DebugSectionTitle('Request Header'),
        DebugCodeBlock(text: NetworkTrafficHelper.toPrettyJson(requestHeaders), filter: ''),
        const SizedBox(height: 12),
        const DebugSectionTitle('Request Body'),
        DebugCodeBlock(text: NetworkTrafficHelper.toPrettyJson(requestData), filter: ''),
        const SizedBox(height: 12),
        const DebugSectionTitle('Response'),
        DebugCodeBlock(text: NetworkTrafficHelper.toPrettyJson(responseData), filter: ''),
        if (errorData != null) ...[
          const SizedBox(height: 12),
          const DebugSectionTitle('Error'),
          DebugCodeBlock(text: NetworkTrafficHelper.toPrettyJson(errorData), filter: ''),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
