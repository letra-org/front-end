import 'dart:io';
import 'dart:convert';
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
  List<File> _imageFiles = [];
  bool _isLoading = false;
  bool _isAiGenerating = false;
  bool _isStoryGenerating = false;

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

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(pickedFiles.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      _showSnackbar('Failed to pick images: $e', isError: true);
    }
  }

  Future<void> _generateAICaption() async {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_imageFiles.isEmpty) {
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

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Field name from the API spec
          _imageFiles.first.path,
        ),
      );

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
        _showSnackbar('AI generated a caption for you! ✨');
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

  Future<void> _generateAIAlbumStory() async {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_imageFiles.length < 2) {
      _showSnackbar(appLocalizations.get('select_multiple_images'),
          isError: true);
      return;
    }

    setState(() => _isStoryGenerating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar(appLocalizations.get('auth_error'), isError: true);
      setState(() => _isStoryGenerating = false);
      return;
    }

    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(ApiConfig.createAlbumStory));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      for (var file in _imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files', // Field name from the API spec (array)
            file.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));

        final String tripTitle = data['trip_title'] ?? 'My Trip';
        final String summary = data['overall_summary'] ?? '';
        final List<dynamic> timeline = data['timeline'] ?? [];

        StringBuffer sb = StringBuffer();
        sb.writeln('📍 $tripTitle');
        sb.writeln('\n$summary');

        if (timeline.isNotEmpty) {
          sb.writeln('\n--- STORY TIMELINE ---');
          for (var item in timeline) {
            sb.writeln('\n🕒 ${item['time_of_day'] ?? ''}');
            if (item['location_guess'] != null) {
              sb.writeln('🗺️ ${item['location_guess']}');
            }
            sb.writeln('${item['story_caption'] ?? ''}');
          }
        }

        setState(() {
          _textController.text = sb.toString();
        });
        _showSnackbar('AI has composed your travel diary! 📖✨');
      } else {
        throw Exception(
            'Failed to generate story. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('${appLocalizations.get('ai_album_story_error')}: $e',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isStoryGenerating = false);
      }
    }
  }

  Future<void> _handlePost() async {
    if (_textController.text.trim().isEmpty && _imageFiles.isEmpty) {
      _showSnackbar('Please add content or an image to post.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar('Authentication error. Please log in again.',
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

      // Add media files if selected
      for (var file in _imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'media', // Adjust if API expects an array name like 'media[]'
            file.path,
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
        throw Exception(
            'Failed to create post. Status: ${response.statusCode}, Body: $responseBody');
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
                  backgroundImage: _avatarUrl != null
                      ? CachedNetworkImageProvider(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null ? const Icon(Icons.person) : null,
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
            if (_imageFiles.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _isAiGenerating || _isStoryGenerating
                        ? null
                        : _generateAICaption,
                    icon: _isAiGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF1E88E5)),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      _isAiGenerating
                          ? appLocalizations.get('ai_generating')
                          : appLocalizations.get('generate_ai_caption'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  if (_imageFiles.length >= 2)
                    TextButton.icon(
                      onPressed: _isAiGenerating || _isStoryGenerating
                          ? null
                          : _generateAIAlbumStory,
                      icon: _isStoryGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.purple),
                            )
                          : const Icon(Icons.auto_stories,
                              size: 18, color: Colors.purple),
                      label: Text(
                        _isStoryGenerating
                            ? 'AI is writing...'
                            : appLocalizations.get('generate_ai_story'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            if (_imageFiles.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.file(
                              _imageFiles[index],
                              fit: BoxFit.cover,
                              width: 300,
                              height: 200,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 20,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageFiles.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: const Icon(Icons.photo_library,
              color: Color(0xFF1E88E5), size: 30),
          onPressed: _pickImages,
        ),
      ),
    );
  }
}
