import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:camera/camera.dart';
import '../screens/camera_screen.dart'; // Import màn hình camera mới

class BottomNavigationBarWidget extends StatelessWidget {
  final String currentScreen;
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentScreen,
    required this.onNavigate,
  });

  // HÀM MỞ MÀN HÌNH CAMERA MỚI
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
          _buildCameraButton(context), // Nút Camera
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
    return InkWell(
      onTap: () => onNavigate(screen),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Icon(
              icon,
              color: isActive
                  ? const Color(0xFF2563EB)
                  : Colors.grey,
              size: isActive ? 34 : 28, // Change size based on active state
            ),
          ),
        ),
      ),
    );
  }

  // HÀM NÚT CAMERA (GỌI _openCamera)
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
