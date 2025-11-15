import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const FriendsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final friends = [
      {'name': 'Nguyễn Văn A', 'location': 'Hà Nội', 'avatar': 'A'},
      {'name': 'Trần Thị B', 'location': 'Đà Nẵng', 'avatar': 'B'},
      {'name': 'Lê Văn C', 'location': 'TP.HCM', 'avatar': 'C'},
      {'name': 'Phạm Thị D', 'location': 'Nha Trang', 'avatar': 'D'},
      {'name': 'Hoàng Văn E', 'location': 'Đà Lạt', 'avatar': 'E'},
    ];

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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => onNavigate('home'),
                    ),
                    const Text(
                      'Bạn bè',
                      style: TextStyle(
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
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
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
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
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
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
