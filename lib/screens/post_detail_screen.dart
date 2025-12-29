import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/api_config.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late int _likes;
  late List<int> _likedBy;
  bool _isLiked = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _likes = widget.post['likes'] is int ? widget.post['likes'] : 0;
    _likedBy = List<int>.from(widget.post['liked_by'] ?? []);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        final user = data['user'] as Map<String, dynamic>?;

        if (user != null && mounted) {
          setState(() {
            _currentUserId = user['id'] as int?;
            _isLiked =
                _currentUserId != null && _likedBy.contains(_currentUserId);
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || _currentUserId == null) return;

    // Optimistic update
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likes--;
        _likedBy.remove(_currentUserId);
      } else {
        _isLiked = true;
        _likes++;
        _likedBy.add(_currentUserId!);
      }
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.likePost(widget.post['id'].toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        // Revert
        setState(() {
          if (_isLiked) {
            _isLiked = false;
            _likes--;
            _likedBy.remove(_currentUserId);
          } else {
            _isLiked = true;
            _likes++;
            _likedBy.add(_currentUserId!);
          }
        });
      }
    } catch (e) {
      // Revert
      setState(() {
        if (_isLiked) {
          _isLiked = false;
          _likes--;
          _likedBy.remove(_currentUserId);
        } else {
          _isLiked = true;
          _likes++;
          _likedBy.add(_currentUserId!);
        }
      });
      debugPrint("Error toggling like: $e");
    }
  }

  String _formatPostTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays > 3) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post by ${widget.post['author'] ?? 'User'}'),
      ),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(0),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Text(widget.post['content'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              if (widget.post['imageUrl'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.post['imageUrl'],
                    placeholder: (context, url) =>
                        Container(height: 250, color: Colors.grey[200]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              _buildPostActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: widget.post['avatarUrl'] != null
                ? CachedNetworkImageProvider(widget.post['avatarUrl'])
                : null,
            child: widget.post['avatarUrl'] == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.post['author'] ?? 'User',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_formatPostTime(widget.post['time']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _toggleLike,
            icon: Icon(
              _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 22,
              color: _isLiked ? Colors.blue : Colors.grey[700],
            ),
            label: Text(
              '$_likes',
              style: TextStyle(
                color: _isLiked ? Colors.blue : Colors.grey[700],
                fontSize: 14,
                fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}
