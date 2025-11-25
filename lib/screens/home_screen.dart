import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SortCriteria { date, likes }
enum SortDirection { ascending, descending }

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  final TextEditingController _searchController = TextEditingController();

  SortCriteria _sortCriteria = SortCriteria.date;
  SortDirection _sortDirection = SortDirection.descending;

  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  bool _isLoading = true;
  String? _avatarUrl;
  final Set<int> _likedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPosts);
    _searchController.dispose();
    super.dispose();
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
            if (key == 'likes') {
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
          _filteredPosts = List.from(_allPosts);
          _sortPosts(); // Initial sort
          _currentPage = 1;
        });
      }
    } catch (e) {
      print('Error reading file assets/home_status/status.txt: $e');
    }
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        final title = post['title']?.toLowerCase() ?? '';
        return title.contains(query);
      }).toList();
      _sortPosts();
      _currentPage = 1;
    });
  }

  void _sortPosts() {
    _filteredPosts.sort((a, b) {
      int comparison;
      if (_sortCriteria == SortCriteria.date) {
        comparison = a['date'].compareTo(b['date']);
      } else {
        comparison = (a['likes'] as int).compareTo(b['likes'] as int);
      }
      return _sortDirection == SortDirection.ascending ? comparison : -comparison;
    });
  }

  void _toggleLike(int postId) {
    setState(() {
      final isLiked = _likedPostIds.contains(postId);
      final postIndex = _allPosts.indexWhere((p) => p['id'] == postId);
      if (postIndex == -1) return;

      if (isLiked) {
        _likedPostIds.remove(postId);
        _allPosts[postIndex]['likes']--;
      } else {
        _likedPostIds.add(postId);
        _allPosts[postIndex]['likes']++;
      }
      
      final filteredPostIndex = _filteredPosts.indexWhere((p) => p['id'] == postId);
      if (filteredPostIndex != -1) {
          _filteredPosts[filteredPostIndex]['likes'] = _allPosts[postIndex]['likes'];
      }
    });
  }

  List<Map<String, dynamic>> get _currentPosts {
    if (_filteredPosts.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredPosts.sublist(startIndex, endIndex > _filteredPosts.length ? _filteredPosts.length : endIndex);
  }

  int get _totalPages => (_filteredPosts.length / _itemsPerPage).ceil();

  void _setSortOrder(SortCriteria criteria, SortDirection direction) {
    setState(() {
      _sortCriteria = criteria;
      _sortDirection = direction;
      _sortPosts();
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
    final appLocalizations = AppLocalizations.of(context)!;

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
                          child: TextFormField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: appLocalizations.get('search_hint'),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<Function>(
                        icon: const Icon(Icons.sort, color: Colors.white),
                        tooltip: appLocalizations.get('sort_by'),
                        onSelected: (Function callback) => callback(),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: () => _setSortOrder(SortCriteria.date, SortDirection.descending),
                            child: Text(appLocalizations.get('sort_by_date_newest')),
                          ),
                          PopupMenuItem(
                            value: () => _setSortOrder(SortCriteria.date, SortDirection.ascending),
                            child: Text(appLocalizations.get('sort_by_date_oldest')),
                          ),
                          PopupMenuItem(
                            value: () => _setSortOrder(SortCriteria.likes, SortDirection.descending),
                            child: Text(appLocalizations.get('sort_by_likes_most')),
                          ),
                          PopupMenuItem(
                            value: () => _setSortOrder(SortCriteria.likes, SortDirection.ascending),
                            child: Text(appLocalizations.get('sort_by_likes_least')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPosts.isEmpty
                      ? Center(child: Text(appLocalizations.get('no_posts_found')))
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
          onPressed: () => widget.onNavigate('createPost'),
          label: Text(appLocalizations.get('create_post_title')),
          icon: const Icon(Icons.add),
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
                if (post['caption'] != null && post['caption']!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpandableText(post['caption']!),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _likedPostIds.contains(post['id']) ? Icons.favorite : Icons.favorite_border,
                        color: _likedPostIds.contains(post['id']) ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      onPressed: () => _toggleLike(post['id'] as int),
                    ),
                    Text('${post['likes']}', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
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

class ExpandableText extends StatefulWidget {
  final String text;
  const ExpandableText(this.text, {super.key});

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, constraints) {
      final textSpan = TextSpan(text: widget.text);
      final textPainter = TextPainter(
        text: textSpan,
        maxLines: 2,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: constraints.maxWidth);

      if (textPainter.didExceedMaxLines) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _isExpanded ? null : 2,
              overflow: TextOverflow.ellipsis,
            ),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  _isExpanded ? appLocalizations.get('show_less') : appLocalizations.get('show_more'),
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      } else {
        return Text(widget.text);
      }
    });
  }
}
