import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  String _sortOrder = 'newest'; // 'newest' or 'oldest'

  List<Map<String, dynamic>> _allPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // --- HÀM LOAD VÀ PARSE DỮ LIỆU ---
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String rawContent = await rootBundle.loadString('assets/home_status/status.txt');
      
      // 1. CHUẨN HÓA: Thay thế tất cả các kiểu xuống dòng về '\n' chuẩn
      String content = rawContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // 2. TÁCH KHỐI: Sử dụng RegEx để tìm các khối được phân tách bởi ít nhất 2 dòng trống
      final List<String> postBlocks = content
          .split(RegExp(r'\n{2,}')) // Tách bởi 2 hoặc nhiều ký tự xuống dòng
          .map((e) => e.trim()) 
          .where((e) => e.isNotEmpty) 
          .toList();
      
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

      setState(() {
        _allPosts = loadedPosts;
        _isLoading = false;
        _currentPage = 1;
      });

      // --- DEBUG LOG: KIỂM TRA DỮ LIỆU ĐÃ LOAD ---
      print('--- DEBUG: DATA LOAD STATUS ---');
      print('Load thành công ${_allPosts.length} bài viết.');
      if (_allPosts.isNotEmpty) {
        _allPosts.forEach((post) => 
          print('  - Title: ${post['title']}, Date: ${post['date']}'));
      }
      print('------------------------------');
      // ------------------------------------------

    } catch (e) {
      print('Lỗi khi đọc file assets/home_status/status.txt: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- CÁC GETTER VÀ HÀM LOGIC (Giữ nguyên) ---
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
    
    return sortedPosts.sublist(
      startIndex,
      endIndex > sortedPosts.length ? sortedPosts.length : endIndex,
    );
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

  // --- PHẦN BUILD UI (ĐÃ THÊM AVATAR) ---
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header 
          Container(
            color: const Color(0xFF2563EB),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar (ĐÃ CẬP NHẬT)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/user/avatar.jpg', // ĐƯỜNG DẪN MỚI
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey,
                                  child: const Icon(Icons.person, color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Search bar 
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm địa điểm, bài viết...',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search, size: 20),
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sort button 
                        IconButton(
                          icon: Icon(
                            _sortOrder == 'newest' ? Icons.arrow_upward : Icons.arrow_downward, 
                            color: Colors.white
                          ),
                          onPressed: _toggleSort,
                          tooltip: _sortOrder == 'newest' ? 'Mới nhất' : 'Cũ nhất',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Friends button 
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onNavigate('friends'),
                        icon: const Icon(Icons.people, size: 20),
                        label: const Text('Bạn bè'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Posts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allPosts.isEmpty
                    ? const Center(child: Text('Không có bài viết nào được tìm thấy.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _currentPosts.length,
                        itemBuilder: (context, index) {
                          final post = _currentPosts[index];
                          return _buildPostCard(post, isDarkMode);
                        },
                      ),
          ),
          // Pagination
          if (!_isLoading && _totalPages > 1) 
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.05).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () => _changePage(_currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  ...List.generate(
                    _totalPages > 5 ? 5 : _totalPages,
                    (index) {
                      int pageNum;
                      if (_totalPages <= 5) {
                        pageNum = index + 1;
                      } else if (_currentPage <= 3) {
                        pageNum = index + 1;
                      } else if (_currentPage >= _totalPages - 2) {
                        pageNum = _totalPages - 4 + index;
                      } else {
                        pageNum = _currentPage - 2 + index;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => _changePage(pageNum),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _currentPage == pageNum
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _currentPage == pageNum
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                pageNum.toString(),
                                style: TextStyle(
                                  color: _currentPage == pageNum
                                      ? Colors.white
                                      : (isDarkMode ? Colors.white : Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () => _changePage(_currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentScreen: 'home',
        onNavigate: widget.onNavigate,
      ),
    );
  }

  // Widget _buildPostCard giữ nguyên
  Widget _buildPostCard(Map<String, dynamic> post, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, size: 50),
                    ),
                  );
                },
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post['location'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      post['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post['likes']}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.comment_outlined,
                      size: 20,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post['comments']}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
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