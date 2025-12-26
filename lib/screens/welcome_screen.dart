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
    final screenWidth = MediaQuery.of(context).size.width;

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
              Color(0xFF1E88E5),
              Color(0xFF1E88E5),
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
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
                          width: screenWidth * 0.45,
                          height: screenWidth * 0.45,
                        ),

                        // Chữ Letra
                        Positioned(
                          bottom: 5,
                          child: Text(
                            'Letra',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenHeight * 0.05,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              shadows: const [
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

                    SizedBox(height: screenHeight * 0.04),

                    // Slogan
                    Text(
                      'Khám phá Việt Nam\n'
                          'Chẳng ngại gian nan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    // Khoảng trống linh hoạt trước nút
                    const Spacer(flex: 3),

                    // NÚT ĐĂNG NHẬP
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: ElevatedButton(
                        onPressed: onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E88E5),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenHeight * 0.02),
                          ),
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                        ),
                        child: Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: screenHeight * 0.022,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04), // Padding dưới cùng
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
