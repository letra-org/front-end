import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../constants/api_config.dart';

class ChangePasswordScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ChangePasswordScreen({super.key, required this.onNavigate});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        return data['access_token'] as String?;
      }
    } catch (e) {
      print("Lỗi khi lấy token: $e");
    }
    return null;
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = await _getAuthToken();
    if (token == null) {
      _showFeedback('Lỗi xác thực. Vui lòng đăng nhập lại.', isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.changepassword),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming the response body is a simple string for success
        _showFeedback(response.body);
        widget.onNavigate('settings');
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        final detail = errorBody['detail'];
        String errorMessage = 'Dữ liệu không hợp lệ.';
        if (detail is List && detail.isNotEmpty) {
          final firstError = detail[0];
          if (firstError is Map && firstError.containsKey('msg')) {
            errorMessage = firstError['msg'];
          }
        }
        _showFeedback(errorMessage, isError: true);
      } else {
         final errorBody = json.decode(response.body);
        _showFeedback('Lỗi: ${errorBody['detail'] ?? response.statusCode}', isError: true);
      }
    } catch (e) {
      _showFeedback('Lỗi kết nối: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header
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
                      onPressed: () => widget.onNavigate('settings'),
                    ),
                    Text(
                      appLocalizations.get('change_password_title'),
                      style: const TextStyle(
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
          // Body
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.get('current_password_label'),
                      suffixIcon: IconButton(
                        icon: Icon(_isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                      ),
                    ),
                    obscureText: !_isCurrentPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu hiện tại';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.get('new_password_label'),
                      suffixIcon: IconButton(
                        icon: Icon(_isNewPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                      ),
                    ),
                    obscureText: !_isNewPasswordVisible,
                    validator: (value) {
                       if (value == null || value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.get('confirm_new_password_label'),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                     validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleChangePassword,
                    child: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                          )
                        : Text(appLocalizations.get('update_password_button')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
