import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';
import 'photos_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const CreatePostScreen({super.key, required this.onNavigate});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  bool _isAiGenerating = false;

  String? _avatarUrl;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
            _userName =
                user['full_name'] as String? ?? user['username'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print("Lỗi khi tải dữ liệu người dùng trên create_post_screen: $e");
    }
  }

  Future<void> _pickImage() async {
    final appLocalizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(appLocalizations.get('device_gallery')),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  try {
                    final XFile? pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path);
                      });
                    }
                  } catch (e) {
                    _showSnackbar(appLocalizations.get('pick_image_error'), isError: true);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.collections),
                title: Text(appLocalizations.get('app_photos')),
                onTap: () async {
                  Navigator.pop(context);
                  final File? pickedPhoto = await Navigator.push<File>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotosScreen(
                        onNavigate: widget.onNavigate,
                        isPickerMode: true,
                      ),
                    ),
                  );

                  if (pickedPhoto != null) {
                    setState(() {
                      _imageFile = pickedPhoto;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateAICaption() async {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_imageFile == null) {
      _showSnackbar(appLocalizations.get('no_image_selected'), isError: true);
      return;
    }

    setState(() => _isAiGenerating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar(appLocalizations.get('auth_error'), isError: true);
      setState(() => _isAiGenerating = false);
      return;
    }

    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(ApiConfig.generateCaption));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      http.MultipartFile multipartFile;
      try {
        final mimeType = lookupMimeType(_imageFile!.path);
        final contentType =
            mimeType != null ? MediaType.parse(mimeType) : null;
        multipartFile = await http.MultipartFile.fromPath(
          'file', // Field name from the API spec
          _imageFile!.path,
          contentType: contentType,
        );
      } catch (e) {
        print('Error setting content type for AI caption: $e');
        multipartFile = await http.MultipartFile.fromPath(
          'file', // Field name from the API spec
          _imageFile!.path,
        );
      }

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final String caption = data['caption'] ?? '';
        final List<dynamic> hashtags = data['hashtags'] ?? [];

        String finalContent = caption;
        if (hashtags.isNotEmpty) {
          finalContent += '\n\n${hashtags.join(' ')}';
        }

        setState(() {
          _textController.text = finalContent;
        });
        _showSnackbar(appLocalizations.get('ai_caption_success'));
      } else {
        throw Exception(
            'Failed to generate caption. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('${appLocalizations.get('ai_caption_error')}: $e',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isAiGenerating = false);
      }
    }
  }

  Future<void> _handlePost() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_textController.text.trim().isEmpty && _imageFile == null) {
      _showSnackbar(appLocalizations.get('create_post_validation_error'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar(appLocalizations.get('auth_error'),
          isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(ApiConfig.createPost));

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add content field
      if (_textController.text.isNotEmpty) {
        request.fields['content'] = _textController.text;
      }

      // Add image file if selected
      if (_imageFile != null) {
        try {
          final mimeType = lookupMimeType(_imageFile!.path);
          final contentType =
              mimeType != null ? MediaType.parse(mimeType) : null;

          request.files.add(
            await http.MultipartFile.fromPath(
              'media',
              _imageFile!.path,
              contentType: contentType,
            ),
          );
        } catch (e) {
          print('Error setting content type: $e');
          // Fallback if mime detection fails
          request.files.add(
            await http.MultipartFile.fromPath(
              'media',
              _imageFile!.path,
            ),
          );
        }
      }

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackbar(appLocalizations.get('post_created_successfully'));
        // Navigate back to home or another screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onNavigate('home');
        });
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception(
            'Failed to create post. Status: ${response.statusCode}, Body: $responseBody');
      }
    } catch (e) {
      _showSnackbar(appLocalizations.get('create_post_error'), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.get('create_post_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => widget.onNavigate('home'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(appLocalizations.get('post_button')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(_avatarUrl!)
                          : null,
                  child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(_userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: appLocalizations.get('whats_on_your_mind'),
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            if (_imageFile != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _isAiGenerating ? null : _generateAICaption,
                    icon: _isAiGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF1E88E5)),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(appLocalizations.get('generate_caption')),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_imageFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(_imageFile!,
                        fit: BoxFit.cover, width: double.infinity),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child:
                            const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library,
                  color: Color(0xFF1E88E5), size: 30),
              onPressed: _pickImage,
            ),
          ],
        ),
      ),
    );
  }
}
