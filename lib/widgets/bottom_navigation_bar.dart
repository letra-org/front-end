import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // Import để tìm đường dẫn
import 'dart:io'; // Import để xử lý File

class BottomNavigationBarWidget extends StatelessWidget {
  final String currentScreen;
  final Function(String) onNavigate;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentScreen,
    required this.onNavigate,
  });

  // HÀM XỬ LÝ CHỤP ẢNH VÀ LƯU VÀO data/User_photo
  Future<void> _takePicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    // Bật camera và chờ ảnh
    final XFile? imageFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600, 
    );

    if (imageFile != null) {
      try {
        // 1. Tìm thư mục Documents của ứng dụng
        final appDocumentsDir = await getApplicationDocumentsDirectory();
        
        // 2. Định nghĩa thư mục đích
        final photosDir = Directory('${appDocumentsDir.path}/User_photo');
        
        // 3. Đảm bảo thư mục đích tồn tại, nếu không thì tạo mới
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        
        // 4. Tạo đường dẫn mới cho file ảnh
        final fileName = imageFile.path.split('/').last;
        final newPath = '${photosDir.path}/$fileName';
        
        // 5. Di chuyển/Sao chép file ảnh từ thư mục tạm thời sang thư mục đích
        final File savedImage = await File(imageFile.path).copy(newPath);

        // Thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu ảnh thành công tại: ${savedImage.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
        
      } catch (e) {
        // Xử lý lỗi nếu việc lưu/di chuyển file thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu ảnh: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      // Thông báo hủy chụp
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hủy chụp ảnh!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).toInt()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            label: 'Trang chủ',
            screen: 'home',
          ),
          _buildNavItem(
            context,
            icon: Icons.image,
            label: 'Ảnh',
            screen: 'photos',
          ),
          _buildCameraButton(context), // Nút Camera
          _buildNavItem(
            context,
            icon: Icons.psychology,
            label: 'AI',
            screen: 'ai',
          ),
          _buildNavItem(
            context,
            icon: Icons.settings,
            label: 'Cài đặt',
            screen: 'settings',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String screen,
  }) {
    final isActive = currentScreen == screen;
    return InkWell(
      onTap: () => onNavigate(screen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFF2563EB)
                  : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF2563EB)
                    : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HÀM NÚT CAMERA (GỌI _takePicture)
  Widget _buildCameraButton(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {
          // GỌI HÀM CHỤP ẢNH VÀ LƯU FILE
          _takePicture(context);
        },
        icon: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}