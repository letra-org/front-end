import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'single_purpose_camera_screen.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../constants/api_config.dart';

class UserProfileScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const UserProfileScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic> _userInfo = {};
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;
  bool _didRunInitialSetup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRunInitialSetup) {
      _didRunInitialSetup = true;
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadDataFromDevice();
      await _fetchUserPosts();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Future<void> _loadDataFromDevice() async {
    if (!mounted) return;
    final appLocalizations = AppLocalizations.of(context)!;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final dataPath = '${directory.path}/data/userdata.js';
      final dataFile = File(dataPath);

      if (await dataFile.exists()) {
        final content = await dataFile.readAsString();
        final jsonData = json.decode(content);
        final user = jsonData['user'] as Map<String, dynamic>?;

        if (user != null) {
          _userInfo = {
            'id': user['id'],
            'full_name':
                user['full_name'] as String? ?? appLocalizations.get('no_name'),
            'email':
                user['email'] as String? ?? appLocalizations.get('no_email'),
            'phone':
                user['phone'] as String? ?? appLocalizations.get('no_phone'),
            'username': user['username'] as String? ??
                appLocalizations.get('no_username'),
            'avatar_url': user['avatar_url'],
          };
        }
      }
    } catch (e) {
      print('LỖI KHI TẢI DỮ LIỆU: $e');
    }
  }

  Future<void> _fetchUserPosts() async {
    final userId = _userInfo['id'];
    if (userId == null) return;

    final token = await _getAuthToken();
    if (token == null) return;

    try {
      final uri = Uri.parse(ApiConfig.getPosts)
          .replace(queryParameters: {'user_id': userId.toString()});
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final posts = json.decode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _userPosts = List<Map<String, dynamic>>.from(posts);
        });
      }
    } catch (e) {
      print("Lỗi khi tải bài viết của người dùng: $e");
    }
  }

  Future<void> _handleAvatarChange(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  appLocalizations.get('image_source_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(appLocalizations.get('device_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(appLocalizations.get('app_photos')),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    final XFile? confirmedImage = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const SinglePurposeCameraScreen()),
    );

    if (confirmedImage != null) {
      _uploadAvatar(confirmedImage);
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _uploadAvatar(image);
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
    }
  }

  Future<void> _uploadAvatar(XFile imageFile) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final String? token = await _getAuthToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.get('auth_error'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(ApiConfig.updateUserAvatar);
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final updatedUser = json.decode(response.body);
        final directory = await getApplicationDocumentsDirectory();
        final dataFile = File('${directory.path}/data/userdata.js');
        Map<String, dynamic> localData = {};

        if (await dataFile.exists()) {
          localData = json.decode(await dataFile.readAsString());
        }

        localData['user'] = updatedUser;
        await dataFile.writeAsString(json.encode(localData));

        setState(() {
          _userInfo['avatar_url'] = updatedUser['avatar_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(appLocalizations.get('avatar_update_success'))),
        );
      } else {
        print("UPLOAD AVATAR ERROR: ${response.statusCode} - ${response.body}");
        throw Exception(
            '${appLocalizations.get('upload_failed')}${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${appLocalizations.get('generic_error')}${e.toString().replaceAll("Exception: ", "")}')),
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFF1E88E5),
              title: Text(appLocalizations.get('personal_info_title')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => widget.onNavigate('settings'),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildProfileHeader(appLocalizations),
            ),
            SliverToBoxAdapter(
              child: _buildInfoCard(appLocalizations),
            ),
            _buildPostsSection(appLocalizations),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations appLocalizations) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Stack(
            children: [
              _buildAvatar(),
              Positioned(
                bottom: 0,
                right: 4,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 24),
                    onPressed: () => _handleAvatarChange(context),
                    tooltip: appLocalizations.get('change_avatar_tooltip'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userInfo['full_name'] ?? '',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '@${_userInfo['username'] ?? ''}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = _userInfo['avatar_url'] as String?;
    return CircleAvatar(
      radius: 60,
      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? CachedNetworkImageProvider(avatarUrl)
          : null,
      child: (avatarUrl == null || avatarUrl.isEmpty)
          ? const Icon(Icons.person, size: 60, color: Colors.grey)
          : null,
    );
  }

  Widget _buildInfoCard(AppLocalizations appLocalizations) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          children: [
            _buildInfoTableRow(
                Icons.email_outlined,
                appLocalizations.get('email_label'),
                _userInfo['email'] ?? '',
                isDarkMode),
            _buildInfoTableRow(
                Icons.phone_outlined,
                appLocalizations.get('phone_label'),
                _userInfo['phone'] ?? '',
                isDarkMode),
          ],
        ),
      ),
    );
  }

  TableRow _buildInfoTableRow(
      IconData icon, String label, String value, bool isDarkMode) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
          child: Icon(icon,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(value,
              style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87)),
        ),
      ],
    );
  }

  String _formatPostTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays > 3) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildPostsSection(AppLocalizations appLocalizations) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
          child: Center(
              child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      )));
    }
    if (_userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Text(appLocalizations.get('no_posts_yet')),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = _userPosts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(post['content'] ?? ''),
              subtitle: Text(_formatPostTime(post['created_at'])),
            ),
          );
        },
        childCount: _userPosts.length,
      ),
    );
  }
}
