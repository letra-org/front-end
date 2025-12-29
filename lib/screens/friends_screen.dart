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
      _showSnackbar('Authentication token not found. Please log in again.',
          isError: true);
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
        final List<dynamic> friendsData =
            json.decode(utf8.decode(response.bodyBytes));
        final List<Map<String, dynamic>> friendsList = [];

        for (var data in friendsData) {
          final friendInfo = data['friend'];
          final friendId = friendInfo['id']?.toString() ?? '';

          // Initial friend data
          final friendMap = {
            'id': friendId,
            'friendship_id': data['id']?.toString() ?? '',
            'name': friendInfo['full_name']?.toString() ?? 'No Name',
            'avatar_url': friendInfo['avatar_url']?.toString(),
            'last_message': 'Loading...',
            'last_message_time': '',
          };
          friendsList.add(friendMap);
        }

        setState(() {
          _allFriends = friendsList;
          _filteredFriends = List.from(_allFriends);
          _isLoading = false;
        });

        // Fetch last messages asynchronously for each friend
        for (int i = 0; i < _allFriends.length; i++) {
          _fetchLastMessage(_allFriends[i]['id'], token, i);
        }
      } else {
        throw Exception(
            'Failed to load friends. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
            'An error occurred while fetching friends: ${e.toString()}',
            isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchLastMessage(
      String friendId, String token, int index) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMessageHistory(friendId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> messages =
            json.decode(utf8.decode(response.bodyBytes));
        if (messages.isNotEmpty) {
          final lastMsg = messages.first; // Backend returns newest first
          final content = lastMsg['content'] ?? '';
          final senderId = lastMsg['sender_id']?.toString() ?? '';

          String displayMsg = content;
          // If sender is not the friend, it's me
          if (senderId != friendId) {
            displayMsg = "Bạn: $content";
          }

          if (mounted) {
            setState(() {
              _allFriends[index]['last_message'] = displayMsg;
              _allFriends[index]['last_message_time'] =
                  lastMsg['created_at'] ?? '';
              // Also update filtered list if it contains this friend
              int filteredIdx =
                  _filteredFriends.indexWhere((f) => f['id'] == friendId);
              if (filteredIdx != -1) {
                _filteredFriends[filteredIdx]['last_message'] = displayMsg;
                _filteredFriends[filteredIdx]['last_message_time'] =
                    lastMsg['created_at'] ?? '';
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _allFriends[index]['last_message'] = 'Chưa có tin nhắn';
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching last message for $friendId: $e");
    }
  }

  String _formatMessageTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(timestamp).toLocal();
      final DateTime now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } else {
        final diff = now.difference(date).inDays;
        if (diff == 1) return "Hôm qua";
        if (diff < 7) return "${date.weekday}"; // Could map to Vietnamese days
        return "${date.day}/${date.month}";
      }
    } catch (e) {
      return '';
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

  Future<void> _confirmUnfriend(String friendshipId, String name) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.get('unfriend_confirm_title')),
        content: Text(appLocalizations.get('unfriend_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLocalizations.get('no_label')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              appLocalizations.get('yes_label'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      _unfriend(friendshipId);
    }
  }

  Future<void> _unfriend(String friendshipId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final appLocalizations = AppLocalizations.of(context)!;

    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rejectFriendRequest),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'friendship_id': int.tryParse(friendshipId) ?? 0}),
      );

      if (response.statusCode == 200) {
        _showSnackbar(appLocalizations.get('unfriend_success'));
        _fetchFriends();
      } else {
        _showSnackbar('Failed to unfriend: ${response.statusCode}',
            isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
      setState(() => _isLoading = false);
    }
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
    final hasPendingRequests =
        context.watch<FriendRequestProvider>().pendingRequestCount > 0;

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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications,
                              color: Colors.white),
                          onPressed: _navigateToPendingRequests,
                          tooltip: 'Pending Requests',
                        ),
                        if (hasPendingRequests)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildFriendsLoading(context)
                : _filteredFriends.isEmpty
                    ? Center(
                        child: Text(appLocalizations.get('no_friends_found')))
                    : ListView.builder(
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          final avatarUrl = friend['avatar_url'] as String?;
                          final name = friend['name'] as String;
                          final friendId = friend['id'] as String;
                          final lastMsg = friend['last_message'] ?? '';
                          final lastTime =
                              _formatMessageTime(friend['last_message_time']);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      friendId: friendId,
                                      friendName: name,
                                      friendAvatar: avatarUrl,
                                    ),
                                  ),
                                ).then((_) => _fetchData());
                              },
                              leading: GestureDetector(
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
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  backgroundImage: (avatarUrl != null &&
                                          avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child:
                                      (avatarUrl == null || avatarUrl.isEmpty)
                                          ? Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(lastTime,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              subtitle: Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'unfriend') {
                                    _confirmUnfriend(
                                        friend['friendship_id'], name);
                                  } else if (value == 'profile') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FriendProfileScreen(
                                          friendId: friendId,
                                          friendName: name,
                                          friendAvatar: avatarUrl,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'profile',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, size: 20),
                                        const SizedBox(width: 8),
                                        Text(appLocalizations
                                            .get('personal_info_title')),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'unfriend',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person_remove,
                                            color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          appLocalizations
                                              .get('unfriend_button'),
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                            onPressed: () =>
                                _sendFriendRequest(user['id'].toString()),
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
