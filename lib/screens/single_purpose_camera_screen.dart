import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Màn hình này xử lý việc hiển thị camera và chụp ảnh.
class SinglePurposeCameraScreen extends StatefulWidget {
  const SinglePurposeCameraScreen({super.key});

  @override
  _SinglePurposeCameraScreenState createState() => _SinglePurposeCameraScreenState();
}

class _SinglePurposeCameraScreenState extends State<SinglePurposeCameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  late List<CameraDescription> _cameras;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera({bool useFrontCamera = false}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('Không tìm thấy camera trên thiết bị');
      }
      if (useFrontCamera && _cameras.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy camera trước.')),
        );
        return;
      }
      final selectedCamera = _cameras[useFrontCamera ? 1 : 0];

      // Dispose the old controller before creating a new one
      await _controller?.dispose();

      _controller = CameraController(selectedCamera, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isFrontCamera = useFrontCamera;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi camera: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Hàm thực hiện chụp ảnh
  Future<void> _onCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    final image = await _controller!.takePicture();
    if (!mounted) return;

    // Chuyển sang màn hình xác nhận và chờ kết quả
    final confirmedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(imageFile: image),
      ),
    );

    // Nếu người dùng đồng ý, trả ảnh về màn hình trước đó (UserProfileScreen)
    if (confirmedImage != null && confirmedImage is XFile) {
      Navigator.pop(context, confirmedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          // Nút chụp ảnh
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _onCapture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    border: Border.all(color: Colors.white, width: 4, style: BorderStyle.none),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), spreadRadius: 2, blurRadius: 10)],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 40),
                ),
              ),
            ),
          ),
          // Nút đóng
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Nút lật camera
          Positioned(
            bottom: 52,
            right: 40,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 36),
              onPressed: () {
                if (_cameras.length > 1) {
                  _initializeCamera(useFrontCamera: !_isFrontCamera);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thiết bị chỉ có một camera.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Màn hình này hiển thị ảnh đã chụp và hỏi người dùng xác nhận.
class ConfirmationScreen extends StatelessWidget {
  final XFile imageFile;
  const ConfirmationScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hiển thị ảnh đã chụp
          Image.file(File(imageFile.path), fit: BoxFit.contain),
          // Các nút điều khiển
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút Chụp lại
                  ElevatedButton.icon(
                    onPressed: () {
                      // Quay lại màn hình camera để chụp lại
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Chụp lại'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  // Nút Đồng ý
                  ElevatedButton.icon(
                    onPressed: () {
                      // Trả kết quả là ảnh đã xác nhận về
                      Navigator.pop(context, imageFile);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Đồng ý'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
