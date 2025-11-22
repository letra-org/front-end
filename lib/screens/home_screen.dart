import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  String _sortOrder = 'newest';

  List<Map<String, dynamic>> _allPosts = [];
  bool _isLoading = true;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    await Future.wait([_loadPosts(), _loadUserData()]);

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null && user['avatar_url'] != null) {
          if (mounted) {
            setState(() {
              _avatarUrl = user['avatar_url'];
            });
          }
        }
      }
    } catch (e) {
      print("Lỗi khi tải avatar người dùng trên home_screen: $e");
    }
  }

  Future<void> _loadPosts() async {
    try {
      final String rawContent = await rootBundle.loadString('assets/home_status/status.txt');
      String content = rawContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final List<String> postBlocks = content.split(RegExp(r'\n{2,}')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      List<Map<String, dynamic>> loadedPosts = [];
      int postId = 1;
      for (final block in postBlocks) {
        final Map<String, dynamic> post = {'id': postId++};
        final lines = block.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();
            if (key == 'likes' || key == 'comments') {
              post[key] = int.tryParse(value) ?? 0;
            } else {
              post[key] = value;
            }
          }
        }
        if (post.containsKey('title') && post.containsKey('image')) {
          loadedPosts.add(post);
        }
      }
      if (mounted) {
        setState(() {
          _allPosts = loadedPosts;
          _currentPage = 1;
        });
      }
    } catch (e) {
      print('Error reading file assets/home_status/status.txt: $e');
    }
  }

  List<Map<String, dynamic>> get _sortedPosts {
    final sorted = List<Map<String, dynamic>>.from(_allPosts);
    sorted.sort((a, b) {
      if (_sortOrder == 'newest') {
        return b['date'].compareTo(a['date']);
      } else {
        return a['date'].compareTo(b['date']);
      }
    });
    return sorted;
  }

  List<Map<String, dynamic>> get _currentPosts {
    if (_allPosts.isEmpty) return [];
    final sortedPosts = _sortedPosts;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return sortedPosts.sublist(startIndex, endIndex > sortedPosts.length ? sortedPosts.length : endIndex);
  }

  int get _totalPages => (_sortedPosts.length / _itemsPerPage).ceil();

  void _toggleSort() {
    setState(() {
      _sortOrder = _sortOrder == 'newest' ? 'oldest' : 'newest';
      _currentPage = 1;
    });
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        widget.onNavigate('login');
      },
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: const Color(0xFF2563EB),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => widget.onNavigate('userProfile'),
                        borderRadius: BorderRadius.circular(20),
                        child: ClipOval(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _avatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _avatarUrl!,
                                    placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2.0),
                                    errorWidget: (context, url, error) => Image.asset('assets/images/user/avatar.jpg', fit: BoxFit.cover),
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset('assets/images/user/avatar.jpg', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for places, posts...',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, size: 20),
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                            _sortOrder == 'newest' ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white),
                        onPressed: _toggleSort,
                        tooltip: _sortOrder == 'newest' ? 'Newest' : 'Oldest',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allPosts.isEmpty
                      ? const Center(child: Text('No posts found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _currentPosts.length,
                          itemBuilder: (context, index) {
                            final post = _currentPosts[index];
                            return _buildPostCard(post, isDarkMode);
                          },
                        ),
            ),
            if (!_isLoading && _totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((255 * 0.05).toInt()), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null, icon: const Icon(Icons.chevron_left)),
                    ...List.generate(_totalPages > 5 ? 5 : _totalPages, (index) {
                      int pageNum;
                      if (_totalPages <= 5) { pageNum = index + 1; } 
                      else if (_currentPage <= 3) { pageNum = index + 1; }
                      else if (_currentPage >= _totalPages - 2) { pageNum = _totalPages - 4 + index; } 
                      else { pageNum = _currentPage - 2 + index; }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => _changePage(pageNum),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: _currentPage == pageNum ? const Color(0xFF2563EB) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _currentPage == pageNum ? const Color(0xFF2563EB) : Colors.grey),
                            ),
                            child: Center(child: Text(pageNum.toString(), style: TextStyle(color: _currentPage == pageNum ? Colors.white : (isDarkMode ? Colors.white : Colors.black)))),
                          ),
                        ),
                      );
                    }),
                    IconButton(onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => widget.onNavigate('friends'),
          label: const Text('Friends'),
          icon: const Icon(Icons.people),
          backgroundColor: const Color(0xFF2563EB),
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          currentScreen: 'home',
          onNavigate: widget.onNavigate,
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(post['image'], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image, size: 50)));
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(post['location'], style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                    const Spacer(),
                    Text(post['date'], style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[500] : Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post['likes']}', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                    const SizedBox(width: 16),
                    Icon(Icons.comment_outlined, size: 20, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post['comments']}', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
