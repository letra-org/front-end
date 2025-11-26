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
│   ├── l10n/
│   │   └── app_localizations.dart         # Bản địa hóa (i18n)
│   ├── providers/
│   │   ├── theme_provider.dart            # State management cho dark mode
│   │   └── language_provider.dart         # State management cho ngôn ngữ
│   ├── screens/                           # Tất cả các màn hình
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── home_screen.dart
│   │   ├── photos_screen.dart
│   │   ├── camera_screen.dart
│   │   ├── create_post_screen.dart
│   │   ├── ai_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── user_profile_screen.dart
│   │   ├── security_screen.dart
│   │   ├── change_password_screen.dart
│   │   ├── team_screen.dart
│   │   ├── sponsors_screen.dart
│   │   ├── app_info_screen.dart
│   │   ├── emergency_location_screen.dart
│   │   ├── friends_screen.dart
│   │   └── chat_screen.dart
│   └── widgets/                           # Custom widgets
│       └── bottom_navigation_bar.dart
└── pubspec.yaml                           # Dependencies

```

## Các màn hình đã chuyển đổi

✅ Đã tạo tất cả 15 màn hình cốt lõi:
1. **WelcomeScreen**
2. **LoginScreen**
3. **RegisterScreen**
4. **ForgotPasswordScreen**
5. **HomeScreen**
6. **PhotosScreen**
7. **AIScreen**
8. **SettingsScreen**
9. **UserProfileScreen**
10. **SecurityScreen**
11. **TeamScreen**
12. **SponsorsScreen**
13. **AppInfoScreen**
14. **EmergencyLocationScreen**
15. **FriendsScreen**

✅ Các màn hình chức năng thêm:
- **CreatePostScreen** - Màn hình tạo bài viết
- **ChatScreen** - Màn hình nhắn tin 1-1
- **ChangePasswordScreen** - Màn hình đổi mật khẩu
- **CameraScreen** - Màn hình chụp ảnh

## Dependencies chính

- **flutter**: Framework
- **provider**: State management
- **http**: Gọi API
- **google_fonts**: Typography
- **cached_network_image**: Load và cache ảnh từ mạng
- **photo_view**: Zoom ảnh
- **image_picker**: Chọn ảnh từ thư viện
- **gal**: Lưu ảnh vào thư viện
- **camera**: Tích hợp camera
- **path_provider**: Truy cập thư mục hệ thống
- **flutter_sound**: Ghi âm (chỉ cho mobile)
- **permission_handler**: Xử lý quyền truy cập
- **url_launcher**: Mở links
- **share_plus**: Chia sẻ nội dung
- **device_preview**: Xem trước giao diện trên nhiều thiết bị

## Cài đặt

1. Đảm bảo đã cài Flutter SDK và các công cụ build cho nền tảng mong muốn (Android, iOS, Desktop).

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Chạy app:
```bash
flutter run
```

## Tính năng chính

### 1. Hệ thống Điều hướng & Giao diện
- Sử dụng state-based navigation trong `AppNavigator` với hiệu ứng chuyển trang thông minh.
- Giao diện đáp ứng (responsive), gỡ bỏ khung cố định để tương thích với nhiều kích thước màn hình.
- Hỗ trợ Dark Mode toàn diện.

### 2. Bản địa hóa (i18n)
- Hỗ trợ 2 ngôn ngữ: Tiếng Việt và Tiếng Anh.
- Người dùng có thể chuyển đổi ngôn ngữ trực tiếp trong ứng dụng mà không phụ thuộc vào ngôn ngữ hệ thống.

### 3. Tính năng cốt lõi
- **Trang chủ:** Tìm kiếm, sắp xếp bài viết theo ngày/lượt thích, thích bài viết, xem thêm/thu gọn caption.
- **Tạo bài viết:** Giao diện chuyên nghiệp, cho phép chọn ảnh từ thư viện hoặc camera của app.
- **Chat:** Nhắn tin 1-1, gửi ảnh, và hỗ trợ ghi âm (chỉ trên mobile).
- **Thư viện ảnh:** Chụp và lưu ảnh mới, xem lại các ảnh đã chụp.
- **AI Assistant:** Trợ lý ảo trả lời các câu hỏi về du lịch Việt Nam.

### 4. Tương thích Đa nền tảng
- **Mobile:** Chạy đầy đủ tính năng trên Android và iOS.
- **Desktop (Demo Mode):** Có thể build và chạy trên Windows/macOS cho mục đích demo (các tính năng yêu cầu phần cứng di động như ghi âm, lưu ảnh sẽ bị vô hiệu hóa).

## Platform-specific setup

### Android
Trong `android/app/src/main/AndroidManifest.xml`, đảm bảo có các quyền sau:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
```

### iOS
Trong `ios/Runner/Info.plist`, đảm bảo có các khóa sau:
```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>vi</string>
</array>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần truy cập thư viện để bạn có thể chọn ảnh.</string>
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần truy cập máy ảnh để bạn có thể chụp ảnh.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Ứng dụng cần truy cập micro để có thể ghi âm tin nhắn thoại.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Ứng dụng cần quyền để lưu ảnh vào bộ sưu tập của bạn.</string>
```

## Build & Release

### Tạo icon cho ứng dụng
```bash
flutter pub run flutter_launcher_icons:main
```

### Build ứng dụng
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## TODO List

- [x] Hoàn thiện tất cả screens còn lại
- [ ] Implement API calls (kết nối backend thật)
- [x] Thêm animations và hiệu ứng chuyển trang
- [x] Thêm loading states
- [x] Error handling (cơ bản)
- [ ] Form validation improvements
- [ ] Add unit & integration tests
- [ ] Optimize images & performance
- [ ] Add offline support (nâng cao)
- [ ] Implement push notifications

---

**Phiên bản**: 1.1.0  
**Ngày cập nhật**: November 11, 2024  
**Framework**: Flutter 3.x  
**Dart SDK**: >=3.0.0
