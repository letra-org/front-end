import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';

class ChatProvider extends ChangeNotifier {
  int _unreadCount = 0;
  Timer? _timer;

  int get unreadCount => _unreadCount;

  void startPolling() {
    _fetchUnreadCount();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchUnreadCount();
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  Future<void> _fetchUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.notificationUnreadCount),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _unreadCount = data['count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  Future<void> markAsRead(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      await http.post(
        Uri.parse(ApiConfig.markMessagesRead(friendId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      // Determine if we should decrement locally or just refetch
      _fetchUnreadCount();
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
