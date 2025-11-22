import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum CameraMode { normal, aiRecognition }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isInitializing = true;
  CameraMode _currentMode = CameraMode.normal;
  FlashMode _flashMode = FlashMode.off;
  bool _isFrontCamera = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera({bool useFrontCamera = false}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('Không tìm thấy camera nào trên thiết bị.');
      }
      final selectedCamera = _cameras[useFrontCamera ? 1 : 0];

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

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
          SnackBar(content: Text('Lỗi khởi tạo camera: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
      print("Lỗi khi lấy token: $e");
    }
    return null;
  }

  Future<void> _onTakePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() { _isProcessing = true; });

    try {
      final image = await _controller!.takePicture();

      if (_currentMode == CameraMode.normal) {
        await _handleNormalCapture(image);
      } else {
        await _handleAiRecognitionCapture(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chụp ảnh: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  Future<void> _handleNormalCapture(XFile image) async {
    try {
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDocumentsDir.path}/User_photo');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName = image.path.split('/').last;
      final newPath = '${photosDir.path}/$fileName';
      await image.saveTo(newPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu ảnh vào thư mục User_photo')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu ảnh: $e')),
      );
    }
  }

  Future<void> _handleAiRecognitionCapture(XFile image) async {
    final token = await _getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi xác thực. Vui lòng đăng nhập lại.')),
      );
      return;
    }

    try {
      final url = Uri.parse('https://b55k0s8l-8000.asse.devtunnels.ms/ai/detect-location');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        // Hiển thị kết quả trong dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kết quả nhận diện'),
            content: Text(responseData.toString()), // Customize this to show the location nicely
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Server phản hồi lỗi: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi API: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Center(
                  child: CameraPreview(_controller!),
                ),
                // Nút quay lại
                Positioned(
                  top: 40, left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Các nút điều khiển camera
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: _buildCameraControls(),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildCameraControls() {
    return Column(
      children: [
        // Toggle chế độ
        _buildModeToggle(),
        const SizedBox(height: 20),
        // Các nút chụp, flash, v.v.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Nút flash
            IconButton(
              icon: Icon(
                _flashMode == FlashMode.off ? Icons.flash_off : (_flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_on),
                color: Colors.white, size: 30
              ),
              onPressed: () {
                setState(() {
                  if (_flashMode == FlashMode.off) _flashMode = FlashMode.auto;
                  else if (_flashMode == FlashMode.auto) _flashMode = FlashMode.torch;
                  else _flashMode = FlashMode.off;
                });
                _controller!.setFlashMode(_flashMode);
              },
            ),
            // Nút chụp ảnh
            GestureDetector(
              onTap: _onTakePicture,
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 58, height: 58,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  ),
                ),
              ),
            ),
            // Nút lật camera
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
              onPressed: () => _initializeCamera(useFrontCamera: !_isFrontCamera),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(CameraMode.normal, 'Bình thường'),
          const SizedBox(width: 10),
          _buildModeButton(CameraMode.aiRecognition, 'AI Nhận diện'),
        ],
      ),
    );
  }

  Widget _buildModeButton(CameraMode mode, String text) {
    final bool isActive = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() { _currentMode = mode; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
