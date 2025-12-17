import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  // Made all parameters optional to avoid compile errors from main.dart
  final String? friendId;
  final String? friendName;
  final String? friendAvatar;
  final Function(String, {Map<String, dynamic> data})? onNavigate;

  const ChatScreen({
    super.key,
    this.friendId,
    this.friendName,
    this.friendAvatar,
    this.onNavigate, // This will satisfy the incorrect call from main.dart
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // If the screen is opened incorrectly (e.g., from main.dart), show a message.
    if (widget.friendId == null || widget.friendName == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lỗi', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2563EB),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Màn hình này không thể được mở trực tiếp.\nVui lòng vào danh sách bạn bè và chọn một người để trò chuyện.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // If opened correctly, show the chat UI.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
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
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tính năng chat đang được cập nhật và sẽ sớm quay trở lại.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
