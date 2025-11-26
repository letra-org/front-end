import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/photos_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/team_screen.dart';
import 'screens/sponsors_screen.dart';
import 'screens/app_info_screen.dart';
import 'screens/emergency_location_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/chat_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'constants/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS),
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const LetraApp(),
      ),
    ),
  );
}

class LetraApp extends StatelessWidget {
  const LetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          builder: DevicePreview.appBuilder,
          title: 'Letra',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: languageProvider.currentLocale, // Use the app's language provider
          supportedLocales: const [
            Locale('en', ''),
            Locale('vi', ''),
          ],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
  String _previousScreen = 'welcome';
  final Map<String, dynamic> _screenData = {};

  final Map<String, int> _screenOrder = const {
    'home': 0,
    'photos': 1,
    'ai': 2,
    'settings': 3,
    'friends': 4,
  };

  void _navigateToScreen(String screen, {Map<String, dynamic>? data}) {
    setState(() {
      _previousScreen = _currentScreen;
      _currentScreen = screen;
      if (data != null) {
        _screenData.clear();
        _screenData.addAll(data);
      }
    });
  }

  void _handleLogout() {
    setState(() {
      _previousScreen = _currentScreen;
      _currentScreen = 'login';
      _screenData.clear();
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'welcome':
        return WelcomeScreen(
          key: const ValueKey('welcome'),
          onLogin: () => _navigateToScreen('login'),
        );
      case 'login':
        return LoginScreen(
          key: const ValueKey('login'),
          onLogin: () => _navigateToScreen('home'),
          onNavigateToRegister: () => _navigateToScreen('register'),
          onNavigateToForgotPassword: () => _navigateToScreen('forgotPassword'),
        );
      case 'register':
        return RegisterScreen(
          key: const ValueKey('register'),
          onRegister: () => _navigateToScreen('home'),
          onBackToLogin: () => _navigateToScreen('login'),
        );
      case 'forgotPassword':
        return ForgotPasswordScreen(
          key: const ValueKey('forgotPassword'),
          onBackToLogin: () => _navigateToScreen('login'),
        );
      case 'home':
        return HomeScreen(
          key: const ValueKey('home'),
          onNavigate: _navigateToScreen,
        );
      case 'photos':
        return PhotosScreen(
          key: const ValueKey('photos'),
          onNavigate: _navigateToScreen,
          isPickerMode: _screenData.containsKey('isPickerMode') ? _screenData['isPickerMode'] : false,
        );
      case 'ai':
        return AIScreen(
          key: const ValueKey('ai'),
          onNavigate: _navigateToScreen,
        );
      case 'settings':
        return SettingsScreen(
          key: const ValueKey('settings'),
          onNavigate: _navigateToScreen,
          onLogout: _handleLogout,
        );
      case 'userProfile':
        return UserProfileScreen(
          key: const ValueKey('userProfile'),
          onNavigate: _navigateToScreen,
        );
      case 'changePassword':
        return ChangePasswordScreen(
          key: const ValueKey('changePassword'),
          onNavigate: _navigateToScreen,
        );
      case 'createPost':
        return CreatePostScreen(
          key: const ValueKey('createPost'),
          onNavigate: _navigateToScreen,
        );
      case 'team':
        return TeamScreen(
          key: const ValueKey('team'),
          onNavigate: _navigateToScreen,
        );
      case 'sponsors':
        return SponsorsScreen(
          key: const ValueKey('sponsors'),
          onNavigate: _navigateToScreen,
        );
      case 'appInfo':
        return AppInfoScreen(
          key: const ValueKey('appInfo'),
          onNavigate: _navigateToScreen,
        );
      case 'emergency':
        return EmergencyLocationScreen(
          key: const ValueKey('emergency'),
          onNavigate: _navigateToScreen,
        );
      case 'friends':
        return FriendsScreen(
          key: const ValueKey('friends'),
          onNavigate: _navigateToScreen,
        );
      case 'chat':
        return ChatScreen(
          key: const ValueKey('chat'),
          onNavigate: _navigateToScreen,
          friendName: _screenData['friendName'] ?? '',
          friendAvatar: _screenData['friendAvatar'] ?? '',
        );
      default:
        return WelcomeScreen(
          key: const ValueKey('default'),
          onLogin: () => _navigateToScreen('login'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final newScreenKey = (child.key as ValueKey).value as String;

          final int newIndex = _screenOrder[newScreenKey] ?? 99;
          final int oldIndex = _screenOrder[_previousScreen] ?? 99;

          var beginOffset = const Offset(1.0, 0.0);
          if (newIndex < oldIndex) {
            beginOffset = const Offset(-1.0, 0.0);
          }

          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _buildCurrentScreen(),
      ),
    );
  }
}
