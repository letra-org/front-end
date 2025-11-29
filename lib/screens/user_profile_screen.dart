import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const UserProfileScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic> _userInfo = {};
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  void _initializeUserData() {
    final appLocalizations = AppLocalizations.of(context)!;
    setState(() {
      _userInfo = {
        'full_name': appLocalizations.get('loading') ?? 'Loading...',
        'email': appLocalizations.get('loading') ?? 'Loading...',
        'phone': appLocalizations.get('loading') ?? 'Loading...',
        'username': appLocalizations.get('loading') ?? 'Loading...',
        'avatar_url': null,
      };
    });
    _loadDataFromDevice();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadDataFromDevice() async {
    if (!mounted) return;
    final appLocalizations = AppLocalizations.of(context)!;

    setState(() { _isLoading = true; });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dataPath = '${directory.path}/data/userdata.js';
      final dataFile = File(dataPath);

      if (await dataFile.exists()) {
        final content = await dataFile.readAsString();
        final jsonData = json.decode(content);
        final user = jsonData['user'] as Map<String, dynamic>?;

        if (user != null) {
          setState(() {
            _userInfo = {
              'full_name': user['full_name'] as String? ?? appLocalizations.get('no_name'),
              'email': user['email'] as String? ?? appLocalizations.get('no_email'),
              'phone': user['phone'] as String? ?? appLocalizations.get('no_phone'),
              'username': user['username'] as String? ?? appLocalizations.get('no_username'),
              'avatar_url': user['avatar_url'],
            };
          });
        }
      }

      _nameController.text = _userInfo['full_name'] ?? '';
      _emailController.text = _userInfo['email'] ?? '';
      _phoneController.text = _userInfo['phone'] ?? '';
      _usernameController.text = _userInfo['username'] ?? '';

    } catch (e) {
      print('LỖI KHI TẢI DỮ LIỆU: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDataFromDevice,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 32),
                      _buildInfoField(appLocalizations.get('username_label'), _usernameController, isDarkMode, icon: Icons.account_circle_outlined),
                      const SizedBox(height: 16),
                      _buildInfoField(appLocalizations.get('full_name_label'), _nameController, isDarkMode, icon: Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildInfoField(appLocalizations.get('email_label'), _emailController, isDarkMode, icon: Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildInfoField(appLocalizations.get('phone_label'), _phoneController, isDarkMode, icon: Icons.phone_outlined),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
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
                appLocalizations.get('personal_info_title'),
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
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: _buildAvatar(),
    );
  }

  Widget _buildAvatar() {
    final appLocalizations = AppLocalizations.of(context)!;
    final avatarUrl = _userInfo['avatar_url'] as String?;

    if (avatarUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          placeholder: (context, url) => const CircleAvatar(radius: 60, child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const CircleAvatar(radius: 60, backgroundImage: AssetImage('assets/images/user/avatar.jpg')),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    }

    final fullName = _userInfo['full_name'] as String?;
    if (fullName != null && fullName.isNotEmpty && fullName != appLocalizations.get('loading')) {
      final initial = fullName[0].toUpperCase();
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF2563EB),
        child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
      );
    }

    return const CircleAvatar(
      radius: 60,
      backgroundImage: AssetImage('assets/images/user/avatar.jpg'),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, bool isDarkMode, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
          ),
        ),
      ],
    );
  }
}
