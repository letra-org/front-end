import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

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
  Map<String, dynamic> _userInfo = {
    'full_name': 'Đang tải...',
    'email': 'Đang tải...',
    'phone': 'Đang tải...',
    'username': 'Đang tải...',
    'avatar_url': null,
  };
  File? _profileImageFile;
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    setState(() { _isLoading = true; });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dataPath = '${directory.path}/data/userdata.js';
      final imagePath = '${directory.path}/user/avatar.jpg';
      final dataFile = File(dataPath);
      final imageFile = File(imagePath);

      if (await dataFile.exists()) {
        final content = await dataFile.readAsString();
        final jsonData = json.decode(content);
        final user = jsonData['user'] as Map<String, dynamic>?;

        if (user != null) {
          _userInfo = {
            'full_name': user['full_name'] as String? ?? 'Chưa có tên',
            'email': user['email'] as String? ?? 'Chưa có email',
            'phone': user['phone'] as String? ?? 'Chưa có SĐT',
            'username': user['username'] as String? ?? 'Chưa có username',
            'avatar_url': user['avatar_url'],
          };
        }
      }

      if (await imageFile.exists()) {
        _profileImageFile = imageFile;
      }

      _nameController.text = _userInfo['full_name']!;
      _emailController.text = _userInfo['email']!;
      _phoneController.text = _userInfo['phone']!;
      _usernameController.text = _userInfo['username']!;

    } catch (e) {
      print('LỖI KHI TẢI DỮ LIỆU: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveUserInfo() async {
    final String? token = await _getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi xác thực. Vui lòng đăng nhập lại.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final url = Uri.parse('https://b55k0s8l-8000.asse.devtunnels.ms/users/me');
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
          'username': _userInfo['username'], // Keep non-editable fields
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
          const SnackBar(content: Text('✅ Cập nhật thông tin thành công!')),
        );
      } else {
        throw Exception('Cập nhật thất bại. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi khi cập nhật: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  Future<void> _takePicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 800);

    if (imageFile == null) return;

    final String? token = await _getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi xác thực. Vui lòng đăng nhập lại.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final url = Uri.parse('https://b55k0s8l-8000.asse.devtunnels.ms/users/me/avatar');
      final request = http.MultipartRequest('POST', url); // Changed from PUT to POST
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
        
        final newAvatarFile = File('${directory.path}/user/avatar.jpg');
         if (!await newAvatarFile.parent.exists()) {
          await newAvatarFile.parent.create(recursive: true);
        }
        final savedImage = await File(imageFile.path).copy(newAvatarFile.path);

        setState(() {
          _userInfo['avatar_url'] = updatedUser['avatar_url'];
          _profileImageFile = savedImage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
        );

      } else {
        throw Exception('Tải lên thất bại. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}')),
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
                            _buildInfoField('Tên người dùng', _usernameController, isDarkMode, readOnly: true, icon: Icons.account_circle_outlined),
                            const SizedBox(height: 16),
                            _buildInfoField('Họ và Tên', _nameController, isDarkMode, icon: Icons.badge_outlined),
                            const SizedBox(height: 16),
                            _buildInfoField('Email', _emailController, isDarkMode, icon: Icons.email_outlined),
                            const SizedBox(height: 16),
                            _buildInfoField('Số điện thoại', _phoneController, isDarkMode, icon: Icons.phone_outlined),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _saveUserInfo,
                              icon: const Icon(Icons.save_alt_outlined),
                              label: const Text('Lưu thay đổi'),
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
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              const Text(
                'Thông tin cá nhân',
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
                onPressed: () => _takePicture(context),
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_profileImageFile != null && _profileImageFile!.existsSync()) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_profileImageFile!),
      );
    }
    if (_userInfo['avatar_url'] != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _userInfo['avatar_url']!,
          placeholder: (context, url) => const CircleAvatar(radius: 60, child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => CircleAvatar(radius: 60, backgroundImage: const AssetImage('assets/images/user/avatar.jpg')),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    }
    if (_userInfo['full_name'] != null && _userInfo['full_name']!.isNotEmpty && _userInfo['full_name'] != 'Đang tải...') {
      final initial = _userInfo['full_name']![0].toUpperCase();
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF2563EB),
        child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
      );
    }
    return CircleAvatar(
      radius: 60,
      backgroundImage: const AssetImage('assets/images/user/avatar.jpg'),
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
