import 'package:flutter/material.dart';
import 'dart:ui'; // Cần thiết để sử dụng BackdropFilter

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onLogin;

  const WelcomeScreen({
    super.key,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Nền: Gradient + Ảnh + Lớp phủ màu xanh đậm (Overlay)
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF1D4ED8),
            ],
          ),
          image: DecorationImage(
            image: const NetworkImage(
              'https://invietnhat.vn/wp-content/uploads/2024/12/background-anh-sang-xanh.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              // LÀM BẠC MÀU HƠN: Sử dụng màu đen mờ (alpha 100) để giảm bão hòa
              Colors.black.withAlpha(100),
              BlendMode.overlay,
            ),
          ),
        ),
        child: Stack(
          children: [
            // 1. BACKDROP FILTER: LÀM MỜ NỀN
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: Colors.black.withAlpha(0), // Container trong suốt để áp dụng filter
              ),
            ),

            // 2. LỚP PHỦ MỜ (FULL SCREEN) - Thay thế cho Card Container cũ
            Container(
              width: double.infinity,
              height: double.infinity,
              // MÀU NỀN TRẮNG/XANH RẤT TRONG SUỐT CHO TOÀN BỘ MÀN HÌNH
              // Sử dụng một màu xanh mờ nhẹ hoặc trắng mờ để làm nổi bật nội dung
              color: const Color(0xFFE0F7FA).withAlpha((255*0.05).toInt()),
            ),

            // 3. NỘI DUNG CHÍNH (Được căn giữa trên lớp phủ mờ)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  // Căn nội dung vào giữa theo chiều dọc
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Khoảng trống linh hoạt từ trên xuống
                    const Spacer(flex: 2),

                    // --- STACK TÍCH HỢP LOGO VÀ TEXT ---
                    Stack(
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
                    // --- KẾT THÚC STACK ---

                    const SizedBox(height: 32),

                    // Slogan
                    const Text(
                      'Khám phá Việt Nam\n'
                          'Chẳng ngại gian nan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    // Khoảng trống linh hoạt trước nút
                    const Spacer(flex: 3),

                    // NÚT ĐĂNG NHẬP
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2563EB),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32), // Padding dưới cùng
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}