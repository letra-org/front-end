import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'single_purpose_camera_screen.dart';
import 'post_detail_screen.dart';
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
      debugPrint("Lỗi khi lấy token: $e");
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
      debugPrint('LỖI KHI TẢI DỮ LIỆU: $e');
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
          _userPosts = List<Map<String, dynamic>>.from(posts.map((post) => {
                ...post,
                'liked_by': List<int>.from(post['likes'] ?? []),
                'likes_count': post['likes_count'] ?? 0,
              }));
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi tải bài viết của người dùng: $e");
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
      debugPrint("Error picking image from gallery: $e");
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
        debugPrint(
            "UPLOAD AVATAR ERROR: ${response.statusCode} - ${response.body}");
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

  Future<void> _deletePost(int postId) async {
    final token = await _getAuthToken();
    if (token == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deletePost(postId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.get('delete_post_success'))),
          );
          await _fetchUserPosts();
        }
      } else {
        throw Exception(
            AppLocalizations.of(context)!.get('delete_post_failed'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(int postId) async {
    final token = await _getAuthToken();
    if (token == null) return;

    final currentUserId = _userInfo['id'];
    if (currentUserId == null) return;

    final int index = _userPosts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    final post = _userPosts[index];
    final List<int> likedBy = post['liked_by'];
    final bool isLiked = likedBy.contains(currentUserId);

    // Optimistic update
    setState(() {
      if (isLiked) {
        likedBy.remove(currentUserId);
        post['likes_count'] = (post['likes_count'] as int) - 1;
      } else {
        likedBy.add(currentUserId);
        post['likes_count'] = (post['likes_count'] as int) + 1;
      }
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.likePost(postId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        // Revert
        setState(() {
          if (isLiked) {
            likedBy.add(currentUserId);
            post['likes_count'] = (post['likes_count'] as int) + 1;
          } else {
            likedBy.remove(currentUserId);
            post['likes_count'] = (post['likes_count'] as int) - 1;
          }
        });
      }
    } catch (e) {
      // Revert
      setState(() {
        if (isLiked) {
          likedBy.add(currentUserId);
          post['likes_count'] = (post['likes_count'] as int) + 1;
        } else {
          likedBy.remove(currentUserId);
          post['likes_count'] = (post['likes_count'] as int) - 1;
        }
      });
      debugPrint("Error toggling like: $e");
    }
  }

  void _confirmDelete(int postId) {
    final appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.get('delete_post_confirm_title')),
        content: Text(appLocalizations.get('delete_post_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.get('no_label')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(postId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(appLocalizations.get('yes_label')),
          ),
        ],
      ),
    );
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
          final postData = _userPosts[index];

          // Map data to match PostDetailScreen expectations (same as home_screen.dart)
          final Map<String, dynamic> post = {
            'id': postData['id'].toString(),
            'user_id': postData['user_id'],
            'author': _userInfo['full_name'] ?? 'User',
            'avatarUrl': _userInfo['avatar_url'],
            'time': postData['created_at'],
            'content': postData['content'],
            'imageUrl': postData['media_url'],
            'likes': postData['likes_count'] ?? 0,
            'liked_by': postData['liked_by'] ?? [],
            'comments': postData['comments_count'] ?? 0,
          };

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: post)),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Profile Info + Delete)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20, // Match home screen radius
                          backgroundImage: post['avatarUrl'] != null
                              ? CachedNetworkImageProvider(post['avatarUrl'])
                              : null,
                          child: post['avatarUrl'] == null
                              ? const Icon(Icons.person, size: 24)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['author'] ?? 'User',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatPostTime(post['time']),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _confirmDelete(int.parse(post['id']));
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      post['content'] ?? '',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Image
                  if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: post['imageUrl'],
                      placeholder: (context, url) =>
                          Container(height: 200, color: Colors.grey[200]),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),

                  // Actions (Likes)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildLikeButton(post, postData['id']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: _userPosts.length,
      ),
    );
  }

  Widget _buildLikeButton(Map<String, dynamic> post, int postId) {
    // Note: post is the mapped data for detail screen, but we need the raw list for reference updates
    // Actually we can use the post data provided since we map it directly
    final List<int> likedBy = List<int>.from(post['liked_by'] ?? []);
    final currentUserId = _userInfo['id'];
    final bool isLiked =
        currentUserId != null && likedBy.contains(currentUserId);

    return TextButton.icon(
      onPressed: () => _toggleLike(postId),
      icon: Icon(
        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
        size: 20,
        color: isLiked ? Colors.blue : Colors.grey[700],
      ),
      label: Text(
        '${post['likes']}',
        style: TextStyle(
          color: isLiked ? Colors.blue : Colors.grey[700],
          fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
