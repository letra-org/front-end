import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; 

import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/friend_request_provider.dart'; 
import '../widgets/bottom_navigation_bar.dart';
import './pending_requests_screen.dart';
import './chat_screen.dart';
import './friend_profile_screen.dart';

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
    _fetchData();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFriends);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await _fetchFriends();
    if (mounted) {
      await context.read<FriendRequestProvider>().fetchPendingRequestCount();
    }
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const UserSearchSheet(),
    );
  }

  void _navigateToPendingRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PendingRequestsScreen()),
    ).then((_) => _fetchData());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;
    final hasPendingRequests = context.watch<FriendRequestProvider>().pendingRequestCount > 0;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E88E5),
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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
                          onPressed: _navigateToPendingRequests,
                          tooltip: 'Pending Requests',
                        ),
                        if (hasPendingRequests)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      onPressed: _showAddFriendDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchData,
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
                ? _buildFriendsLoading(context)
                : _filteredFriends.isEmpty
                    ? Center(child: Text(appLocalizations.get('no_friends_found')))
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
                              onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FriendProfileScreen(
                                        friendId: friendId,
                                        friendName: name,
                                        friendAvatar: avatarUrl,
                                      ),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1E88E5),
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

  Widget _buildFriendsLoading(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white),
            title: Container(width: 150, height: 16, color: Colors.white),
            subtitle: Container(width: 100, height: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class UserSearchSheet extends StatefulWidget {
  const UserSearchSheet({super.key});

  @override
  _UserSearchSheetState createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _searchUsers(_searchController.text);
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.searchUsers).replace(queryParameters: {'q': query}),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackbar('Error searching users: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
        await http.post(
        Uri.parse(ApiConfig.addFriend),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'target_user_id': userId}),
      );
      _showSnackbar('Friend request sent!');
    } catch (e) {
      _showSnackbar('Failed to send friend request: $e', isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name or username',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          title: Text(user['full_name'] ?? ''),
                          subtitle: Text(user['username'] ?? ''),
                          trailing: ElevatedButton(
                            onPressed: () => _sendFriendRequest(user['id'].toString()),
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
