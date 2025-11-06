import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const LetraApp());
}

class LetraApp extends StatefulWidget {
  const LetraApp({super.key});

  @override
  State<LetraApp> createState() => _LetraAppState();
}

class _LetraAppState extends State<LetraApp> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Tạo thư mục "assets/images" trong bộ nhớ app nếu chưa có
  Future<Directory> _createAppImagesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/assets/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
      debugPrint("Thư mục đã được tạo: ${imagesDir.path}");
    }
    return imagesDir;
  }

  // Lưu ảnh vào thư mục "assets/images"
  Future<void> _saveImageToLocalAssets(String imagePath) async {
    final imagesDir = await _createAppImagesDir();
    final fileName = 'letra_${DateTime.now().millisecondsSinceEpoch}.png';
    final newPath = '${imagesDir.path}/$fileName';

    final imageFile = File(imagePath);
    await imageFile.copy(newPath);

    debugPrint("Ảnh đã được lưu vào: $newPath");
    setState(() {
      _image = File(newPath);
    });
  }

  // Mở camera
  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await _saveImageToLocalAssets(photo.path);
    }
  }

  // Mở thư viện ảnh
  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _saveImageToLocalAssets(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.lightBlueAccent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/letra_without_text.png', height: 40),
              const SizedBox(width: 10),
              const Text(
                "Letra App",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        body: Center(
          child: _image == null
              ? const Text(
            "Chưa có ảnh nào 🫠",
            style: TextStyle(fontSize: 18),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.file(
                _image!,
                height: 300,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              const Text("Ảnh đã được lưu trong bộ nhớ app!"),
            ],
          ),
        ),

        // ⚡ Floating buttons
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom: 16,
              left: 32,
              child: FloatingActionButton.small(
                heroTag: 'gallery',
                backgroundColor: Colors.white,
                onPressed: _openGallery,
                tooltip: 'Chọn ảnh từ thư viện',
                child: const Icon(Icons.photo_library, color: Colors.black),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 32,
              child: FloatingActionButton(
                heroTag: 'camera',
                backgroundColor: Colors.blueAccent,
                onPressed: _openCamera,
                tooltip: 'Chụp ảnh mới',
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
