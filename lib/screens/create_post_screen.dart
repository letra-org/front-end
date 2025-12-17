import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';

class CreatePostScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const CreatePostScreen({super.key, required this.onNavigate});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  String? _avatarUrl;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Placeholder: In a real app, you'd get this from a state management solution
    // after login. For now, we simulate it.
    setState(() {
      _avatarUrl = 'https://source.unsplash.com/random/100x100?face';
      _userName = 'Your Name';
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackbar('Failed to pick image: $e', isError: true);
    }
  }


  Future<void> _handlePost() async {
    if (_textController.text.trim().isEmpty && _imageFile == null) {
      _showSnackbar('Please add content or an image to post.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar('Authentication error. Please log in again.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.createPost));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add content field
      if (_textController.text.isNotEmpty) {
        request.fields['content'] = _textController.text;
      }

      // Add media file if selected
      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'media', // This must match the API's expected field name
            _imageFile!.path,
          ),
        );
      }

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackbar('Post created successfully!');
        // Navigate back to home or another screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onNavigate('home');
        });
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Failed to create post. Status: ${response.statusCode}, Body: $responseBody');
      }

    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
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
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
                  backgroundImage: _avatarUrl != null ? CachedNetworkImageProvider(_avatarUrl!) : null,
                  child: _avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            const SizedBox(height: 20),
            if (_imageFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
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
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
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
        child: IconButton(
          icon: const Icon(Icons.photo_library, color: Color(0xFF2563EB), size: 30),
          onPressed: _pickImage,
        ),
      ),
    );
  }
}
