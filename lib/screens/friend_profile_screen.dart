import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../constants/api_config.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendAvatar;

  const FriendProfileScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatar,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  Map<String, dynamic> _userInfo = {};
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userInfo = {
      'full_name': widget.friendName,
      'avatar_url': widget.friendAvatar,
    };
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getAuthToken();
      if (token != null) {
        await Future.wait([
          _fetchFriendInfo(token),
          _fetchFriendPosts(token),
        ]);
      }
    } catch (e) {
      debugPrint('Error loading friend data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchFriendInfo(String token) async {
    try {
      final intId = int.tryParse(widget.friendId);
      if (intId == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.getUserById(intId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _userInfo = {
              ..._userInfo, // Keep existing data like name/avatar as fallback or initial
              'full_name': userData['full_name'],
              'username': userData['username'],
              'email': userData[
                  'email'], // Depending on privacy settings, might not be visible
              'phone': userData[
                  'phone'], // Depending on privacy settings, might not be visible
              'avatar_url': userData['avatar_url'],
            };
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching friend info: $e");
    }
  }

  Future<void> _fetchFriendPosts(String token) async {
    try {
      final uri = Uri.parse(ApiConfig.getPosts)
          .replace(queryParameters: {'user_id': widget.friendId});
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final posts = json.decode(utf8.decode(response.bodyBytes)) as List;
        if (mounted) {
          setState(() {
            _userPosts = List<Map<String, dynamic>>.from(posts);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching friend posts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFriendData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFF1E88E5),
              title: Text(widget.friendName), // Use passed name initially
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildProfileHeader(context),
            ),
            SliverToBoxAdapter(
              child: _buildInfoCard(context, appLocalizations),
            ),
            _buildPostsSection(appLocalizations),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          Text(
            _userInfo['full_name'] ?? widget.friendName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (_userInfo['username'] != null)
            Text(
              '@${_userInfo['username']}',
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
          ? Text(
              widget.friendName.isNotEmpty
                  ? widget.friendName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 40),
            )
          : null,
    );
  }

  Widget _buildInfoCard(
      BuildContext context, AppLocalizations appLocalizations) {
    // If we don't have extra info, we might skip this or show limited info
    // Assuming backend returns email/phone for friends for now, or we just show what we have.
    // If fields are missing, we can hide the rows.

    final email = _userInfo['email'];
    final phone = _userInfo['phone'];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if ((email == null || email.isEmpty) && (phone == null || phone.isEmpty)) {
      return const SizedBox.shrink();
    }

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
            if (email != null && email.isNotEmpty)
              _buildInfoTableRow(Icons.email_outlined,
                  appLocalizations.get('email_label'), email, isDarkMode),
            if (phone != null && phone.isNotEmpty)
              _buildInfoTableRow(Icons.phone_outlined,
                  appLocalizations.get('phone_label'), phone, isDarkMode),
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
              // subtitle: Text(post['created_at'] ?? ''),
            ),
          );
        },
        childCount: _userPosts.length,
      ),
    );
  }
}
