import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

// =================================================================
// 1. MODEL DỮ LIỆU CỦA THÀNH VIÊN
// =================================================================
class TeamMember {
  final String name;
  final String role;
  final String bio;
  final String assetPath; // Đường dẫn ảnh trong thư mục assets

  const TeamMember({
    required this.name,
    required this.role,
    required this.bio,
    required this.assetPath,
  });
}

// DỮ LIỆU MOCK (Giả định 5 thành viên và đường dẫn ảnh)
final List<TeamMember> teamData = [
  const TeamMember(
    name: 'Lâm Chí Hào',
    role: 'Trưởng nhóm/Phát triển AI',
    bio: 'A là người đứng đầu chịu trách nhiệm về tiến độ của toàn bộ dự án, chịu trách nhiệm phát triển các mô hình học máy (Machine Learning Models) cho tính năng gợi ý địa điểm, phân tích cảm xúc và xử lý ngôn ngữ tự nhiên (NLP), giúp nâng cao trải nghiệm cá nhân hóa của người dùng..',
    assetPath: 'assets/images/team/Chi_Hao.jpg',
  ),
  const TeamMember(
    name: 'Lê Nguyễn Anh Trí',
    role: 'Backend',
    bio: 'Làm thinh',
    assetPath: 'assets/images/team/Anh_Tri.jpg',
  ),
  const TeamMember(
    name: 'Phạm Công Khánh',
    role: 'Backend',
    bio: 'Thêm sau',
    assetPath: 'assets/images/team/Cong_Khanh.jpg',
  ),
  const TeamMember(
    name: 'Thái Kiệt',
    role: 'Camera AI',
    bio: 'Trường chịu trách nhiệm phát triển tính năng thông tin địa điểm qua camera.',
    assetPath: 'assets/images/team/Thai_Kiet.jpg',
  ),
  const TeamMember(
    name: 'Huỳnh Thái Hoà',
    role: 'Phát triển Frontend/UI-UX',
    bio: 'Hoà chuyên về thiết kế giao diện người dùng và trải nghiệm người dùng, đảm bảo ứng dụng Letra không chỉ hoạt động trơn tru mà còn đẹp mắt và thân thiện với người dùng.',
    assetPath: 'assets/images/team/Thai_Hoa.jpg',
  ),
];


// =================================================================
// 2. WIDGET MÀN HÌNH CHÍNH (STATELASS)
// =================================================================

class TeamScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const TeamScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header Bar
          Container(
            color: const Color(0xFF2563EB),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => onNavigate('settings'),
                    ),
                    Text(
                      appLocalizations.get('development_team_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content (Danh sách thành viên)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  appLocalizations.get('team_intro_title'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  appLocalizations.get('team_intro_body'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // Hiển thị 5 ô thông tin thành viên
                ...teamData.map((member) {
                  return TeamMemberCard(member: member);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 3. WIDGET THẺ THÀNH VIÊN (STATEFUL) - Xử lý Mở rộng/Thu gọn
// =================================================================

class TeamMemberCard extends StatefulWidget {
  final TeamMember member;

  const TeamMemberCard({super.key, required this.member});

  @override
  State<TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<TeamMemberCard> {
  // Trạng thái cục bộ để theo dõi việc mở rộng/thu gọn
  bool _isExpanded = false;

  // Số lượng dòng tối đa khi bị thu gọn
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    // Đoạn mô tả với nút Mở rộng
    final bioWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sử dụng AnimatedSize để làm cho việc mở rộng/thu gọn mượt mà hơn
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Text(
            widget.member.bio,
            maxLines: _isExpanded ? null : _maxLines,
            overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        
        // Nút Mở rộng/Thu gọn (chỉ hiển thị nếu đoạn văn bản dài)
        // Chúng ta cần một cách để biết đoạn văn bản có dài hơn _maxLines không.
        // Tuy nhiên, để đơn giản, chúng ta giả định đoạn văn bản giới thiệu là đủ dài để hiển thị nút này.
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _isExpanded ? appLocalizations.get('show_less') : appLocalizations.get('show_more'),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );


    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh và Tên/Vai trò
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh thành viên
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    // Đảm bảo bạn đã thêm các ảnh này vào assets/images/team/ trong pubspec.yaml
                    widget.member.assetPath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Tên và Vai trò
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.member.role,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            // Giới thiệu/Tiểu sử (Bio)
            bioWidget,
          ],
        ),
      ),
    );
  }
}