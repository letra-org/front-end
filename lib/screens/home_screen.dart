import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants/api_config.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../l10n/app_localizations.dart';
import './post_detail_screen.dart'; // Import the new detail screen

class HomeScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _avatarUrl;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() => _isLoading = true);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar('Authentication token not found', isError: true);
      if (mounted && !loadMore) setState(() => _isLoading = false);
      return;
    }

    final offset = loadMore ? _posts.length : 0;
    final uri = Uri.parse('${ApiConfig.getPosts}?offset=$offset&limit=20');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> postsData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          final newPosts = postsData.map((post) {
            final user = post['user'] as Map<String, dynamic>?;
            return {
              'id': post['id'].toString(),
              'author': user?['full_name'] ?? 'Unknown User',
              'avatarUrl': user?['avatar_url'],
              'time': post['created_at'], // Store the original timestamp
              'content': post['content'],
              'imageUrl': post['media_url'],
              'likes': post['likes_count'] ?? 0,
              'comments': post['comments_count'] ?? 0,
            };
          }).toList();

          if (loadMore) {
            _posts.addAll(newPosts);
          } else {
            _posts = newPosts;
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(e.toString(), isError: true);
        if (!loadMore) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => widget.onNavigate('userProfile'),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: _avatarUrl != null ? CachedNetworkImageProvider(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.person, size: 24) : null,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => widget.onNavigate('createPost'),
            tooltip: appLocalizations.get('create_post_tooltip'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchPosts(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? Center(child: Text(appLocalizations.get('no_posts_to_show')))
                : ListView.builder(
                    itemCount: _posts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        return _buildLoadMoreButton(appLocalizations);
                      }
                      final post = _posts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                          );
                        },
                        child: _buildPostCard(post, appLocalizations),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentScreen: 'home',
        onNavigate: widget.onNavigate,
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, AppLocalizations appLocalizations) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(post, appLocalizations),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              post['content'] ?? '',
              maxLines: 4, // Limit lines in the list view
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (post['imageUrl'] != null)
            CachedNetworkImage(
              imageUrl: post['imageUrl'],
              placeholder: (context, url) => Container(height: 200, color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              width: double.infinity,
              height: 200, // Fixed height for consistency
              fit: BoxFit.cover,
            ),
          _buildPostActions(post, appLocalizations),
        ],
      ),
    );
  }

  Widget _buildPostHeader(Map<String, dynamic> post, AppLocalizations appLocalizations) {
    // A proper implementation would format the `post['time']` timestamp.
    // For now, we use a localized string for "Just now".
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: post['avatarUrl'] != null ? CachedNetworkImageProvider(post['avatarUrl']) : null,
            child: post['avatarUrl'] == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['author'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(appLocalizations.get('just_now'), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions(Map<String, dynamic> post, AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(Icons.thumb_up_outlined, '${post['likes']}', () {}),
          _buildActionButton(Icons.comment_outlined, '${post['comments']}', () {}),
          _buildActionButton(Icons.share_outlined, appLocalizations.get('share'), () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.grey[700]),
      label: Text(label, style: TextStyle(color: Colors.grey[700])),
    );
  }

  Widget _buildLoadMoreButton(AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: TextButton(
          onPressed: () => _fetchPosts(loadMore: true),
          child: Text(appLocalizations.get('load_more')),
        ),
      ),
    );
  }
}
