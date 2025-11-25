import 'package:flutter/material.dart';
import 'dart:ui'; // Required for BackdropFilter
import 'dart:convert'; // Required for json encoding
import 'package:http/http.dart' as http; // Required for HTTP requests
import 'package:path_provider/path_provider.dart'; // For file storage
import 'dart:io'; // For file operations
import '../l10n/app_localizations.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorToast(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveUserData(String userData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/data';
      final file = File('$path/userdata.js');

      await Directory(path).create(recursive: true);
      await file.writeAsString(userData);
      print('User data saved successfully to: ${file.path}');
    } catch (e) {
      print('Failed to save user data: $e');
      if (mounted) {
        _showErrorToast('Không thể lưu dữ liệu người dùng cục bộ: $e', backgroundColor: Colors.orange);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() { _isLoading = true; });

    final email = _emailController.text;
    final password = _passwordController.text;
    final appLocalizations = AppLocalizations.of(context)!;

    if (email == 'dev@test.com' && password == 'dev') {
      print('--- Performing local developer login ---');
      final mockUserData = {
        'access_token': 'local_dev_token',
        'refresh_token': 'local_dev_refresh_token',
        'user': {
          'id': 'dev-user-01',
          'email': 'dev@test.com',
          'full_name': 'Developer',
          'avatar_url': 'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
          'is_active': true,
        }
      };
      
      await _saveUserData(json.encode(mockUserData));
      widget.onLogin();
      return;
    }

    final loginUrl = Uri.parse('https://letra-org.fly.dev/auth/login');

    try {
      final loginResponse = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        final accessToken = loginData['access_token'];

        final userDetailsUrl = Uri.parse('https://letra-org.fly.dev/users/me');
        final userDetailsResponse = await http.get(
          userDetailsUrl,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (!mounted) return;

        if (userDetailsResponse.statusCode == 200) {
          final userDetails = json.decode(userDetailsResponse.body);
          final finalUserData = { ...loginData, 'user': userDetails };
          await _saveUserData(json.encode(finalUserData));
          widget.onLogin();
        } else {
          throw Exception('Không thể lấy chi tiết người dùng. Mã lỗi: ${userDetailsResponse.statusCode}');
        }
      } else {
        _showErrorToast(appLocalizations.get('invalid_credentials'));
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Đã xảy ra lỗi: ${e.toString().replaceAll("Exception: ", "")}');
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
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
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha((255 * 0.3).toInt()),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(color: Colors.black.withAlpha(0)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appLocalizations.get('welcome_back'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(blurRadius: 5, color: Colors.black38)
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(53),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(127),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.3).toInt()),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.15).toInt()),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha((255 * 0.4).toInt()),
                            width: 1,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(appLocalizations.get('account_label')),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailController,
                                hintText: appLocalizations.get('enter_your_email'),
                                icon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty || !value.contains('@')) {
                                    return appLocalizations.get('invalid_email_prompt');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildLabel(appLocalizations.get('password_label')),
                              const SizedBox(height: 8),
                              _buildPasswordField(),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1D4ED8),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF1D4ED8)),
                                        )
                                      : Text(
                                          appLocalizations.get('login_button'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: widget.onNavigateToForgotPassword,
                            child: Text(
                              appLocalizations.get('forgot_password'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onNavigateToRegister,
                            child: Text(
                              appLocalizations.get('register_now'),
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withAlpha((255 * 0.7).toInt())),
        prefixIcon: Icon(icon, color: Colors.white, size: 22),
        filled: true,
        fillColor: Colors.white.withAlpha((255 * 0.2).toInt()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    final appLocalizations = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: appLocalizations.get('enter_your_password'),
        hintStyle: TextStyle(color: Colors.white.withAlpha((255 * 0.7).toInt())),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withAlpha(180),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withAlpha((255 * 0.2).toInt()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return appLocalizations.get('empty_password_prompt');
        }
        return null;
      },
    );
  }
}
