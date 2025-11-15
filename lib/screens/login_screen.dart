import 'package:flutter/material.dart';
import 'dart:ui'; // Cần thiết cho BackdropFilter
import 'dart:io'; // Thư viện để làm việc với File và Directory
import 'package:path_provider/path_provider.dart'; // Thư viện để lấy đường dẫn hệ thống

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onNavigateToRegister;
  final VoidCallback onNavigateToForgotPassword;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onNavigateToRegister,
    required this.onNavigateToForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Dùng state để quản lý trạng thái hiển thị/ẩn mật khẩu
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC LƯU FILE ---

  // Hàm 1: Trả về đối tượng File với đường dẫn tuyệt đối (bao gồm cấu trúc tương đối 'data/userdata.txt')
  Future<File> get _localFile async {
    // Lấy thư mục Document của ứng dụng (đường dẫn cơ sở)
    final directory = await getApplicationDocumentsDirectory();

    // TẠO THƯ MỤC 'data' theo yêu cầu relative path
    final dataDir = Directory('${directory.path}/data');
    if (!await dataDir.exists()) {
      // Tạo thư mục nếu nó chưa tồn tại
      await dataDir.create(recursive: true);
    }

    // Trả về đối tượng File với đường dẫn: [DocumentPath]/data/userdata.txt
    final path = '${dataDir.path}/userdata.txt';
    return File(path);
  }

  // Hàm 2: Lưu dữ liệu vào file
  Future<File> _saveData(String data) async {
    final file = await _localFile;

    // Viết dữ liệu vào file (sử dụng writeAsString để ghi đè nội dung cũ)
    return file.writeAsString(data);
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      // Định dạng dữ liệu cần lưu
      final dataToSave = 'Tài khoản: $username, Mật khẩu: $password\n';

      // GỌI HÀM LƯU FILE
      _saveData(dataToSave).then((file) {
        // Kiểm tra mounted trước khi sử dụng context để đảm bảo widget vẫn còn tồn tại
        if (!mounted) return;

        // Hiển thị thông báo sau khi lưu thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu dữ liệu vào: ${file.path}',
              style: const TextStyle(color: Color(0xFF1D4ED8)),
            ),
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }).catchError((e) {
        // Kiểm tra mounted trước khi sử dụng context
        if (!mounted) return;

        // Xử lý lỗi nếu có
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu file: $e')),
        );
      });

      // Chuyển sang màn hình tiếp theo
      widget.onLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tăng cường thẩm mỹ bằng cách thêm hình ảnh nền mờ nhẹ
    const backgroundImage = NetworkImage(
        'https://images.unsplash.com/photo-1603269231725-4ea1da7d02fd?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1031');

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF1D4ED8),
            ],
          ),
          image: DecorationImage(
            image: backgroundImage,
            fit: BoxFit.cover,
            // Giảm độ bão hòa và độ sáng của nền để card nổi bật hơn
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha((255 * 0.3).toInt()),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Lớp mờ nhẹ cho nền (Backdrop Blur)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(color: Colors.black.withAlpha(0)),
            ),

            // Nội dung chính
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tiêu đề
                      const Text(
                        'Chào mừng trở lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(blurRadius: 5, color: Colors.black38)
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Avatar
                      Container(
                        width: 100, // Giảm nhẹ kích thước avatar
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                              53), // Nền trắng trong suốt
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(127),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                  (255 * 0.3).toInt()),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline, // Icon outline hiện đại hơn
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40), // Tăng khoảng cách

                      // --- FORM CARD (Kích thước cố định và hiệu ứng trong suốt) ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                              (255 * 0.15).toInt()), // Nền form trong suốt
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha(
                                (255 * 0.4).toInt()),
                            width: 1,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username Label
                              _buildLabel('Tài khoản'),
                              const SizedBox(height: 8),
                              // Username Field
                              _buildTextField(
                                controller: _usernameController,
                                hintText: 'Nhập tên đăng nhập hoặc Email',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 20),

                              // Password Label
                              _buildLabel('Mật khẩu'),
                              const SizedBox(height: 8),
                              // Password Field
                              _buildPasswordField(),
                              const SizedBox(height: 30),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(
                                        0xFF1D4ED8), // Màu xanh đậm
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          12), // Bo góc hơn
                                    ),
                                  ),
                                  child: const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 18, // Font lớn hơn
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // --- KẾT THÚC FORM CARD ---

                      const SizedBox(height: 20), // Giảm khoảng cách

                      // Quên mật khẩu & Đăng ký (Bên ngoài Card)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Forgot Password
                          TextButton(
                            onPressed: widget.onNavigateToForgotPassword,
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),

                          // Register Button (Dùng TextButton gọn gàng hơn)
                          TextButton(
                            onPressed: widget.onNavigateToRegister,
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color:
                                    Color(0xFF93C5FD), // Màu xanh nhạt nổi bật
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30), // Padding cuối
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets để làm sạch hàm build() ---

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600, // Đậm hơn
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: hintText.contains('Email')
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: const TextStyle(color: Color(0xFF1D4ED8)), // Màu chữ xanh đậm
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF93C5FD)),
        filled: true,
        fillColor: Colors.white, // Nền field là trắng
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Bo góc nhẹ
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF1D4ED8), width: 2), // Focus border xanh đậm
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(color: Color(0xFF1D4ED8)),
      decoration: InputDecoration(
        hintText: 'Nhập mật khẩu',
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF93C5FD)),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF93C5FD),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập mật khẩu';
        }
        return null;
      },
    );
  }
}