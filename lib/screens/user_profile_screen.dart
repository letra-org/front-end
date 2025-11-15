import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Chuyển sang StatefulWidget để quản lý trạng thái tải dữ liệu
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
  // Biến lưu trữ dữ liệu người dùng
  Map<String, String> _userInfo = {
    'name': 'Đang tải...',
    'email': 'Đang tải...',
    'phone': 'Đang tải...',
    'birthday': 'Đang tải...',
  };
  File? _profileImageFile;
  bool _isLoading = true;

  // Controllers cho TextField
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Hàm đọc file và load ảnh
  Future<void> _loadUserInfo() async {
    try {
      // Lấy đường dẫn thư mục ứng dụng cục bộ (Documents Directory)
      final directory = await getApplicationDocumentsDirectory();
      print('Documents Directory Path: ${directory.path}');
      
      // 1. Định nghĩa đường dẫn cục bộ và Assets Path
      final localInfoPath = '${directory.path}/info/user_info.txt';
      final infoFile = File(localInfoPath);
      final assetInfoPath = 'assets/info/user_info.txt';
      
      final imageDirPath = '${directory.path}/images/user';
      final imageDir = Directory(imageDirPath);
      final assetImagePath = 'assets/images/user/avatar.jpg'; 
      final localImageFile = File('$imageDirPath/avatar.jpg');

      // --- BƯỚC SỬA LỖI: KIỂM TRA VÀ SAO CHÉP DỮ LIỆU MẶC ĐỊNH (ASSET) ---
      
      // A. Sao chép info.txt
      if (!await infoFile.exists()) {
        print('File user_info.txt chưa tồn tại cục bộ. Bắt đầu sao chép từ Assets...');
        await Directory('${directory.path}/info').create(recursive: true);
        
        try {
          // Dùng rootBundle để đọc file Asset
          final assetData = await rootBundle.loadString(assetInfoPath); 
          await infoFile.writeAsString(assetData);
          print('✅ Sao chép user_info.txt THÀNH CÔNG.');
        } catch (e) {
          print('❌ LỖI SAO CHÉP INFO.TXT. Có thể asset không được tìm thấy: $e');
        }
      } else {
        print('File user_info.txt đã tồn tại cục bộ.');
      }
      
      // B. Sao chép ảnh đại diện (avatar.jpg)
      if (!await localImageFile.exists()) { 
        print('Ảnh mặc định chưa tồn tại cục bộ. Bắt đầu sao chép từ Assets...');
        await imageDir.create(recursive: true);
        
        try {
          // Dùng rootBundle để đọc file Asset
          final assetImageByte = await rootBundle.load(assetImagePath); 
          await localImageFile.writeAsBytes(assetImageByte.buffer.asUint8List());
          print('✅ Sao chép ảnh THÀNH CÔNG.');
        } catch (e) {
          print('❌ LỖI SAO CHÉP ẢNH. Có thể asset không được tìm thấy: $e');
        }
      } else {
         print('Ảnh mặc định đã tồn tại cục bộ.');
      }
      // -------------------------------------------------------------------

      // 2. Đọc file info.txt (đã được đảm bảo tồn tại)
      if (await infoFile.exists()) {
          final content = await infoFile.readAsString();
          // Tách nội dung và đảm bảo không lấy dòng trống cuối cùng
          final lines = content.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(); 
          
          if (lines.length >= 4) {
              _userInfo = {
                'name': lines[0],
                'email': lines[1],
                'phone': lines[2],
                'birthday': lines[3],
              };
              print('Đã load thông tin người dùng: ${_userInfo['name']}');
            } else {
               print('Lỗi định dạng file info.txt.');
            }
      }
      
      // 3. Load ảnh đại diện
      File? foundImage;
      if (await imageDir.exists()) {
        final files = await imageDir.list().toList();
        
        // Dùng vòng lặp an toàn để tìm và ép kiểu thành File
        for (var entity in files) {
          if (entity is File && (entity.path.endsWith('.jpg') || entity.path.endsWith('.png'))) {
            foundImage = entity;
            break;
          }
        }
      }
      _profileImageFile = foundImage;

      // 4. Cập nhật Controllers
      _nameController.text = _userInfo['name']!;
      _emailController.text = _userInfo['email']!;
      _phoneController.text = _userInfo['phone']!;
      _birthdayController.text = _userInfo['birthday']!;
      
    } catch (e) {
      print('LỖI KHÔNG XỬ LÝ ĐƯỢC (Cấp độ cao hơn): $e');
      _userInfo['name'] = 'Lỗi tải dữ liệu';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm xây dựng Avatar dựa trên trạng thái tải/có ảnh
  Widget _buildAvatar() {
    // 1. Nếu có file ảnh hợp lệ (từ Documents Directory)
    if (_profileImageFile != null && _profileImageFile!.existsSync()) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_profileImageFile!),
      );
    } 
    // 2. Nếu không có ảnh, hiển thị chữ cái đầu tiên
    else if (_userInfo['name'] != null && _userInfo['name']!.isNotEmpty && !_isLoading) {
      final initial = _userInfo['name']![0].toUpperCase();
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF2563EB),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } 
    // 3. Nếu đang tải hoặc có lỗi
    else {
      return const CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 48, color: Colors.white),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

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
          ),
          // Body
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      _buildAvatar(), // Dùng hàm build Avatar mới
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: () {
                              // TODO: Thêm logic chọn ảnh từ thư viện/chụp mới
                              // Nếu người dùng chọn ảnh mới, bạn cần lưu ảnh đó 
                              // vào thư mục imageDir (ví dụ: đè lên avatar.jpg)
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Name
                _buildInfoField('Tên người dùng', _nameController, isDarkMode),
                const SizedBox(height: 16),
                // Email
                _buildInfoField('Email', _emailController, isDarkMode, readOnly: true), 
                const SizedBox(height: 16),
                // Phone
                _buildInfoField('Số điện thoại', _phoneController, isDarkMode),
                const SizedBox(height: 16),
                // Birthday
                _buildInfoField('Ngày sinh', _birthdayController, isDarkMode),
                const SizedBox(height: 32),
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Thêm logic lưu dữ liệu mới vào infoFile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang cập nhật thông tin...')),
                      );
                    },
                    child: const Text('Cập nhật thông tin'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, bool isDarkMode, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}