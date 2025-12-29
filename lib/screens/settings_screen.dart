import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../constants/api_config.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _avatarUrl;
  String _fullName = 'Người dùng';
  String _email = 'Tải thông tin...';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        final user = data['user'] as Map<String, dynamic>?;

        if (user != null && mounted) {
          setState(() {
            _avatarUrl = user['avatar_url'] as String?;
            _fullName = user['full_name'] as String? ?? 'Chưa có tên';
            _email = user['email'] as String? ?? 'Chưa có email';
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi tải dữ liệu người dùng trên settings_screen: $e");
      if (mounted) {
        setState(() {
          _email = "Không thể tải dữ liệu";
        });
      }
    }
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
      debugPrint("Lỗi khi lấy token: $e");
    }
    return null;
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    final token = await _getAuthToken();

    if (token != null) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint("Logout API call failed: $e");
        // Ignore error and proceed with client-side logout
      }
    }

    // Clear local data
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Failed to delete user data: $e");
    }

    if (mounted) {
      widget.onLogout();
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        final appLocalizations = AppLocalizations.of(context)!;

        return AlertDialog(
          title: Text(appLocalizations.get('choose_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipOval(
                  child: Image.asset('assets/images/flags/vn.png',
                      width: 32, height: 32, fit: BoxFit.cover),
                ),
                title: Text(appLocalizations.get('vietnamese')),
                onTap: () {
                  if (languageProvider.currentLocale.languageCode != 'vi') {
                    languageProvider.toggleLanguage();
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: ClipOval(
                  child: Image.asset('assets/images/flags/gb.png',
                      width: 32, height: 32, fit: BoxFit.cover),
                ),
                title: Text(appLocalizations.get('english')),
                onTap: () {
                  if (languageProvider.currentLocale.languageCode != 'en') {
                    languageProvider.toggleLanguage();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF1E88E5),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appLocalizations.get('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _showLanguageDialog,
                      child: ClipOval(
                        child: Image.asset(
                          languageProvider.currentLocale.languageCode == 'vi'
                              ? 'assets/images/flags/vn.png'
                              : 'assets/images/flags/gb.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
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
              padding: const EdgeInsets.all(12),
              children: [
                // Profile Card
                GestureDetector(
                  onTap: () => widget.onNavigate('userProfile'),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipOval(
                            child: Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[300],
                              child: _avatarUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: _avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Image.asset(
                                              'assets/images/user/avatar.jpg',
                                              fit: BoxFit.cover),
                                    )
                                  : Image.asset('assets/images/user/avatar.jpg',
                                      fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fullName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  _email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
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
                _buildSectionTitle(
                    appLocalizations.get('appearance'), isDarkMode),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: Text(appLocalizations.get('dark_mode')),
                        subtitle:
                            Text(appLocalizations.get('dark_mode_subtitle')),
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (value) => themeProvider.toggleTheme(),
                          activeTrackColor: const Color(0xFF1E88E5),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(appLocalizations.get('language')),
                        subtitle: Row(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                languageProvider.currentLocale.languageCode ==
                                        'vi'
                                    ? 'assets/images/flags/vn.png'
                                    : 'assets/images/flags/gb.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              languageProvider.currentLocale.languageCode ==
                                      'vi'
                                  ? appLocalizations.get('vietnamese')
                                  : appLocalizations.get('english'),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showLanguageDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Account
                _buildSectionTitle(appLocalizations.get('account'), isDarkMode),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: Text(appLocalizations.get('change_password')),
                        subtitle: Text(
                            appLocalizations.get('change_password_subtitle')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onNavigate('changePassword'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: Text(appLocalizations.get('your_photos')),
                        subtitle:
                            Text(appLocalizations.get('your_photos_subtitle')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onNavigate('photos'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // About
                _buildSectionTitle(
                    appLocalizations.get('about_us'), isDarkMode),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.group),
                        title: Text(appLocalizations.get('development_team')),
                        subtitle: Text(
                            appLocalizations.get('development_team_subtitle')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onNavigate('team'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.star),
                        title: Text(appLocalizations.get('sponsors')),
                        subtitle:
                            Text(appLocalizations.get('sponsors_subtitle')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onNavigate('sponsors'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: Text(appLocalizations.get('app_info')),
                        subtitle:
                            Text(appLocalizations.get('app_info_subtitle')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onNavigate('appInfo'),
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
                    onPressed: _isLoggingOut ? null : _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red),
                          )
                        : Text(appLocalizations.get('logout')),
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
        onNavigate: widget.onNavigate,
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
