import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/camera_screen.dart';
import '../providers/friend_request_provider.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final String currentScreen;
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentScreen,
    required this.onNavigate,
  });

  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen(onNavigate: onNavigate)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).toInt()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, icon: Icons.home, screen: 'home'),
          _buildNavItem(context, icon: Icons.group_rounded, screen: 'friends'),
          _buildCameraButton(context),
          _buildNavItem(context, icon: Icons.auto_awesome_rounded, screen: 'ai'),
          _buildNavItem(context, icon: Icons.settings, screen: 'settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String screen,
  }) {
    final isActive = currentScreen == screen;
    final friendRequestProvider = Provider.of<FriendRequestProvider>(context);
    final hasPendingRequests = friendRequestProvider.pendingRequestCount > 0;

    return InkWell(
      onTap: () => onNavigate(screen),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  color: isActive ? const Color(0xFF2563EB) : Colors.grey,
                  size: isActive ? 34 : 28,
                ),
              ),
              if (screen == 'friends' && hasPendingRequests)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
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
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => _openCamera(context),
        icon: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
