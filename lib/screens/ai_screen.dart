import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';

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
    
    // Welcome message
    _messages.add({
      'text': 'Xin chào! Tôi là trợ lý AI du lịch Việt Nam 🐢\nHãy hỏi tôi về các địa điểm du lịch nhé!',
      'isUser': false,
      'timestamp': DateTime.now(),
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
    
    if (lowerMessage.contains('hạ long') || lowerMessage.contains('ha long')) {
      return '🌊 Vịnh Hạ Long là di sản thiên nhiên thế giới tại Quảng Ninh. Bạn nên đi từ tháng 3-5 hoặc 9-11 để thời tiết đẹp nhất. Đừng quên thưởng thức hải sản tươi sống nhé!';
    } else if (lowerMessage.contains('sapa') || lowerMessage.contains('sa pa')) {
      return '🏔️ Sapa ở Lào Cai nổi tiếng với ruộng bậc thang đẹp nhất vào tháng 9-10. Nhiệt độ mát mẻ quanh năm, nhớ mang áo ấm! Nên thử món thắng cố và cá hồi ở đây.';
    } else if (lowerMessage.contains('phú quốc')) {
      return '🏝️ Phú Quốc - đảo ngọc của Việt Nam! Thời điểm lý tưởng là 11-3. Ghé thăm bãi Sao, bãi Dài, và đừng bỏ lỡ chợ đêm Phú Quốc với hải sản tươi ngon!';
    } else if (lowerMessage.contains('hội an')) {
      return '🏮 Hội An phố cổ thật đẹp vào buổi tối với đèn lồng rực rỡ. Nên đi vào rằm để thả đèn hoa đăng. Thử cao lầu, mì Quảng và bánh bao vạc nhé!';
    } else if (lowerMessage.contains('đà nẵng') || lowerMessage.contains('da nang')) {
      return '🌉 Đà Nẵng có Cầu Vàng nổi tiếng, bãi biển Mỹ Khê đẹp nhất Việt Nam. Đi từ tháng 3-8 để tắm biển. Phải thử mì Quảng, bún chả cá!';
    } else if (lowerMessage.contains('nha trang')) {
      return '🏖️ Nha Trang - thiên đường biển! Lặn biển ngắm san hô ở Hòn Mun, tắm bùn khoáng, thưởng thức hải sản tươi ngon. Đi từ tháng 3-9 nhé!';
    } else if (lowerMessage.contains('đà lạt') || lowerMessage.contains('da lat')) {
      return '🌸 Đà Lạt - thành phố ngàn hoa! Thời tiết mát mẻ quanh năm. Ghé hồ Xuân Hương, thác Datanla, và nhớ chụp ảnh tại nhà ga cũ. Thử sữa đậu nành, bánh tráng nướng nhé!';
    } else if (lowerMessage.contains('thời tiết') || lowerMessage.contains('mùa nào')) {
      return '🌤️ Miền Bắc: mùa thu (9-11) đẹp nhất\n🌞 Miền Trung: 2-8 tránh mưa bão\n☀️ Miền Nam: 11-4 khô ráo, dễ đi\n\nBạn muốn đi đâu để tôi tư vấn chi tiết hơn?';
    } else if (lowerMessage.contains('ăn gì') || lowerMessage.contains('món ăn')) {
      return '🍜 Món ăn nổi tiếng:\n• Hà Nội: Phở, bún chả, bánh cuốn\n• Đà Nẵng: Mì Quảng, bún chả cá\n• Hội An: Cao lầu, bánh bao vạc\n• Sài Gòn: Bánh mì, hủ tiếu, cơm tấm\n\nBạn đang ở đâu để tôi gợi ý cụ thể?';
    } else if (lowerMessage.contains('chi phí') || lowerMessage.contains('giá')) {
      return '💰 Chi phí ước tính (1 ngày):\n• Ngân sách thấp: 300-500k VNĐ\n• Trung bình: 800k-1.5tr VNĐ\n• Cao cấp: 2-5tr VNĐ\n\nBạn muốn biết chi tiết cho địa điểm nào?';
    } else {
      return '🐢 Để tôi giúp bạn tốt hơn, hãy hỏi về:\n• Địa điểm du lịch cụ thể\n• Thời tiết và mùa đi\n• Món ăn địa phương\n• Chi phí và lịch trình\n\nVí dụ: "Nên đi Sapa vào tháng mấy?"';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Trợ lý Du lịch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rùa thông minh 🇻🇳',
                          style: TextStyle(
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
                        hintText: 'Hỏi AI về du lịch Việt Nam...',
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
