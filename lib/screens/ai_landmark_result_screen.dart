import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiLandmarkResultScreen extends StatelessWidget {
  final Function(String) onNavigate;
  final String markdownContent;

  const AiLandmarkResultScreen({
    super.key,
    required this.onNavigate,
    required this.markdownContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF2563EB),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => onNavigate('camera'), // Quay lại màn hình camera
                    ),
                    const Text(
                      'Thông tin địa danh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Markdown(
              data: markdownContent,
              padding: const EdgeInsets.all(16.0),
              styleSheet: MarkdownStyleSheet(
                h3: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                p: const TextStyle(fontSize: 16, height: 1.5),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                listBullet: const TextStyle(fontSize: 16),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: const Border(left: BorderSide(color: Colors.blue, width: 5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
