# 🚀 Letra Flutter - Hướng dẫn nhanh

## ✅ Tổng quan

Đây là phiên bản Flutter của ứng dụng du lịch Việt Nam "Letra". Dự án đã được chuyển đổi hoàn toàn và tích hợp nhiều tính năng hiện đại.

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart
├── constants/
├── l10n/
├── providers/
├── screens/ (15+ màn hình)
└── widgets/
```

## 📱 Các màn hình chính (15+)

1. ✅ **Welcome & Auth:** Welcome, Login, Register, Forgot Password
2. ✅ **Core App:** Home, Photos, AI Assistant, Settings, Friends
3. ✅ **Settings (Sub-screens):** User Profile, Security, Team, Sponsors, App Info, Emergency, Change Password
4. ✅ **Features:** Create Post, Chat, Camera

## 🔧 Cài đặt và chạy

### Bước 1: Cài đặt dependencies
```bash
flutter pub get
```

### Bước 2: Chạy ứng dụng
```bash
# Chọn thiết bị và chạy
flutter run
```

*Lưu ý: Để build cho Windows, bạn cần cài đặt bộ công cụ "Desktop development with C++" từ Visual Studio Installer.*

## ✨ Tính năng nổi bật

- **Giao diện đáp ứng:** Tự động co giãn trên mọi kích thước màn hình.
- **Đa ngôn ngữ:** Chuyển đổi giữa Tiếng Việt và Tiếng Anh trong ứng dụng.
- **Dark Mode:** Hỗ trợ giao diện tối toàn diện.
- **Hiệu ứng mượt mà:** Sử dụng `SlideTransition` và `FadeTransition` cho việc chuyển trang.
- **Trang chủ đa năng:** Tìm kiếm, sắp xếp (theo ngày, lượt thích), thích bài viết, và xem thêm/thu gọn caption.
- **Tạo bài viết:** Giao diện chuyên nghiệp, cho phép chọn ảnh từ thư viện hoặc camera của app.
- **Chat 1-1:** Gửi tin nhắn văn bản, hình ảnh. Hỗ trợ ghi âm (chỉ trên mobile).
- **Thư viện ảnh:** Chụp và lưu ảnh mới, xem lại các ảnh đã chụp.

## ⚙️ Cấu hình nền tảng

Để các tính năng hoạt động, hãy đảm bảo các file sau đã được cấu hình đúng:

### Android (`android/app/src/main/AndroidManifest.xml`)
Cần có các quyền `INTERNET`, `RECORD_AUDIO`, `READ_MEDIA_IMAGES`, `WRITE_EXTERNAL_STORAGE`...

### iOS (`ios/Runner/Info.plist`)
Cần có các khóa `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`...

## 🚀 Build & Release

### 1. Tạo icon cho ứng dụng
```bash
flutter pub run flutter_launcher_icons:main
```

### 2. Build ứng dụng
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---
**Phiên bản**: 1.2.0  
**Ngày cập nhật**: November 26, 2025
