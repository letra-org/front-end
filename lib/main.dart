import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/photos_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/security_screen.dart';
import 'screens/team_screen.dart';
import 'screens/sponsors_screen.dart';
import 'screens/app_info_screen.dart';
import 'screens/emergency_location_screen.dart';
import 'screens/friends_screen.dart';
import 'providers/theme_provider.dart';
import 'constants/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const LetraApp(),
    ),
  );
}

class LetraApp extends StatelessWidget {
  const LetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Letra',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AppNavigator(),
        );
      },
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  String _currentScreen = 'welcome';
  final Map<String, dynamic> _screenData = {};

  void _navigateToScreen(String screen, {Map<String, dynamic>? data}) {
    setState(() {
      _currentScreen = screen;
      if (data != null) {
        _screenData.addAll(data);
      }
    });
  }

  void _handleLogout() {
    setState(() {
      _currentScreen = 'login';
      _screenData.clear();
    });
  }

  Widget _buildCurrentScreen() {
    // KHẮC PHỤC LỖI: Tạo hàm bao bọc chỉ chấp nhận 1 tham số String.
    // Hàm này được sử dụng cho các màn hình (như PhotosScreen) có BottomNavigationBarWidget
    // để tránh lỗi "No named parameter named 'onNavigate'" do chữ ký hàm không khớp.
    void navigateSimple(String screen) {
      _navigateToScreen(screen);
    }

    switch (_currentScreen) {
      case 'welcome':
        return WelcomeScreen(
          onLogin: () => _navigateToScreen('login'),
        );
      case 'login':
        return LoginScreen(
          onLogin: () => _navigateToScreen('home'),
          onNavigateToRegister: () => _navigateToScreen('register'),
          onNavigateToForgotPassword: () => _navigateToScreen('forgotPassword'),
        );
      case 'register':
        return RegisterScreen(
          onRegister: () => _navigateToScreen('home'),
          onBackToLogin: () => _navigateToScreen('login'),
        );
      case 'forgotPassword':
        return ForgotPasswordScreen(
          onBackToLogin: () => _navigateToScreen('login'),
        );
      case 'home':
        return HomeScreen(
          onNavigate: _navigateToScreen, // Dùng hàm đầy đủ
        );
      case 'photos':
        return PhotosScreen(
          onNavigate: navigateSimple, // Dùng hàm bao bọc đã sửa lỗi
        );
      case 'ai':
        return AIScreen(
          onNavigate: navigateSimple, // Thường AI Screen cũng dùng Bottom Bar
        );
      case 'settings':
        return SettingsScreen(
          onNavigate: navigateSimple, // Thường Settings Screen cũng dùng Bottom Bar
          onLogout: _handleLogout,
        );
      case 'userProfile':
        return UserProfileScreen(
          onNavigate: navigateSimple,
        );
      case 'security':
        return SecurityScreen(
          onNavigate: navigateSimple,
        );
      case 'team':
        return TeamScreen(
          onNavigate: navigateSimple,
        );
      case 'sponsors':
        return SponsorsScreen(
          onNavigate: navigateSimple,
        );
      case 'appInfo':
        return AppInfoScreen(
          onNavigate: navigateSimple,
        );
      case 'emergency':
        return EmergencyLocationScreen(
          onNavigate: navigateSimple,
        );
      case 'friends':
        return FriendsScreen(
          onNavigate: navigateSimple,
        );
      default:
        return WelcomeScreen(
          onLogin: () => _navigateToScreen('login'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 375,
          height: 812,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRect(
            child: _buildCurrentScreen(),
          ),
        ),
      ),
    );
  }
}