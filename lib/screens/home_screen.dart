import 'package:flutter/material.dart';
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

  // Mock data for travel posts
  final List<Map<String, dynamic>> _allPosts = [
    {
      'id': 1,
      'title': 'Vịnh Hạ Long - Kỳ quan thế giới',
      'location': 'Quảng Ninh',
      'image': 'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
      'date': '2024-11-08',
      'likes': 234,
      'comments': 45,
    },
    {
      'id': 2,
      'title': 'Phố cổ Hội An về đêm',
      'location': 'Quảng Nam',
      'image': 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800',
      'date': '2024-11-07',
      'likes': 189,
      'comments': 32,
    },
    {
      'id': 3,
      'title': 'Ruộng bậc thang Sapa',
      'location': 'Lào Cai',
      'image': 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800',
      'date': '2024-11-06',
      'likes': 456,
      'comments': 78,
    },
    {
      'id': 4,
      'title': 'Cầu Vàng Đà Nẵng',
      'location': 'Đà Nẵng',
      'image': 'https://images.unsplash.com/photo-1583504403615-fe7c48c5b9a6?w=800',
      'date': '2024-11-05',
      'likes': 567,
      'comments': 91,
    },
    {
      'id': 5,
      'title': 'Động Phong Nha',
      'location': 'Quảng Bình',
      'image': 'https://images.unsplash.com/photo-1566577134770-93d89dd44b68?w=800',
      'date': '2024-11-04',
      'likes': 345,
      'comments': 56,
    },
    // Add more posts for pagination
    ...List.generate(45, (index) => {
      'id': 6 + index,
      'title': 'Địa điểm du lịch ${6 + index}',
      'location': 'Việt Nam',
      'image': 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=800',
      'date': '2024-11-0${index % 9 + 1}',
      'likes': 100 + index * 10,
      'comments': 20 + index * 2,
    }),
  ];

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
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _sortedPosts.sublist(
      startIndex,
      endIndex > _sortedPosts.length ? _sortedPosts.length : endIndex,
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
                        // Logo
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
                          icon: const Icon(Icons.sort, color: Colors.white),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _currentPosts.length,
              itemBuilder: (context, index) {
                final post = _currentPosts[index];
                return _buildPostCard(post, isDarkMode);
              },
            ),
          ),
          // Pagination
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255*0.05).toInt()),
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
