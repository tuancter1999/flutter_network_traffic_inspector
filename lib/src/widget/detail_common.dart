import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugSectionTitle extends StatelessWidget {
  final String title;
  const DebugSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class DebugCodeBlock extends StatefulWidget {
  final String text;
  final String filter;
  const DebugCodeBlock({super.key, required this.text, this.filter = ''});

  @override
  State<DebugCodeBlock> createState() => _DebugCodeBlockState();
}

class _DebugCodeBlockState extends State<DebugCodeBlock> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 800),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: RawScrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            interactive: true,
            thumbColor: Colors.white38,
            radius: const Radius.circular(8),
            thickness: 6,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(right: 10),
              child: SelectableText.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Color(0xFFB8F0CF),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  children: _highlight(widget.text, widget.filter),
                ),
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar.editableText(
                    editableTextState: editableTextState,
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.text));
            },
          ),
        ),
      ],
    );
  }

  List<TextSpan> _highlight(String source, String query) {
    if (query.isEmpty) return [TextSpan(text: source)];
    final spans = <TextSpan>[];
    final lowerSource = source.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    while (true) {
      final index = lowerSource.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: source.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: source.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: source.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFFF00),
            color: Colors.black,
          ),
        ),
      );
      start = index + query.length;
    }
    return spans;
  }
}
