import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

import '../constants/api_config.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoading = true);
    // Simulate delay for shimmer effect
    await Future.delayed(const Duration(milliseconds: 1500));

    final token = await _getToken();
    if (token == null) {
      _showSnackbar('Authentication required.', isError: true);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.listPendingRequests),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _pendingRequests = data.map((req) => {
            'request_id': req['id'],
            'user_info': req['requester'],
          }).toList();
        });
      } else {
        throw Exception('Failed to load pending requests: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showSnackbar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequest(dynamic requestId, bool accept) async {
    final token = await _getToken();
    if (token == null) {
      _showSnackbar('Authentication required.', isError: true);
      return;
    }

    final url = accept
        ? Uri.parse(ApiConfig.acceptFriendRequest)
        : Uri.parse(ApiConfig.rejectFriendRequest);

    try {
      final friendshipId = int.tryParse(requestId.toString());
      if (friendshipId == null) {
        throw Exception('Invalid request ID format.');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'friendship_id': friendshipId}),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Request ${accept ? 'accepted' : 'rejected'} successfully.');
        _fetchPendingRequests(); // Refresh the list
      } else {
        final responseBody = json.decode(response.body);
        final detail = responseBody['detail'] ?? 'Unknown error';
        throw Exception('Failed to ${accept ? 'accept' : 'reject'} request: $detail');
      }
    } catch (e) {
      if (mounted) _showSnackbar(e.toString(), isError: true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Friend Requests'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPendingRequests,
        child: _isLoading
            ? _buildRequestsLoading(context)
            : _pendingRequests.isEmpty
                ? const Center(
                    child: Text(
                      'No pending friend requests.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = _pendingRequests[index];
                      final userInfo = request['user_info'] as Map<String, dynamic>;
                      final requestId = request['request_id'];
                      final name = userInfo['full_name'] ?? 'No Name';
                      final avatarUrl = userInfo['avatar_url'] as String?;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _handleRequest(requestId, true),
                                tooltip: 'Accept',
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _handleRequest(requestId, false),
                                tooltip: 'Reject',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildRequestsLoading(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white),
            title: Container(width: 150, height: 16, color: Colors.white),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 24, height: 24, color: Colors.white),
                const SizedBox(width: 16),
                Container(width: 24, height: 24, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
