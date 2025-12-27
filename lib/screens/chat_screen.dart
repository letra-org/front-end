import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';

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
  String _connectionStatus = 'Connecting...';
  bool _isConnected = false;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (mounted) {
      setState(() {
        _connectionStatus = 'Connecting...';
        _isConnected = false;
      });
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data/userdata.js');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        final userData = data['user'];
        if (userData != null) {
          _myId = userData['id']?.toString();
        }
      }
    } catch (e) {
      debugPrint("Error reading user ID: $e");
    }

    if (token != null) {
      // Fetch message history before or during connection
      _fetchHistory(token);

      final wsUrl = '${ApiConfig.friendChatWebSocket}?token=$token';
      final uri = Uri.parse(wsUrl);

      try {
        _channel = WebSocketChannel.connect(uri);

        _channel!.stream.listen(
          (message) {
            debugPrint("Received WebSocket message: $message");
            if (mounted) {
              final data = json.decode(message);
              final String type = data['type'] ?? '';

              if (type == 'system') {
                setState(() {
                  _isConnected = true;
                  _connectionStatus = 'Connected';
                  if (data['user_id'] != null) {
                    _myId = data['user_id'].toString();
                    debugPrint("My ID set from system message: $_myId");
                  }
                });
              } else if (type == 'direct_message') {
                if (!_isConnected) {
                  setState(() {
                    _isConnected = true;
                    _connectionStatus = 'Connected';
                  });
                }
                setState(() {
                  _messages.insert(0, data);
                });
              } else if (type == 'delivery_receipt') {
                final status = data['status'];
                debugPrint("Delivery receipt status: $status");

                if (status == 'undelivered') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .get('offline_message_notice')),
                      backgroundColor: Colors.blueGrey,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else if (type == 'error') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${data['message']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onError: (error) {
            debugPrint("WebSocket Error: $error");
            if (mounted) {
              setState(() {
                _isConnected = false;
                _connectionStatus = 'Connection Error';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat connection error: $error')),
              );
            }
          },
          onDone: () {
            debugPrint("WebSocket Closed");
            if (mounted) {
              setState(() {
                _isConnected = false;
                _connectionStatus = 'Disconnected';
              });
            }
          },
        );

        // Assume connected if no error in first 1s
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _channel != null && !_isConnected) {
            setState(() {
              _isConnected = true;
              _connectionStatus = 'Connected';
            });
          }
        });
      } catch (e) {
        debugPrint("Connection exception: $e");
        if (mounted) {
          setState(() {
            _isConnected = false;
            _connectionStatus = 'Failed';
          });
        }
      }
    } else {
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context)!;
        setState(() {
          _connectionStatus = 'Error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.get('auth_token_missing'))),
        );
      }
    }
  }

  String _getConnectionStatusText() {
    final appLocalizations = AppLocalizations.of(context);
    if (appLocalizations == null) return _connectionStatus;

    switch (_connectionStatus) {
      case 'Connecting...':
        return appLocalizations.get('connecting');
      case 'Connected':
        return appLocalizations.get('connected');
      case 'Disconnected':
        return appLocalizations.get('disconnected');
      case 'Connection Error':
      case 'Error':
      case 'Failed':
        return appLocalizations.get('connection_error');
      default:
        return _connectionStatus;
    }
  }

  Future<void> _fetchHistory(String token) async {
    if (widget.friendId == null) return;
    debugPrint("Fetching chat history for friend: ${widget.friendId}");

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMessageHistory(widget.friendId!)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint("History response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> historyData =
            json.decode(utf8.decode(response.bodyBytes));
        debugPrint("Fetched ${historyData.length} messages.");
        if (mounted) {
          setState(() {
            _messages.clear();
            for (var msg in historyData.reversed) {
              _messages.add(Map<String, dynamic>.from(msg));
            }
          });
        }
      } else {
        debugPrint("Failed history fetch: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    if (_channel == null || !_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa kết nối được với máy chủ.')),
      );
      return;
    }

    final message = {
      'recipient_id': int.tryParse(widget.friendId!) ?? 0,
      'content': _controller.text,
    };

    try {
      _channel!.sink.add(json.encode(message));

      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'type': 'direct_message',
            'content': _controller.text,
            'sender_id': _myId,
            'recipient_id': message['recipient_id'],
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
      }
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
      );
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.friendAvatar != null && widget.friendAvatar!.isNotEmpty
                      ? NetworkImage(widget.friendAvatar!)
                      : null,
              child: widget.friendAvatar == null || widget.friendAvatar!.isEmpty
                  ? Text(
                      widget.friendName!.isNotEmpty
                          ? widget.friendName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendName!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getConnectionStatusText(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.grey[100],
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMe = message['sender_id']?.toString() == _myId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF1E88E5)
                                  : (isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isMe ? 20 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              message['content'] ?? '',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : (isDarkMode
                                        ? Colors.white
                                        : Colors.black87),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(message['timestamp']),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildMessageInput(isDarkMode),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final DateTime dt = DateTime.parse(timestamp);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  Widget _buildMessageInput(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: _l10n.get('type_your_message_hint'),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
