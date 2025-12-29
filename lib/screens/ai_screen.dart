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
  final List<Map<String, dynamic>> _messages = [];
  bool _isSendingMessage = false;
  String? _currentChatTitle;

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
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context)!;
        _showError(appLocalizations.get('auth_error'));
      }
      setState(() => _isLoadingThreads = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.recommendThreads),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache'
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _threads = List<Map<String, dynamic>>.from(data['threads']);
          _isLoadingThreads = false;
        });
        // Fetch titles for threads that don't have one
        for (var thread in _threads) {
          final String title = thread['title'] ?? '';
          if (title.isEmpty || title.startsWith('Conversation #')) {
            _fetchThreadTitle(thread['id']);
          }
        }
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
      if (mounted) {
        final appLocalizations = AppLocalizations.of(context)!;
        _showError(appLocalizations.get('auth_error'));
      }
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
        final String newThreadId = data['thread_id'];
        setState(() {
          _threads.insert(0, {
            'id': newThreadId,
            'title': '',
            'message_count': 0,
          });
        });
        _startChat(newThreadId);
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
    final appLocalizations = AppLocalizations.of(context)!;
    final token = await _getToken();
    if (token == null) {
      _showError(appLocalizations.get('auth_error'));
      return;
    }
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.recommendDelete(threadId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnackbar(appLocalizations.get('ai_delete_success'));
        setState(() {
          _threads.removeWhere((thread) => thread['id'] == threadId);
        });
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(
            'Failed to delete thread: ${errorData['detail'] ?? response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _fetchThreadTitle(String threadId) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.recommendHistory(threadId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted && response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> historyMessages = data['messages'] ?? [];
        final firstUserMsg = historyMessages.firstWhere(
          (msg) => msg['role'] == 'user',
          orElse: () => null,
        );
        if (firstUserMsg != null) {
          setState(() {
            final threadIndex = _threads.indexWhere((t) => t['id'] == threadId);
            if (threadIndex != -1) {
              _threads[threadIndex]['first_message'] =
                  firstUserMsg['content']?.toString();
            }
          });
        }
      }
    } catch (e) {
      // Silently fail for individual title fetches
    }
  }

  void _startChat(String threadId) {
    setState(() {
      _isListView = false;
      _selectedThreadId = threadId;
      _currentChatTitle = null; // Reset title for new chat view
      _messages.clear();
      _fetchChatHistory(threadId);
    });
  }

  Future<void> _fetchChatHistory(String threadId) async {
    setState(() => _isSendingMessage = true);
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.get('auth_error'));
      }
      setState(() => _isSendingMessage = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.recommendHistory(threadId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted && response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> historyMessages = data['messages'] ?? [];
        final List<Map<String, dynamic>> formattedMessages =
            historyMessages.map((msg) {
          final bool isUser = msg['role'] == 'user';
          final metadata = msg['metadata'] ?? {};
          final messageType = metadata['type'] ?? msg['type'] ?? 'text';
          var content = msg['content'];

          if (messageType == 'recommendation') {
            return {
              'isUser': isUser,
              'type': 'recommendation',
              'text': content, // Keep the text content ("Đã tìm thấy...")
              'data': metadata // Use metadata as the data source
            };
          } else {
            return {
              'isUser': isUser,
              'type': 'text',
              'text': content.toString()
            };
          }
        }).toList();

        setState(() {
          _messages.clear();
          _messages.addAll(formattedMessages.reversed);

          // Get chat title from the first user message
          try {
            final firstUserMsg = historyMessages.firstWhere(
              (msg) => msg['role'] == 'user',
              orElse: () => null,
            );
            if (firstUserMsg != null) {
              _currentChatTitle = firstUserMsg['content']?.toString();

              // Update title in the threads list too
              final threadIndex =
                  _threads.indexWhere((t) => t['id'] == threadId);
              if (threadIndex != -1) {
                _threads[threadIndex]['first_message'] = _currentChatTitle;
              }
            }
          } catch (e) {
            // Fallback if history is empty or structure differs
          }
        });
      } else if (mounted) {
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  void _addTextMessage(String text, {bool isUser = false}) {
    setState(() {
      _messages.insert(0, {
        'text': text,
        'isUser': isUser,
        'type': 'text',
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedThreadId == null)
      return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    _addTextMessage(userMessage, isUser: true);
    setState(() {
      _isSendingMessage = true;
      // Use the first user message as the title if not set
      if (_currentChatTitle == null) {
        _currentChatTitle = userMessage;
        final threadIndex =
            _threads.indexWhere((t) => t['id'] == _selectedThreadId);
        if (threadIndex != -1) {
          _threads[threadIndex]['first_message'] = userMessage;
        }
      }
    });

    final token = await _getToken();
    if (token == null) {
      _showError(AppLocalizations.of(context)!.get('auth_error'));
      setState(() => _isSendingMessage = false);
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
        final messageType = data['type']?.toString();

        if (messageType == 'recommendation' && data['content'] != null) {
          var content = data['content'];
          if (content is String) {
            try {
              content = json.decode(content);
            } catch (e) {
              _addTextMessage(content);
              return;
            }
          }
          setState(() {
            _messages.insert(0, {
              'isUser': false,
              'type': 'recommendation',
              'data': content,
            });
          });
        } else {
          _addTextMessage(data['content']?.toString() ?? '(No response)');
        }
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorData['detail'] ??
            '${AppLocalizations.of(context)!.get('server_error')}: ${response.statusCode}';
        _showError(errorMessage);
      }
    } catch (e) {
      if (mounted)
        _showError('${AppLocalizations.of(context)!.get('generic_error')}: $e');
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
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
    final appLocalizations = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isListView,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (!_isListView) {
          setState(() {
            _isListView = true;
            _selectedThreadId = null;
          });
        } else {
          widget.onNavigate('home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isListView
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isListView = true;
                      _selectedThreadId = null;
                    });
                  },
                ),
          title: Text(
              _isListView
                  ? appLocalizations.get('ai_assistant_title')
                  : (_currentChatTitle ?? appLocalizations.get('chat_title')),
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          backgroundColor: const Color(0xFF1E88E5),
          actions: _isListView
              ? [
                  IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchThreads)
                ]
              : [],
        ),
        body: _isListView ? _buildThreadsList() : _buildChatView(),
        floatingActionButton: _isListView
            ? FloatingActionButton(
                onPressed: _createNewThreadAndChat,
                backgroundColor: const Color(0xFF1E88E5),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        bottomNavigationBar: _isListView
            ? BottomNavigationBarWidget(
                currentScreen: 'ai',
                onNavigate: widget.onNavigate,
              )
            : null,
      ),
    );
  }

  Widget _buildThreadsList() {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_isLoadingThreads) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_threads.isEmpty) {
      return Center(child: Text(appLocalizations.get('ai_no_conversations')));
    }
    return ListView.builder(
      itemCount: _threads.length,
      itemBuilder: (context, index) {
        final thread = _threads[index];
        String displayTitle = thread['title'] ?? '';

        // If title is generic or empty, try to use first_message
        if (displayTitle.isEmpty || displayTitle.startsWith('Conversation #')) {
          displayTitle = thread['first_message'] ??
              thread['last_message'] ??
              '${appLocalizations.get('ai_conversation')} #${index + 1}';
        }

        // Limit title length
        if (displayTitle.length > 50) {
          displayTitle = '${displayTitle.substring(0, 47)}...';
        }

        return ListTile(
          title: Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
    final appLocalizations = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.get('ai_delete_conversation_title')),
        content: Text(appLocalizations.get('ai_delete_conversation_content')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appLocalizations.get('cancel'))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(appLocalizations.get('delete'),
                  style: const TextStyle(color: Colors.red))),
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
            reverse: true,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageItem(message, isDarkMode);
            },
          ),
        ),
        if (_isSendingMessage)
          const Padding(
              padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
        _buildInputArea(isDarkMode),
      ],
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isDarkMode) {
    final isUser = message['isUser'] as bool;

    if (message['type'] == 'recommendation') {
      return _buildRecommendationWidget(message['data'],
          messageText: message['text']);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF1E88E5)
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message['text']?.toString() ?? '',
          style: TextStyle(
              color: isUser
                  ? Colors.white
                  : (isDarkMode ? Colors.white : Colors.black87)),
        ),
      ),
    );
  }

  Widget _buildRecommendationWidget(Map<String, dynamic> recommendationData,
      {String? messageText}) {
    final List<dynamic> destinations = recommendationData['destinations'] ?? [];
    final appLocalizations = AppLocalizations.of(context);
    final summary = recommendationData['profile']?['summary'] ??
        appLocalizations?.get('ai_recommendation_summary') ??
        'Summary';

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Display the text content ("Đã tìm thấy...") as a bubble
          if (messageText != null && messageText.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                messageText,
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
              ),
            ),

          // 2. Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(summary,
                style: TextStyle(
                    color: Colors.grey[600], fontStyle: FontStyle.italic)),
          ),

          // 3. Carousel of cards
          SizedBox(
            height: 380, // Increased height for better fit
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                return _buildDestinationCard(destinations[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(Map<String, dynamic> destination) {
    final appLocalizations = AppLocalizations.of(context)!;
    return SizedBox(
      width: 250,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.blue.shade100,
              child: Center(
                  child:
                      Icon(Icons.map, size: 40, color: Colors.blue.shade800)),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination['name'] ??
                        appLocalizations.get('unknown_destination'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        destination['location'] ?? '',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    destination['description'] ??
                        appLocalizations.get('no_description'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLocalizations.get('ai_match_reason'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination['match_reason'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: appLocalizations.get('type_your_message_hint'),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF1E88E5)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
