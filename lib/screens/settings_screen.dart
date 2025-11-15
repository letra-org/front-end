import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF2563EB),
            child: const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cài đặt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Profile Card
                GestureDetector(
                  onTap: () => onNavigate('userProfile'),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF2563EB),
                            child: Text(
                              'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Người dùng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'user@example.com',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Appearance
                _buildSectionTitle('Giao diện', isDarkMode),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Chế độ tối'),
                    subtitle: const Text('Bảo vệ mắt khi sử dụng ban đêm'),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(),
                      activeTrackColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Emergency
                _buildSectionTitle('Khẩn cấp', isDarkMode),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: const Text('Chia sẻ vị trí cứu hộ'),
                    subtitle: const Text('Gửi vị trí khi gặp nguy hiểm'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigate('emergency'),
                  ),
                ),
                const SizedBox(height: 16),
                // Account
                _buildSectionTitle('Tài khoản', isDarkMode),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Bảo mật'),
                    subtitle: const Text('Đổi mật khẩu, xác thực 2 lớp'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigate('security'),
                  ),
                ),
                const SizedBox(height: 16),
                // About
                _buildSectionTitle('Về chúng tôi', isDarkMode),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.group),
                        title: const Text('Đội ngũ phát triển'),
                        subtitle: const Text('Gặp gỡ những người tạo nên Letra'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onNavigate('team'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.star),
                        title: const Text('Nhà tài trợ'),
                        subtitle: const Text('Các đối tác hỗ trợ dự án'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onNavigate('sponsors'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('Thông tin ứng dụng'),
                        subtitle: const Text('Phiên bản, điều khoản, chính sách'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onNavigate('appInfo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Logout
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Đăng xuất'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentScreen: 'settings',
        onNavigate: onNavigate,
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
