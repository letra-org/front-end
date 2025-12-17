import 'dart:convert';
import 'dart:io'; // For WebSocket

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/bottom_navigation_bar.dart';

class AIScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const AIScreen({super.key, required this.onNavigate});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late AnimationController _animationController;
  WebSocket? _channel;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appLocalizations = AppLocalizations.of(context)!;
      setState(() {
        _messages.add({
          'text': appLocalizations.get('ai_welcome_message'),
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
      _connectToChat();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _channel?.close();
    super.dispose();
  }

  Future<void> _connectToChat() async {
    if (_isConnecting || (_channel != null && _channel!.readyState == WebSocket.open)) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // 1. Get WebSocket URL from the /chat endpoint
      final response = await http.get(Uri.parse(ApiConfig.aiChat));
      if (response.statusCode != 200) {
        throw Exception('Failed to get WebSocket URL: ${response.statusCode}');
      }
      final responseBody = json.decode(response.body);
      final websocketPath = responseBody['websocket_url'];
      if (websocketPath == null) {
        throw Exception('WebSocket URL not found in response');
      }

      // 2. Get the auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      // 3. Connect to the WebSocket with the token
      final baseUri = Uri.parse(ApiConfig.baseUrl);
      final wsUri = Uri(
        scheme: 'ws',
        host: baseUri.host,
        port: baseUri.port,
        path: websocketPath,
        queryParameters: {'token': token}, // Add token to query parameters
      );

      _channel = await WebSocket.connect(wsUri.toString());

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });

      // 4. Listen for messages from the server
      _channel!.listen(
        (data) {
          if (mounted) {
            final message = json.decode(data);
            // Safely get content, provide a fallback message if it's null or not a string
            final content = message['content']?.toString() ?? '(No content received)';
            setState(() {
              _messages.add({
                'text': content,
                'isUser': false,
                'timestamp': DateTime.now(),
              });
            });
          }
        },
        onError: (error) {
          if (mounted) _showError('WebSocket Error: ${error.toString()}');
          setState(() => _isConnecting = false);
        },
        onDone: () {
          if (mounted) {
             _messages.add({
                'text': 'Connection closed.',
                'isUser': false,
                'isError': true,
                'timestamp': DateTime.now(),
              });
            setState(() => _isConnecting = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _showError('Connection error: ${e.toString()}');
        setState(() => _isConnecting = false);
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();

    if (_channel != null && _channel!.readyState == WebSocket.open) {
      setState(() {
        _messages.add({
          'text': userMessage,
          'isUser': true,
          'timestamp': DateTime.now(),
        });
      });

      // Send the message to the server as a JSON object
      _channel!.add(json.encode({'content': userMessage}));
      _messageController.clear();
    } else {
      _showError('Not connected. Trying to reconnect...');
      _connectToChat();
    }
  }

  void _showError(String message) {
    setState(() {
      _messages.add({
        'text': message,
        'isUser': false,
        'isError': true,
        'timestamp': DateTime.now(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        widget.onNavigate('home');
      },
      child: Scaffold(
        body: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF2563EB),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _animationController.value * 10 - 5),
                            child: const Text('🐢', style: TextStyle(fontSize: 28)),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLocalizations.get('ai_assistant_title'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            appLocalizations.get('ai_assistant_subtitle'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessage(message, isDarkMode);
                },
              ),
            ),
            if (_isConnecting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.05).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: appLocalizations.get('ai_input_hint'),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          currentScreen: 'ai',
          onNavigate: widget.onNavigate,
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, bool isDarkMode) {
    final isUser = message['isUser'] as bool;
    final isError = message['isError'] as bool? ?? false;

    // Make sure text is never null before passing to the Text widget
    final text = message['text']?.toString() ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red.shade700
              : isUser
                  ? const Color(0xFF2563EB)
                  : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text, // Use the safe text variable
          style: TextStyle(
            color: isError
                ? Colors.white
                : isUser
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
