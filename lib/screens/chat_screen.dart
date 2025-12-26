import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';

class ChatScreen extends StatefulWidget {
  final String? friendId;
  final String? friendName;
  final String? friendAvatar;

  const ChatScreen({
    super.key,
    this.friendId,
    this.friendName,
    this.friendAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  WebSocketChannel? _channel;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        _myId = data['user']['id']?.toString();
      }
    } catch (e) {
      print("Error reading user ID: $e");
    }

    if (token != null && _myId != null) {
      final uri = Uri.parse('${ApiConfig.friendChatWebSocket}?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen((message) {
        if (mounted) {
          final data = json.decode(message);
          setState(() {
            _messages.insert(0, data);
          });
        }
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && widget.friendId != null) {
      final message = {
        'recipient_id': int.tryParse(widget.friendId!) ?? 0,
        'content': _controller.text,
      };
      _channel!.sink.add(json.encode(message));
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'content': _controller.text,
            'sender_id': _myId,
          });
        });
      }
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.friendId == null || widget.friendName == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Friend not specified.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.friendAvatar != null && widget.friendAvatar!.isNotEmpty
                  ? NetworkImage(widget.friendAvatar!)
                  : null,
              child: widget.friendAvatar == null || widget.friendAvatar!.isEmpty
                  ? Text(
                      widget.friendName!.isNotEmpty ? widget.friendName![0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.friendName!, style: const TextStyle(color: Colors.white)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender_id']?.toString() == _myId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: TextStyle(color: isMe ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
