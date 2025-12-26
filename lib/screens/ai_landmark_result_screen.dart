import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AiLandmarkResultScreen extends StatelessWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;
  final String markdownContent;
  final String? from;

  const AiLandmarkResultScreen({
    super.key,
    required this.onNavigate,
    required this.markdownContent,
    this.from,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF1E88E5),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => onNavigate('home'),
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
              onTapLink: (text, href, title) {
                if (href != null) {
                  _launchUrl(href);
                }
              },
              styleSheet: MarkdownStyleSheet(
                h3: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                p: const TextStyle(fontSize: 16, height: 1.5),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                listBullet: const TextStyle(fontSize: 16, height: 1.5),
                blockquote: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: const Border(left: BorderSide(color: Colors.blue, width: 5)),
                  borderRadius: BorderRadius.circular(4)
                ),
                blockquotePadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
