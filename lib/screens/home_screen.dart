import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/api_config.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../l10n/app_localizations.dart';
import './post_detail_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() => _isLoading = true);
    }

    await Future.delayed(const Duration(seconds: 2));

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
        final List<dynamic> postsData =
            json.decode(utf8.decode(response.bodyBytes));

        // Fetch user details for each post
        final List<Map<String, dynamic>> newPosts = [];
        for (var post in postsData) {
          final userId = post['user_id'];
          String authorName = 'Unknown User';
          String? avatarUrl;

          if (userId != null) {
            try {
              final userResponse = await http.get(
                Uri.parse(ApiConfig.getUserById(userId)),
                headers: {'Authorization': 'Bearer $token'},
              );

              if (userResponse.statusCode == 200) {
                final userData =
                    json.decode(utf8.decode(userResponse.bodyBytes));
                authorName = userData['username'] ?? 'Unknown User';
                avatarUrl = userData['avatar_url'];
              }
            } catch (e) {
              print('Error fetching user $userId: $e');
            }
          }

          newPosts.add({
            'id': post['id'].toString(),
            'author': authorName,
            'avatarUrl': avatarUrl,
            'time': post['created_at'],
            'content': post['content'],
            'imageUrl': post['media_url'],
            'likes': post['likes_count'] ?? 0,
            'comments': post['comments_count'] ?? 0,
          });
        }

        if (mounted) {
          setState(() {
            if (loadMore) {
              _posts.addAll(newPosts);
            } else {
              _posts = newPosts;
            }
            _isLoading = false;
          });
        }
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

  // Function to format the post timestamp
  String _formatPostTime(String? isoTimestamp) {
    if (isoTimestamp == null) return '';
    try {
      final postTime = DateTime.parse(isoTimestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(postTime);

      if (difference.inDays >= 3) {
        return DateFormat('dd/MM/yyyy').format(postTime);
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
      return ''; // Return empty string if parsing fails
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final filteredPosts = _posts.where((post) {
      final content = post['content']?.toString().toLowerCase() ?? '';
      return content.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => widget.onNavigate('userProfile'),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: _avatarUrl != null
                    ? CachedNetworkImageProvider(_avatarUrl!)
                    : null,
                child: _avatarUrl == null
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: appLocalizations.get('Tìm kiếm'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
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
            ? _buildPostsLoading(context)
            : filteredPosts.isEmpty
                ? Center(
                    child: Text(_searchQuery.isNotEmpty
                        ? 'No posts found'
                        : appLocalizations.get('no_posts_to_show')))
                : ListView.builder(
                    itemCount: filteredPosts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredPosts.length) {
                        // Only show load more if not searching, or handle pagination with search (complex)
                        // For now, hide load more if searching to avoid confusion or just keep it.
                        // If searching local list, load more adds to list and might match.
                        return _searchQuery.isEmpty
                            ? _buildLoadMoreButton(appLocalizations)
                            : const SizedBox(height: 50);
                      }
                      final post = filteredPosts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailScreen(post: post)),
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

  Widget _buildPostsLoading(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => _buildPostCardSkeleton(),
      ),
    );
  }

  Widget _buildPostCardSkeleton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: Colors.white),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 16, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 6),
            Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 14,
                color: Colors.white),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 200, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(
      Map<String, dynamic> post, AppLocalizations appLocalizations) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(post, appLocalizations),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              post['content'] ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (post['imageUrl'] != null)
            CachedNetworkImage(
              imageUrl: post['imageUrl'],
              placeholder: (context, url) =>
                  Container(height: 200, color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          _buildPostActions(post, appLocalizations),
        ],
      ),
    );
  }

  Widget _buildPostHeader(
      Map<String, dynamic> post, AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: post['avatarUrl'] != null
                ? CachedNetworkImageProvider(post['avatarUrl'])
                : null,
            child: post['avatarUrl'] == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['author'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_formatPostTime(post['time']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions(
      Map<String, dynamic> post, AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildActionButton(
              Icons.thumb_up_outlined, '${post['likes']}', () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
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
