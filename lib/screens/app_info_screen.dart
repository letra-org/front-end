import 'package:flutter/material.dart';
// import 'dart:ui'; // Không cần thiết

class AppInfoScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const AppInfoScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Bar
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
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  // Sửa lỗi cú pháp: Stack không thể là const do Image.asset
                  child: Stack( 
                    alignment: Alignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: 180,
                        height: 180,
                      ),

                      // Chữ Letra
                      const Positioned(
                        bottom: 5,
                        child: Text(
                          'Letra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black54,
                                offset: Offset(0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ), // Thiếu dấu phẩy ở đây
                
                const SizedBox(height: 8),
                const Center(child: Text('Phiên bản 1.0.0')),
                const SizedBox(height: 32),
                const Text(
                  'Về Letra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Letra là ứng dụng du lịch Việt Nam giúp bạn khám phá và chia sẻ những điểm đến tuyệt vời trên khắp đất nước.',
                ),
                const SizedBox(height: 24),
                const Text(
                  '© 2025 Letra. All rights reserved.',
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