import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';

class FriendRequestProvider extends ChangeNotifier {
  int _pendingRequestCount = 0;

  int get pendingRequestCount => _pendingRequestCount;

  Future<void> fetchPendingRequestCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _updateCount(0);
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

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _updateCount(data.length);
      } else {
        _updateCount(0);
      }
    } catch (e) {
      _updateCount(0);
    } 
  }

  void _updateCount(int newCount) {
    if (_pendingRequestCount != newCount) {
      _pendingRequestCount = newCount;
      notifyListeners();
    }
  }
}
