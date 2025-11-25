import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../l10n/app_localizations.dart';

class AIScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const AIScreen({super.key, required this.onNavigate});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Use a post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appLocalizations = AppLocalizations.of(context)!;
      setState(() {
        _messages.add({
          'text': appLocalizations.get('ai_welcome_message'),
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });

    _messageController.clear();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      final aiResponse = _getAIResponse(userMessage);
      setState(() {
        _messages.add({
          'text': aiResponse,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    });
  }

  String _getAIResponse(String message) {
    final lowerMessage = message.toLowerCase();
    final appLocalizations = AppLocalizations.of(context)!;
    
    if (lowerMessage.contains('hạ long') || lowerMessage.contains('ha long')) {
      return appLocalizations.get('ai_response_halong');
    } else if (lowerMessage.contains('sapa') || lowerMessage.contains('sa pa')) {
      return appLocalizations.get('ai_response_sapa');
    } else if (lowerMessage.contains('phú quốc')) {
      return appLocalizations.get('ai_response_phuquoc');
    } else if (lowerMessage.contains('hội an')) {
      return appLocalizations.get('ai_response_hoian');
    } else if (lowerMessage.contains('đà nẵng') || lowerMessage.contains('da nang')) {
      return appLocalizations.get('ai_response_danang');
    } else if (lowerMessage.contains('nha trang')) {
      return appLocalizations.get('ai_response_nhatrang');
    } else if (lowerMessage.contains('đà lạt') || lowerMessage.contains('da lat')) {
      return appLocalizations.get('ai_response_dalat');
    } else if (lowerMessage.contains('thời tiết') || lowerMessage.contains('mùa nào')) {
      return appLocalizations.get('ai_response_weather');
    } else if (lowerMessage.contains('ăn gì') || lowerMessage.contains('món ăn')) {
      return appLocalizations.get('ai_response_food');
    } else if (lowerMessage.contains('chi phí') || lowerMessage.contains('giá')) {
      return appLocalizations.get('ai_response_cost');
    } else {
      return appLocalizations.get('ai_response_default');
    }
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
      child:  Scaffold(
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
                      // Turtle animation
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              _animationController.value * 10 - 5,
                            ),
                            child: const Text(
                              '🐢',
                              style: TextStyle(fontSize: 28),
                            ),
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
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            appLocalizations.get('ai_assistant_subtitle'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255*0.05).toInt()),
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
                          fillColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
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
      )
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, bool isDarkMode) {
    final isUser = message['isUser'] as bool;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2563EB)
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message['text'],
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDarkMode ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
