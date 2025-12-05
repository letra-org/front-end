import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import 'photos_screen.dart'; // Import PhotosScreen

class CreatePostScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;

  const CreatePostScreen({super.key, required this.onNavigate});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  
  File? _imageFile;
  String? _avatarUrl;
  String _fullName = 'User';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        final user = data['user'] as Map<String, dynamic>?;

        if (user != null && mounted) {
          setState(() {
            _avatarUrl = user['avatar_url'] as String?;
            _fullName = user['full_name'] as String? ?? 'User';
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _showImageSourceDialog() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSourceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.get('image_source_title')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSourceType.gallery),
            child: Text(appLocalizations.get('device_gallery')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSourceType.appPhotos),
            child: Text(appLocalizations.get('app_photos')),
          ),
        ],
      ),
    );

    if (source == null) return;

    if (source == ImageSourceType.gallery) {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } else if (source == ImageSourceType.appPhotos) {
      final selectedPhoto = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => PhotosScreen(
            onNavigate: widget.onNavigate,
            isPickerMode: true,
          ),
        ),
      );
      if (selectedPhoto != null) {
        setState(() {
          _imageFile = selectedPhoto;
        });
      }
    }
  }

  Future<void> _submitPost() async {
    // ignore: unused_local_variable
    final appLocalizations = AppLocalizations.of(context)!;
    if (_titleController.text.isEmpty || _locationController.text.isEmpty || _captionController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin và chọn ảnh')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://letra-org.fly.dev/posts/');
      final request = http.MultipartRequest('POST', url);
      request.fields['title'] = _titleController.text;
      request.fields['location'] = _locationController.text;
      request.fields['caption'] = _captionController.text;
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      final response = await request.send();

      if (response.statusCode == 201) {
        widget.onNavigate('home');
      } else if (response.statusCode == 422) {
        throw Exception('Dữ liệu không hợp lệ');
      } else {
        throw Exception('Lỗi không xác định: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đăng bài: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close), // Changed to close icon
          onPressed: () => widget.onNavigate('home'),
        ),
        title: Text(appLocalizations.get('create_post_title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : Text(appLocalizations.get('post_button')),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: _avatarUrl != null ? CachedNetworkImageProvider(_avatarUrl!) : null,
                        child: _avatarUrl == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(_fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(fontSize: 22),
                    decoration: InputDecoration(
                      hintText: appLocalizations.get('caption_label'),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                  if (_imageFile != null)
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 4,
                          child: IconButton(
                            icon: const CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                            onPressed: () => setState(() => _imageFile = null),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            child: Column(
              children: [
                 _buildTextField(appLocalizations.get('title_label'), _titleController, Icons.title),
                 const Divider(height: 1, indent: 56),
                _buildTextField(appLocalizations.get('location_label'), _locationController, Icons.location_on_outlined),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: Text(appLocalizations.get('add_image_button')),
                  onTap: _showImageSourceDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

enum ImageSourceType { gallery, appPhotos }
