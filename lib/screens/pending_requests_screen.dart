import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
            'request_id': req['id'], // This is the friendship_id (integer)
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
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        // Use the ID directly, as it should already be an integer from the API response.
        body: jsonEncode({'friendship_id': requestId}),
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
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? const Center(
                  child: Text(
                    'No pending friend requests.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPendingRequests,
                  child: ListView.builder(
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = _pendingRequests[index];
                      final userInfo = request['user_info'] as Map<String, dynamic>;
                      final requestId = request['request_id']; // This is the friendship_id
                      final name = userInfo['full_name'] ?? 'No Name';
                      final avatarUrl = userInfo['avatar_url'] as String?;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2563EB),
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                                ? NetworkImage(avatarUrl) 
                                : null,
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
}
