import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'single_purpose_camera_screen.dart'; // Import the new camera screen
import '../l10n/app_localizations.dart';
import '../constants/api_config.dart';

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
    // Use a post-frame callback to ensure context is available for AppLocalizations
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

  // --- DATA & API LOGIC ---

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

  Future<void> _saveUserInfo() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final String? token = await _getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.get('auth_error'))),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final url = Uri.parse(ApiConfig.currentUser);
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'full_name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final updatedUser = json.decode(response.body);

        final directory = await getApplicationDocumentsDirectory();
        final dataFile = File('${directory.path}/data/userdata.js');
        Map<String, dynamic> localData = {};
        if (await dataFile.exists()) {
          localData = json.decode(await dataFile.readAsString());
        }
        localData['user'] = updatedUser;
        await dataFile.writeAsString(json.encode(localData));

        setState(() {
          _userInfo['full_name'] = updatedUser['full_name'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.get('update_success'))),
        );
      } else if (response.statusCode == 422) {
        throw Exception('Dữ liệu không hợp lệ');
      } else {
        throw Exception('${appLocalizations.get('update_failed')}${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.get('update_error')}${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  Future<void> _handleAvatarChange(BuildContext context) async {
    final XFile? confirmedImage = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SinglePurposeCameraScreen()),
    );

    if (confirmedImage != null) {
      _uploadAvatar(confirmedImage);
    }
  }

  Future<void> _uploadAvatar(XFile imageFile) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final String? token = await _getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.get('auth_error'))),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final url = Uri.parse(ApiConfig.updateUserAvatar);
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final updatedUser = json.decode(response.body);
        final directory = await getApplicationDocumentsDirectory();
        final dataFile = File('${directory.path}/data/userdata.js');
        Map<String, dynamic> localData = {};

        if (await dataFile.exists()) {
          localData = json.decode(await dataFile.readAsString());
        }

        localData['user'] = updatedUser;
        await dataFile.writeAsString(json.encode(localData));
        
        setState(() {
          _userInfo['avatar_url'] = updatedUser['avatar_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.get('avatar_update_success'))),
        );

      } else if (response.statusCode == 422) {
        throw Exception('Dữ liệu không hợp lệ');
      } else {
        throw Exception('${appLocalizations.get('upload_failed')}${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.get('generic_error')}${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  // --- UI BUILDING WIDGETS ---

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
                            _buildInfoField(appLocalizations.get('username_label'), _usernameController, isDarkMode, readOnly: true, icon: Icons.account_circle_outlined),
                            const SizedBox(height: 16),
                            _buildInfoField(appLocalizations.get('full_name_label'), _nameController, isDarkMode, icon: Icons.badge_outlined),
                            const SizedBox(height: 16),
                            _buildInfoField(appLocalizations.get('email_label'), _emailController, isDarkMode, icon: Icons.email_outlined),
                            const SizedBox(height: 16),
                            _buildInfoField(appLocalizations.get('phone_label'), _phoneController, isDarkMode, icon: Icons.phone_outlined),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _saveUserInfo,
                              icon: const Icon(Icons.save_alt_outlined),
                              label: Text(appLocalizations.get('save_changes_button')),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha((255*0.5).toInt()),
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
      child: Stack(
        children: [
          _buildAvatar(),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 48, 
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _handleAvatarChange(context), // MODIFIED: Calls the new handler function
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
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
          errorWidget: (context, url, error) => CircleAvatar(radius: 60, backgroundImage: const AssetImage('assets/images/user/avatar.jpg')),
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

  Widget _buildInfoField(String label, TextEditingController controller, bool isDarkMode, {bool readOnly = false, IconData? icon}) {
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
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.grey[600] : null),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: readOnly,
            fillColor: readOnly ? (isDarkMode ? Colors.grey[850] : Colors.grey[200]) : null,
          ),
        ),
      ],
    );
  }
}
