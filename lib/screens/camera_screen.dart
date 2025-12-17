import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

  final String _gradioApiUrl = 'http://127.0.0.1:7860/api/gradio_predict';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    final cameraDescription = _cameras![_isFrontCamera ? 1 : 0];
    _controller = CameraController(cameraDescription, ResolutionPreset.high, enableAudio: false);

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
    setState(() {
      _mode = _mode == CameraMode.normal ? CameraMode.ai : CameraMode.normal;
    });
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() { _isProcessing = true; });

    try {
      final image = await _controller!.takePicture();

      if (_mode == CameraMode.normal) {
        await _saveImageNormally(image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ảnh đã được lưu!')),
          );
        }
      } else { // AI Mode
        await _sendToAIAndNavigate(image);
      }
    } catch (e) {
      print("Error during picture taking/processing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
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

    try {
      final response = await http.post(
        Uri.parse(_gradioApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "data": [
            "data:image/jpeg;base64,$base64Image",
            3 // top_k value
          ]
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final markdownContent = result['data'][0] as String;

        widget.onNavigate(
          'aiLandmarkResult',
          data: {'markdownContent': markdownContent},
        );
      } else {
        throw Exception('Lỗi từ máy chủ AI: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

 @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (_isProcessing) ...[
            Container(color: Colors.black.withOpacity(0.5)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _mode == CameraMode.ai ? "AI đang nhận diện..." : "Đang xử lý...",
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
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeButton(CameraMode.normal, "Chụp ảnh"),
                      const SizedBox(width: 20),
                      _buildModeButton(CameraMode.ai, "AI Nhận diện"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                        onPressed: _flipCamera,
                      ),
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: _mode == CameraMode.ai ? Colors.cyanAccent : Colors.white, width: 3)
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
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
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.white, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
