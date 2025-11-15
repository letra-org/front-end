# Letra - Flutter Version

## Giới thiệu

Đây là phiên bản Flutter của ứng dụng du lịch Việt Nam "Letra", được chuyển đổi từ React/TypeScript sang Flutter/Dart.

## Cấu trúc thư mục

```
flutter/
├── lib/
│   ├── main.dart                          # Entry point của app
│   ├── constants/
│   │   └── app_theme.dart                 # Theme và màu sắc
│   ├── providers/
│   │   └── theme_provider.dart            # State management cho dark mode
│   ├── screens/                           # Tất cả các màn hình
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── home_screen.dart
│   │   ├── photos_screen.dart
│   │   ├── ai_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── user_profile_screen.dart
│   │   ├── security_screen.dart
│   │   ├── team_screen.dart
│   │   ├── sponsors_screen.dart
│   │   ├── app_info_screen.dart
│   │   ├── emergency_location_screen.dart
│   │   └── friends_screen.dart
│   └── widgets/                           # Custom widgets
│       └── bottom_navigation_bar.dart
└── pubspec.yaml                           # Dependencies

```

## Các màn hình đã chuyển đổi

✅ Đã tạo:
1. **WelcomeScreen** - Màn hình chào mừng với logo và background map
2. **LoginScreen** - Màn hình đăng nhập
3. **RegisterScreen** - Màn hình đăng ký
4. **ForgotPasswordScreen** - Màn hình quên mật khẩu

⏳ Cần tạo thêm:
5. **HomeScreen** - Trang chủ với bài viết du lịch phân trang
6. **PhotosScreen** - Trưng bày ảnh với zoom/download
7. **AIScreen** - AI gợi ý với hình rùa cute
8. **SettingsScreen** - Cài đặt với dark mode
9. **UserProfileScreen** - Thông tin cá nhân
10. **SecurityScreen** - Bảo mật
11. **TeamScreen** - Đội ngũ phát triển
12. **SponsorsScreen** - Nhà tài trợ
13. **AppInfoScreen** - Thông tin app
14. **EmergencyLocationScreen** - Chia sẻ vị trí cứu hộ
15. **FriendsScreen** - Danh sách bạn bè

## Dependencies chính

- **flutter**: Framework
- **provider**: State management cho dark mode
- **google_fonts**: Typography (Inter font)
- **cached_network_image**: Load ảnh từ mạng
- **photo_view**: Zoom ảnh
- **url_launcher**: Mở links
- **share_plus**: Chia sẻ nội dung

## Cài đặt

1. Đảm bảo đã cài Flutter SDK: https://docs.flutter.dev/get-started/install

2. Di chuyển vào thư mục flutter:
```bash
cd flutter
```

3. Cài dependencies:
```bash
flutter pub get
```

4. Chạy app:
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## Tính năng chính

### 1. Navigation System
- Sử dụng state-based navigation trong `AppNavigator`
- Điều hướng giữa 15 màn hình

### 2. Dark Mode
- Sử dụng Provider cho state management
- Có thể toggle từ SettingsScreen
- Theme được định nghĩa trong `app_theme.dart`

### 3. Responsive Design
- Tối ưu cho iPhone standard: 375x812
- Sử dụng SafeArea và SingleChildScrollView

### 4. Custom Widgets
- BottomNavigationBar với 5 icon và nút camera
- Reusable components

## So sánh React vs Flutter

### React (TypeScript)
```typescript
<Button
  onClick={onLogin}
  className="bg-white text-blue-600 hover:bg-blue-50 px-12 py-6"
>
  Đăng nhập
</Button>
```

### Flutter (Dart)
```dart
ElevatedButton(
  onPressed: onLogin,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF2563EB),
    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 24),
  ),
  child: Text('Đăng nhập'),
)
```

## Hướng dẫn tiếp tục phát triển

### 1. Tạo màn hình HomeScreen:

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 1;
  final int _totalPages = 10;
  String _sortOrder = 'newest';

  // Mock data
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'title': 'Vịnh Hạ Long',
      'location': 'Quảng Ninh',
      'image': 'https://images.unsplash.com/photo-...',
      'date': '2024-11-08',
    },
    // Add more posts...
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Column(
        children: [
          // Header with search and logo
          Container(
            color: Color(0xFF2563EB),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('L', style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Search bar
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm địa điểm, bài viết...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    // Sort button & Friends button
                    IconButton(
                      icon: Icon(Icons.sort, color: Colors.white),
                      onPressed: () {
                        // Toggle sort
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.people, color: Colors.white),
                      onPressed: () => widget.onNavigate('friends'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Posts list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: 5, // 5 posts per page
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: // Build post card
                );
              },
            ),
          ),
          // Pagination
          Container(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous, page numbers, Next buttons
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentScreen: 'home',
        onNavigate: widget.onNavigate,
      ),
    );
  }
}
```

### 2. Tạo PhotosScreen với zoom:

```dart
// Sử dụng photo_view package
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// Trong màn hình full screen photo:
PhotoView(
  imageProvider: NetworkImage(imageUrl),
  minScale: PhotoViewComputedScale.contained,
  maxScale: PhotoViewComputedScale.covered * 2,
  backgroundDecoration: BoxDecoration(
    color: Colors.black,
  ),
)
```

### 3. Tạo AIScreen với animation:

```dart
// Sử dụng AnimatedContainer hoặc Lottie
import 'package:flutter/material.dart';

// Turtle animation
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  child: Image.network(turtleImageUrl),
)
```

### 4. Implement Dark Mode toggle:

```dart
// Trong SettingsScreen
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// Toggle switch
Switch(
  value: Provider.of<ThemeProvider>(context).isDarkMode,
  onChanged: (value) {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  },
)
```

## Assets cần thêm

Tạo thư mục `assets/` và thêm vào `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/logo.png
```

## Platform-specific setup

### Android
Trong `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

### iOS
Trong `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cần truy cập vị trí để chia sẻ trong trường hợp khẩn cấp</string>
```

## Build & Release

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## TODO List

- [ ] Hoàn thiện tất cả screens còn lại
- [ ] Implement API calls (nếu có backend)
- [ ] Thêm animations
- [ ] Thêm loading states
- [ ] Error handling
- [ ] Form validation improvements
- [ ] Add unit tests
- [ ] Add integration tests
- [ ] Optimize images
- [ ] Add offline support
- [ ] Implement push notifications

## Lưu ý quan trọng

1. **Images**: Thay thế URL Unsplash bằng assets hoặc URLs thật
2. **Logo**: Upload logo thật vào assets/
3. **API**: Kết nối với backend API nếu cần
4. **Permissions**: Cấu hình permissions cho camera, location
5. **Firebase** (optional): Thêm Firebase cho authentication, storage

## Liên hệ & Hỗ trợ

Nếu cần hỗ trợ thêm về Flutter:
- Flutter Docs: https://docs.flutter.dev
- Dart Docs: https://dart.dev/guides
- Flutter Community: https://flutter.dev/community

---

**Phiên bản**: 1.0.0  
**Ngày tạo**: November 9, 2024  
**Framework**: Flutter 3.x  
**Dart SDK**: >=3.0.0
