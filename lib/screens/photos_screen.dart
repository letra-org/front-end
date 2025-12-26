import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:async/async.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../l10n/app_localizations.dart';
import 'camera_screen.dart';

class PhotosScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;
  final bool isPickerMode;

  const PhotosScreen({
    super.key,
    required this.onNavigate,
    this.isPickerMode = false,
  });

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<File> _photos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() { _isLoading = true; });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${directory.path}/photos');
      if (await photosDir.exists()) {
        final files = await photosDir.list().toList();
        _photos = files.whereType<File>().toList();
      } else {
        _photos = [];
      }
    } catch (e) {
      print('Error loading photos: $e');
      _photos = [];
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _deletePhoto(File photo) async {
    try {
      await photo.delete();
      _loadPhotos(); // Refresh the list
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  Future<void> _pickAndSaveImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${directory.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(image.path).copy('${photosDir.path}/$fileName');
      _loadPhotos(); // Refresh the list
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.get('photos_library')),
        leading: widget.isPickerMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => widget.onNavigate('settings'),
              ),
        actions: [
          if (!widget.isPickerMode)
            IconButton(
                icon: const Icon(Icons.add_photo_alternate),
                onPressed: _pickAndSaveImage,
                tooltip: 'Thêm từ thư viện',
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CameraScreen(onNavigate: widget.onNavigate)),
                );
                if (result == true) {
                  _loadPhotos(); // Refresh photos after taking a new one
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(
                  child: Text(
                    appLocalizations.get('no_photos_message'),
                    textAlign: TextAlign.center,
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return GestureDetector(
                      onTap: () {
                        if (widget.isPickerMode) {
                          Navigator.of(context).pop(photo);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoViewScreen(photo: photo, onDelete: _deletePhoto, onNavigate: widget.onNavigate),
                            ),
                          );
                        }
                      },
                      child: Image.file(photo, fit: BoxFit.cover),
                    );
                  },
                ),
      bottomNavigationBar: widget.isPickerMode
          ? null
          : BottomNavigationBarWidget(
              currentScreen: 'photos',
              onNavigate: widget.onNavigate,
            ),
    );
  }
}

class PhotoViewScreen extends StatefulWidget {
  final File photo;
  final Future<void> Function(File) onDelete;
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const PhotoViewScreen({super.key, required this.photo, required this.onDelete, required this.onNavigate});

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  bool _isProcessing = false;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _updateLandmark() async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });

    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi xác thực. Vui lòng đăng nhập lại.')),
        );
        setState(() { _isProcessing = false; });
      }
      return;
    }

    try {
      var stream = http.ByteStream(DelegatingStream.typed(widget.photo.openRead()));
      var length = await widget.photo.length();

      var uri = Uri.parse(ApiConfig.landmarkDetectUpload);

      var request = http.MultipartRequest("POST", uri);
      var multipartFile = http.MultipartFile('file', stream, length,
          filename: p.basename(widget.photo.path),
          contentType: MediaType('image', 'jpeg'));

      request.files.add(multipartFile);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      var response = await request.send();

      if (!mounted) return;

      final responseBody = await response.stream.bytesToString();
      final result = jsonDecode(responseBody);

      if (response.statusCode == 200 && result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        
        final name = data['Tên'] ?? 'N/A';
        final engName = data['Tên tiếng Anh'] != null ? ' (${data['Tên tiếng Anh']})' : '';
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
          data: {'markdownContent': resultString, 'from': 'photos'},
        );
      } else {
        final String errorMessage = result['detail'] ?? 'Không nhận diện được địa danh từ ảnh. (${response.statusCode})';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome), // AI Icon
            onPressed: _updateLandmark,
            tooltip: 'Cập nhật Landmark',
          ),
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: () async {
                try {
                  await Gal.putImage(widget.photo.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.get('save_success'))),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.get('save_general_error')}$e')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có chắc chắn muốn xóa ảnh này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirmDelete == true) {
                  await widget.onDelete(widget.photo);
                  if (mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: FileImage(widget.photo),
            heroAttributes: PhotoViewHeroAttributes(tag: widget.photo.path),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("AI đang nhận diện...", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ), 
              ),
            ),
        ],
      ),
    );
  }
}
