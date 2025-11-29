import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/bottom_navigation_bar.dart';

class FriendsScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const FriendsScreen({super.key, required this.onNavigate});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _allFriends = [];
  List<Map<String, String>> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _allFriends = [
      {'name': 'Nguyễn Văn A', 'location': 'Hà Nội', 'avatar': 'A'},
      {'name': 'Trần Thị B', 'location': 'Đà Nẵng', 'avatar': 'B'},
      {'name': 'Lê Văn C', 'location': 'TP.HCM', 'avatar': 'C'},
      {'name': 'Phạm Thị D', 'location': 'Nha Trang', 'avatar': 'D'},
      {'name': 'Hoàng Văn E', 'location': 'Đà Lạt', 'avatar': 'E'},
    ];
    _filteredFriends = List.from(_allFriends);
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFriends);
    _searchController.dispose();
    super.dispose();
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFriends = _allFriends.where((friend) {
        final name = friend['name']!.toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;

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
                child: Row(
                  children: [
                    Text(
                      appLocalizations.get('friends_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: appLocalizations.get('search_friends_hint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Friends List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(
                        friend['avatar']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(friend['name']!),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.location_on, size: 14),
                        const SizedBox(width: 4),
                        Text(friend['location']!),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () => widget.onNavigate('chat', data: {
                        'friendName': friend['name']!,
                        'friendAvatar': friend['avatar']!,
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentScreen: 'friends',
        onNavigate: widget.onNavigate,
      ),
    );
  }
}
