// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';
import 'dart:async';

enum MessageType { text, image }

class ChatScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;
  final String friendName;
  final String friendAvatar;

  const ChatScreen({
    super.key,
    required this.onNavigate,
    required this.friendName,
    required this.friendAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {})); // Rebuild on text change

    // Add some mock messages
    _messages.addAll([
      {'type': MessageType.text, 'content': 'Chào bạn, khoẻ không?', 'isUser': false, 'timestamp': DateTime.now().subtract(const Duration(minutes: 5))},
      {'type': MessageType.text, 'content': 'Mình khoẻ, còn bạn?', 'isUser': true, 'timestamp': DateTime.now().subtract(const Duration(minutes: 4))},
      {'type': MessageType.text, 'content': 'Đi du lịch không? ✈️', 'isUser': false, 'timestamp': DateTime.now().subtract(const Duration(minutes: 2))},
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'type': MessageType.text,
        'content': _messageController.text.trim(),
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _messages.add({
          'type': MessageType.image,
          'content': File(pickedFile.path),
          'isUser': true,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate('friends'),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                widget.friendAvatar,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.friendName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages.reversed.toList()[index];
                return _buildMessage(message, isDarkMode);
              },
            ),
          ),
          _buildInputArea(appLocalizations, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, bool isDarkMode) {
    final isUser = message['isUser'] as bool;
    final type = message['type'] as MessageType;
    final content = message['content'];

    Widget messageContent;
    switch (type) {
      case MessageType.image:
        messageContent = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(content as File, fit: BoxFit.cover),
        );
        break;
      default: // MessageType.text
        messageContent = Text(
          content as String,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDarkMode ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2563EB)
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: messageContent,
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations appLocalizations, bool isDarkMode) {
    final hasText = _messageController.text.isNotEmpty;

    return Container(
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
            if (!hasText)
              IconButton(
                icon: const Icon(Icons.photo_library), 
                onPressed: _pickImage,
                color: Theme.of(context).primaryColor,
              ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: appLocalizations.get('type_a_message'),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
            if (hasText)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
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
    );
  }
}
