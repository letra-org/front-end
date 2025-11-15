import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final String currentScreen;
  final Function(String) onNavigate;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentScreen,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255*0.1).toInt()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            label: 'Trang chủ',
            screen: 'home',
          ),
          _buildNavItem(
            context,
            icon: Icons.image,
            label: 'Ảnh',
            screen: 'photos',
          ),
          _buildCameraButton(context),
          _buildNavItem(
            context,
            icon: Icons.psychology,
            label: 'AI',
            screen: 'ai',
          ),
          _buildNavItem(
            context,
            icon: Icons.settings,
            label: 'Cài đặt',
            screen: 'settings',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String screen,
  }) {
    final isActive = currentScreen == screen;
    return InkWell(
      onTap: () => onNavigate(screen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFF2563EB)
                  : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF2563EB)
                    : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraButton(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {
          // Camera functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chức năng camera sẽ được thêm'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
