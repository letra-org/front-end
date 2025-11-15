import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const AppInfoScreen({super.key, required this.onNavigate});

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
                      'Thông tin ứng dụng',
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
                Center(
                  child: Text(
                    'Letra',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Center(child: Text('Phiên bản 1.0.0')),
                SizedBox(height: 32),
                Text(
                  'Về Letra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Letra là ứng dụng du lịch Việt Nam giúp bạn khám phá và chia sẻ những điểm đến tuyệt vời trên khắp đất nước.',
                ),
                SizedBox(height: 24),
                Text(
                  '© 2024 Letra. All rights reserved.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
