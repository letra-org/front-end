import 'package:flutter/material.dart';

class SponsorsScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const SponsorsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
                      onPressed: () => onNavigate('settings'),
                    ),
                    const Text(
                      'Nhà tài trợ',
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Text(
                  'Cảm ơn các nhà tài trợ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Dự án được hỗ trợ bởi các đối tác và nhà tài trợ tin tưởng vào tầm nhìn phát triển du lịch Việt Nam.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
