import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';

enum CameraMode { normal, ai }

class CameraScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const CameraScreen({super.key, required this.onNavigate});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  bool _isFrontCamera = false;
  CameraMode _mode = CameraMode.normal;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Force AI mode on Desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _mode = CameraMode.ai;
    }
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    final cameraDescription = _cameras![_isFrontCamera ? 1 : 0];
    _controller = CameraController(cameraDescription, ResolutionPreset.high,
        enableAudio: false);

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() {
      _isReady = false;
      _isFrontCamera = !_isFrontCamera;
    });
    await _initializeCamera();
  }

  void _toggleMode() {
    // Disable toggle on Desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;

    setState(() {
      _mode = _mode == CameraMode.normal ? CameraMode.ai : CameraMode.normal;
    });
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();

      if (_mode == CameraMode.normal) {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          await _sendToAIAndNavigate(image);
        } else {
          await _saveImageNormally(image);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ảnh đã được lưu!')),
            );
          }
        }
      } else {
        // AI Mode
        await _sendToAIAndNavigate(image);
      }
    } catch (e) {
      debugPrint("Error during picture taking/processing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveImageNormally(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await image.saveTo('${photosDir.path}/$fileName');
  }

  Future<void> _sendToAIAndNavigate(XFile image) async {
    final bytes = await image.readAsBytes();
    String base64Image = base64Encode(bytes);
    final token = await _getToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lỗi xác thực. Vui lòng đăng nhập lại.')),
        );
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.landmarkDetect),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "image_base64": base64Image,
        }),
      );

      if (!mounted) return;

      final responseBody = utf8.decode(response.bodyBytes);
      final result = jsonDecode(responseBody);

      if (response.statusCode == 200 &&
          result['success'] == true &&
          result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;

        final name = data['Tên'] ?? 'N/A';
        final engName =
            data['Tên tiếng Anh'] != null ? ' (${data['Tên tiếng Anh']})' : '';
        final intro = data['Giới thiệu'] ?? 'Không có thông tin.';
        final similarity = (data['Điểm similarity'] as num?)?.toDouble() ?? 0.0;
        final highlights = data['Điểm đặc sắc'] as List<dynamic>? ?? [];
        final funFacts = data['Sự thật thú vị'] as List<dynamic>? ?? [];
        final story = data['Câu chuyện'] ?? '';
        final wikiUrl = data['Wikipedia'] ?? '';

        final highlightsString = highlights.map((e) => '- $e').join('\n');
        final funFactsString = funFacts.map((e) => '- $e').join('\n');

        final String resultString = '''
### $name$engName

**Độ tương đồng:** ${(similarity * 100).toStringAsFixed(1)}%

---

**Giới thiệu:**
$intro

**Điểm đặc sắc:**
$highlightsString

**Sự thật thú vị:**
$funFactsString

**Câu chuyện:**
>$story

**Tìm hiểu thêm:**
[$wikiUrl]($wikiUrl)
''';

        widget.onNavigate(
          'aiLandmarkResult',
          data: {'markdownContent': resultString},
        );
      } else {
        final String errorMessage = result['detail'] ??
            'Không nhận diện được địa danh từ ảnh. (${response.statusCode})';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi kết nối tới AI: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }

    final bool isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (_isProcessing) ...[
            Container(color: Colors.black.withValues(alpha: 0.5)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _mode == CameraMode.ai
                        ? "AI đang nhận diện..."
                        : "Đang xử lý...",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDesktop) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModeButton(CameraMode.normal, "Chụp ảnh"),
                        const SizedBox(width: 20),
                        _buildModeButton(CameraMode.ai, "AI Nhận diện"),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    const Text(
                      "Chế độ AI Landmark",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios,
                            color: Colors.white, size: 30),
                        onPressed: _flipCamera,
                      ),
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                  color: _mode == CameraMode.ai
                                      ? Colors.cyanAccent
                                      : Colors.white,
                                  width: 3)),
                        ),
                      ),
                      const SizedBox(width: 48), // Placeholder for symmetry
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(CameraMode mode, String text) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: _toggleMode,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
              width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
