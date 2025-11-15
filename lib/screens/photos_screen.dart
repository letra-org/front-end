import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; 
import 'dart:io'; 
// Thêm các import cần thiết cho PhotoViewScreen
import 'package:flutter/services.dart'; 
import 'package:gallery_saver_plus/gallery_saver.dart'; 

// Import widget điều hướng dưới cùng của bạn
import '../widgets/bottom_navigation_bar.dart'; 


// =================================================================
// PHOTOS SCREEN (Vẫn là StatefulWidget để quản lý tải ảnh và trạng thái)
// =================================================================

class PhotosScreen extends StatefulWidget {
  // Giữ lại onNavigate vì nó được sử dụng trong BottomNavigationBarWidget
  final Function(String) onNavigate;

  const PhotosScreen({super.key, required this.onNavigate});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  // Thay đổi List<String> thành List<File>
  List<File> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos(); // Gọi hàm tải ảnh khi khởi tạo State
  }

  // Hàm tải ảnh từ thư mục cục bộ
  Future<void> _loadPhotos() async {
    // 1. Tìm thư mục Documents của ứng dụng
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDocumentsDir.path}/User_photo');

    // 2. Kiểm tra và tạo thư mục nếu chưa có
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    // 3. Đọc danh sách file trong thư mục
    final List<File> loadedPhotos = [];
    try {
      // Lấy danh sách các đối tượng File/Directory
      final fileList = photosDir.listSync(recursive: true)
          // Lọc ra chỉ các file và kiểm tra đuôi file là ảnh
          .where((item) => item is File && _isImageFile(item.path))
          .toList();
      
      for (var file in fileList) {
        loadedPhotos.add(file as File);
      }
      
    } catch (e) {
      debugPrint('Lỗi khi đọc thư mục ảnh: $e');
    }

    // 4. Cập nhật State
    if (mounted) { // Kiểm tra để tránh lỗi khi State bị hủy
      setState(() {
        _photos = loadedPhotos.reversed.toList(); // Hiển thị ảnh mới nhất lên đầu
        _isLoading = false;
      });
    }
  }

  // Hàm kiểm tra đơn giản để lọc ra các file ảnh
  bool _isImageFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.png') ||
           lowerPath.endsWith('.jpg') ||
           lowerPath.endsWith('.jpeg');
  }

  // Hàm mở ảnh (sử dụng FilePath)
  void _openPhoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewScreen(
          // Truyền đường dẫn File
          filePath: _photos[index].path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading trong khi chờ tải ảnh
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                    const Text(
                      'Thư viện ảnh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        // Show filter options
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Photos Grid
          Expanded(
            child: _photos.isEmpty
                ? const Center(
                    child: Text(
                      'Không có ảnh nào.\nHãy chụp một bức ảnh!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openPhoto(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Sử dụng Image.file
                              Image.file( 
                                _photos[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 50),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withAlpha((255 * 0.3).toInt()),
                                    ],
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 8,
                                right: 8,
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentScreen: 'photos',
        onNavigate: widget.onNavigate,
      ),
    );
  }
}


// =================================================================
// PHOTO VIEW SCREEN (Màn hình xem ảnh chi tiết với tính năng lưu)
// =================================================================

class PhotoViewScreen extends StatefulWidget {
  final String filePath; 

  const PhotoViewScreen({
    super.key,
    required this.filePath,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // HÀM: Xử lý lưu ảnh về Gallery SỬ DỤNG gallery_saver_plus
  void _handleDownload() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    try {
      final String filePath = widget.filePath;
      
      // Sử dụng GallerySaverPlus.saveImage
      final bool? success = await GallerySaver.saveImage(
        filePath,
        albumName: "User_photo_Gallery", 
        toDcim: true, 
      );

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu ảnh vào Thư viện thành công!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi lưu ảnh. Vui lòng kiểm tra quyền truy cập.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chung: Không thể lưu file: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image with zoom
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              onInteractionUpdate: (details) {
                final scale = _transformationController.value.getMaxScaleOnAxis();
                if (scale != 1.0) {
                    setState(() {
                      _isZoomed = scale > 1.0;
                    });
                }
              },
              onInteractionEnd: (details) {
                final scale = _transformationController.value.getMaxScaleOnAxis();
                setState(() {
                  _isZoomed = scale > 1.0;
                });
              },
              child: Image.file(
                File(widget.filePath), 
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((255 * 0.7).toInt()),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // CHỈ hiển thị nút Download khi _isZoomed là TRUE
                      if (_isZoomed)
                        IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _handleDownload, // Gọi hàm lưu ảnh
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom hint (Chỉ hiển thị khi KHÔNG zoom)
          if (!_isZoomed)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((255 * 0.7).toInt()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Phóng to để tải ảnh', 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}