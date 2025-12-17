import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/bottom_navigation_bar.dart';
import './pending_requests_screen.dart';
import './chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const FriendsScreen({super.key, required this.onNavigate});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFriends);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar('Authentication token not found. Please log in again.', isError: true);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.listFriends),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> friendsData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _allFriends = friendsData.map((data) {
            final friendInfo = data['friend'];
            return {
              'id': friendInfo['id']?.toString() ?? '',
              'name': friendInfo['full_name']?.toString() ?? 'No Name',
              'avatar_url': friendInfo['avatar_url']?.toString(),
              'location': 'Việt Nam',
            };
          }).toList();
          _filteredFriends = List.from(_allFriends);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load friends. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('An error occurred while fetching friends: ${e.toString()}', isError: true);
        setState(() => _isLoading = false);
      }
    }
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

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showAddFriendDialog() {
    final TextEditingController idController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: TextField(
            controller: idController,
            decoration: const InputDecoration(hintText: 'Enter a user ID'),
            keyboardType: TextInputType.text,
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final userId = idController.text.trim();
                if (userId.isNotEmpty) {
                  Navigator.of(context).pop();
                  // _sendFriendRequest(userId); // You would call your API here
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToPendingRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PendingRequestsScreen()),
    ).then((_) => _fetchFriends());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
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
                    Text(
                      appLocalizations.get('friends_title'),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: _navigateToPendingRequests,
                      tooltip: 'Pending Requests',
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      onPressed: _showAddFriendDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchFriends,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: appLocalizations.get('search_friends_hint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? const Center(child: Text('You have no friends yet. Add one!'))
                    : ListView.builder(
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          final avatarUrl = friend['avatar_url'] as String?;
                          final name = friend['name'] as String;
                          final friendId = friend['id'] as String;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB),
                                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              title: Text(name),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14),
                                  const SizedBox(width: 4),
                                  Text(friend['location'] ?? 'Việt Nam'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.message),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        friendId: friendId,
                                        friendName: name,
                                        friendAvatar: avatarUrl,
                                      ),
                                    ),
                                  );
                                },
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
