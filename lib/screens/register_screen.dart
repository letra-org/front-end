import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegister;
  final VoidCallback onBackToLogin;

  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onBackToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final username = _usernameController.text;
      final fullName = _fullNameController.text;
      final email = _emailController.text;
      final phone = _phoneController.text;
      final password = _passwordController.text;

      final formattedPhone = '+84${phone.startsWith('0') ? phone.substring(1) : phone}';

      final url = Uri.parse(ApiConfig.create);

      try {
        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode({
                'email': email,
                'username': username,
                'password': password,
                'full_name': fullName,
                'phone': formattedPhone,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onBackToLogin();
        } else {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          String detailMessage = 'Đã xảy ra lỗi không xác định.';

          final detail = errorData['detail'];
          if (detail != null) {
            if (detail is String) {
              detailMessage = detail;
            } else if (detail is List && detail.isNotEmpty) {
              detailMessage = detail.map((error) {
                if (error is Map && error.containsKey('msg')) {
                  return error['msg'].toString();
                }
                return error.toString();
              }).join('\n');
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng ký thất bại:\n$detailMessage', maxLines: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối đến máy chủ. Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D4ED8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBackToLogin,
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    tooltip: 'Quay lại',
                  ),
                  const Text(
                    'Tạo tài khoản',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('Tên người dùng'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: _buildInputDecoration(hintText: 'Ví dụ: user123', icon: Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Vui lòng nhập tên người dùng';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Họ và tên'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: _buildInputDecoration(hintText: 'Ví dụ: Nguyễn Văn A', icon: Icons.badge_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Vui lòng nhập họ tên của bạn';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(hintText: 'email@example.com', icon: Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email không được để trống';
                            final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                            if (!emailRegex.hasMatch(value)) return 'Email không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Số điện thoại'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(hintText: 'Ví dụ: 0912345678', icon: Icons.phone_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Số điện thoại không được để trống';
                            final phoneRegex = RegExp(r'^0[0-9]{9}$');
                            if (!phoneRegex.hasMatch(value)) return 'Số điện thoại không hợp lệ (gồm 10 số)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Mật khẩu'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _buildInputDecoration(hintText: 'Nhập mật khẩu của bạn', icon: Icons.lock_outline),
                          validator: (value) {
                            if (value == null || value.length < 12) return 'Mật khẩu phải có ít nhất 12 ký tự';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Xác nhận mật khẩu'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: _buildInputDecoration(hintText: 'Nhập lại mật khẩu', icon: Icons.lock_person_outlined),
                          validator: (value) {
                            if (value != _passwordController.text) return 'Mật khẩu không khớp';
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E40AF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)))
                                : const Text('Đăng ký', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: widget.onBackToLogin,
                            child: Text(
                              'Đã có tài khoản? Đăng nhập ngay',
                              style: TextStyle(color: Colors.white.withAlpha((255*0.9).toInt()), fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: Colors.white, size: 22),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      errorStyle: const TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.bold),
    );
  }
}
