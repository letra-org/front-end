import 'package:flutter/material.dart';

class TeamScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const TeamScreen({super.key, required this.onNavigate});

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
                      'Đội ngũ phát triển',
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
                  'Đội ngũ phát triển Letra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Ứng dụng được phát triển bởi đội ngũ tận tâm với sứ mệnh kết nối du khách và khám phá vẻ đẹp Việt Nam.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
