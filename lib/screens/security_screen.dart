import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const SecurityScreen({super.key, required this.onNavigate});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                    const Text(
                      'Bảo mật',
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
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Đổi mật khẩu'),
                    subtitle: const Text('Cập nhật mật khẩu mới'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Xác thực 2 lớp'),
                    subtitle: const Text('Tăng cường bảo mật tài khoản'),
                    trailing: Switch(
                      value: _twoFactorEnabled,
                      onChanged: (value) {
                        setState(() {
                          _twoFactorEnabled = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Lịch sử đăng nhập'),
                    subtitle: const Text('Xem các thiết bị đã đăng nhập'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
