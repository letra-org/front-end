import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/bottom_navigation_bar.dart';

class AIScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const AIScreen({super.key, required this.onNavigate});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  bool _isListView = true;
  String? _selectedThreadId;
  List<Map<String, dynamic>> _threads = [];
  bool _isLoadingThreads = true;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _fetchThreads();
  }

  Future<void> _fetchThreads() async {
    setState(() {
      _isLoadingThreads = true;
      _isListView = true;
    });

    final token = await _getToken();
    if (token == null) {
      _showError('Authentication error');
      setState(() => _isLoadingThreads = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.recommendThreads),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _threads = List<Map<String, dynamic>>.from(data['threads']);
          _isLoadingThreads = false;
        });
      } else {
        throw Exception('Failed to load threads: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
        setState(() => _isLoadingThreads = false);
      }
    }
  }

  Future<void> _createNewThreadAndChat() async {
    setState(() => _isLoadingThreads = true);
    final token = await _getToken();
    if (token == null) {
      _showError('Authentication error');
      setState(() => _isLoadingThreads = false);
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.recommendNew),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _startChat(data['thread_id']);
      } else {
        throw Exception('Failed to create new thread: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
        setState(() => _isLoadingThreads = false);
      }
    }
  }

  Future<void> _deleteThread(String threadId) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Authentication error');
      return;
    }
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.recommendDelete(threadId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnackbar('Conversation deleted successfully');
        _fetchThreads();
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Failed to delete thread: ${errorData['detail'] ?? response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _startChat(String threadId) {
    setState(() {
      _isListView = false;
      _selectedThreadId = threadId;
      _messages.clear();
      _fetchChatHistory(threadId);
    });
  }

  Future<void> _fetchChatHistory(String threadId) async {
    setState(() => _isSendingMessage = true);
    final appLocalizations = AppLocalizations.of(context)!;
    setState(() {
      _messages.add({
        'text': appLocalizations.get('ai_welcome_message'),
        'isUser': false,
      });
      _isSendingMessage = false;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedThreadId == null) return;
    final userMessage = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _messages.add({'text': userMessage, 'isUser': true});
      _isSendingMessage = true;
    });
    final token = await _getToken();
    if (token == null) {
      _showError('Authentication error');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.recommendChat(_selectedThreadId!)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': userMessage,
          'guardrail_enabled': false,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add({
            'text': data['content']?.toString() ?? '(No response)',
            'isUser': false,
            'type': data['type']?.toString(),
          });
        });
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  Future<void> _sendFeedback(int score, {String? comment}) async {
    if (_selectedThreadId == null) return;

    final token = await _getToken();
    if (token == null) {
      _showError('Authentication error');
      return;
    }

    try {
      await http.post(
        Uri.parse(ApiConfig.recommendFeedback(_selectedThreadId!)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'score': score,
          'comment': comment,
        }),
      );
      _showSnackbar('Thank you for your feedback!');
    } catch (e) {
      _showError('Failed to send feedback: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isListView,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (!_isListView) {
          setState(() {
            _isListView = true;
            _selectedThreadId = null;
          });
          _fetchThreads();
        } else {
          widget.onNavigate('home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isListView ? null : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _isListView = true;
                _selectedThreadId = null;
              });
              _fetchThreads();
            },
          ),
          title: Text(_isListView ? 'AI Conversations' : 'Chat', style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2563EB),
          actions: _isListView ? [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchThreads)] : [],
        ),
        body: _isListView ? _buildThreadsList() : _buildChatView(),
        floatingActionButton: _isListView ? FloatingActionButton(
          onPressed: _createNewThreadAndChat,
          child: const Icon(Icons.add),
        ) : null,
        bottomNavigationBar: _isListView ? BottomNavigationBarWidget(
          currentScreen: 'ai',
          onNavigate: widget.onNavigate,
        ) : null,
      ),
    );
  }

  Widget _buildThreadsList() {
    if (_isLoadingThreads) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_threads.isEmpty) {
      return const Center(child: Text('No conversations yet. Start a new one!'));
    }
    return ListView.builder(
      itemCount: _threads.length,
      itemBuilder: (context, index) {
        final thread = _threads[index];
        return ListTile(
          title: Text(thread['title'] ?? 'Conversation #${index + 1}'),
          subtitle: Text('${thread['message_count'] ?? 0} messages'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(thread['id']),
          ),
          onTap: () => _startChat(thread['id']),
        );
      },
    );
  }

  Future<void> _confirmDelete(String threadId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to permanently delete this conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      _deleteThread(threadId);
    }
  }

  Widget _buildChatView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageItem(message, isDarkMode);
            },
          ),
        ),
        if (_isSendingMessage) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
        _buildInputArea(isDarkMode),
      ],
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isDarkMode) {
    final isUser = message['isUser'] as bool;
    final isLastAiMessage = !isUser && _messages.last == message;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF2563EB) : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message['text']?.toString() ?? '',
              style: TextStyle(color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black87)),
            ),
          ),
        ),
        if (isLastAiMessage)
          _buildFeedbackButtons(),
      ],
    );
  }

  Widget _buildFeedbackButtons() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.thumb_up_outlined, size: 20), onPressed: () => _sendFeedback(1)),
          IconButton(icon: const Icon(Icons.thumb_down_outlined, size: 20), onPressed: () => _showFeedbackDialog()),
        ],
      ),
    );
  }

  Future<void> _showFeedbackDialog() async {
    final TextEditingController commentController = TextEditingController();
    final bool? send = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provide Feedback'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: 'Tell us more...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Send')),
        ],
      ),
    );
    if (send == true) {
      _sendFeedback(-1, comment: commentController.text);
    }
  }

  Widget _buildInputArea(bool isDarkMode) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
