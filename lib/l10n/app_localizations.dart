import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'loading': 'Loading...',
      'show_less': '<< Show less',
      'show_more': '... Show more >>',

      // Exit Dialog
      'exit_dialog_title': 'Leaving so soon? 🥺',
      'exit_dialog_content': 'Are you sure you want to exit Letra?',
      'exit_dialog_yes': 'Yes, exit',
      'exit_dialog_no': 'Stay',

      // Emergency Screen
      'emergency_warning': 'This feature should only be used in an emergency',
      'current_location_label': 'Your Current Location',
      'address_label': 'Address',
      'coordinates_label': 'Coordinates',
      'accuracy_label': 'Accuracy',
      'share_location_button': 'Share Location',
      'location_shared_button': 'Location Shared',
      'location_sent_message': 'Location has been sent. Please keep your phone on.',
      'emergency_contacts_label': 'Emergency Contacts',
      'police': 'Police',
      'fire_department': 'Fire Dept.',
      'ambulance': 'Ambulance',
      'rescue': 'Rescue',

      // Photos Screen
      'photos_library': 'Photos',
      'no_photos_message': 'No photos yet.\nTake a picture!',
      'save_success': 'Photo saved to gallery!',
      'save_error': 'Failed to save photo.',
      'save_general_error': 'Error saving photo: ',

      // Image Source
      'image_source_title': 'Choose Image Source',
      'device_gallery': 'Device Gallery',
      'app_photos': 'App Photos',

      // Create Post Screen
      'create_post_title': 'Create Post',
      'post_button': 'Post',
      'title_label': 'Title',
      'location_label': 'Location (e.g., Ha Long Bay)',
      'caption_label': 'What are you thinking?',
      'add_image_button': 'Add Image/Video',

      // Sort Options
      'sort_by': 'Sort by',
      'sort_by_date_newest': 'Date (Newest First)',
      'sort_by_date_oldest': 'Date (Oldest First)',
      'sort_by_likes_most': 'Likes (Most First)',
      'sort_by_likes_least': 'Likes (Least First)',

      // Change Password Screen
      'change_password_title': 'Change Password',
      'current_password_label': 'Current Password',
      'new_password_label': 'New Password',
      'confirm_new_password_label': 'Confirm New Password',
      'update_password_button': 'Update Password',

      // AI Screen
      'ai_assistant_title': 'AI Travel Assistant',
      'ai_assistant_subtitle': 'Smart Turtle 🇻🇳',
      'ai_welcome_message': 'Hello! I am a Vietnam travel AI assistant 🐢\nAsk me about tourist destinations!',
      'ai_input_hint': 'Ask AI about Vietnam travel...',
      'ai_response_halong': '🌊 Halong Bay is a world natural heritage site in Quang Ninh. You should go from March to May or September to November for the best weather. Don\'t forget to enjoy fresh seafood!',
      'ai_response_sapa': '🏔️ Sapa in Lao Cai is famous for its beautiful terraced fields, best seen in September-October. The temperature is cool year-round, remember to bring warm clothes! You should try thang co and salmon here.',
      'ai_response_phuquoc': '🏝️ Phu Quoc - the pearl island of Vietnam! The ideal time is from November to March. Visit Sao Beach, Long Beach, and don\'t miss the Phu Quoc night market with delicious fresh seafood!',
      'ai_response_hoian': '🏮 Hoi An ancient town is beautiful at night with sparkling lanterns. You should go on the full moon day to release flower lanterns. Try Cao Lau, Mi Quang, and white rose dumplings!',
      'ai_response_danang': '🌉 Da Nang has the famous Golden Bridge, and My Khe beach is one of the most beautiful in Vietnam. Go from March to August for swimming. You must try Mi Quang and fish cake noodles!',
      'ai_response_nhatrang': '🏖️ Nha Trang - a beach paradise! Go snorkeling to see coral at Hon Mun, take a mud bath, and enjoy delicious fresh seafood. The best time to visit is from March to September!',
      'ai_response_dalat': '🌸 Da Lat - the city of thousands of flowers! Cool weather all year round. Visit Xuan Huong Lake, Datanla Waterfall, and don\'t forget to take photos at the old train station. Try soy milk and grilled rice paper!',
      'ai_response_weather': '🌤️ North: Autumn (Sept-Nov) is the best\n🌞 Central: Feb-Aug to avoid storms\n☀️ South: Nov-Apr is dry and easy to travel\n\nWhere do you want to go for more details?',
      'ai_response_food': '🍜 Famous dishes:\n• Hanoi: Pho, Bun Cha, Banh Cuon\n• Da Nang: Mi Quang, Bun Cha Ca\n• Hoi An: Cao Lau, White Rose Dumplings\n• Saigon: Banh Mi, Hu Tieu, Com Tam\nWhere are you for specific suggestions?',
      'ai_response_cost': '💰 Estimated cost (1 day):\n• Low budget: 300-500k VND\n• Medium: 800k-1.5m VND\n• High-end: 2-5m VND\n\nWhich location do you want details for?',
      'ai_response_default': '🐢 To help you better, please ask about:\n• Specific tourist destinations\n• Weather and seasons\n• Local dishes\n• Costs and itineraries\nExample: \"When should I go to Sapa?\"',

      // Friends Screen
      'friends_title': 'Friends',
      'search_friends_hint': 'Search for friends...',

      // Sponsors Screen
      'sponsors_title': 'Sponsors',
      'sponsors_thank_you': 'Thank You to Our Sponsors',
      'sponsors_description': 'This project is supported by partners and sponsors who believe in the vision of developing tourism in Vietnam.',
      
      // Team Screen
      'development_team_title': 'Development Team',
      'team_intro_title': 'The Letra Development Team',
      'team_intro_body': 'The application was developed by a dedicated team with a mission to connect tourists and explore the beauty of Vietnam.',

      // Security Screen
      'security_title': 'Security',
      'change_password': 'Change Password',
      'change_password_subtitle': 'Update to a new password',
      
      // Home Screen
      'search_hint': 'Search for places, posts...',
      'sort_tooltip_newest': 'Newest',
      'sort_tooltip_oldest': 'Oldest',
      'no_posts_found': 'No posts found.',
      'friends_button': 'Friends',

      // Login Screen
      'welcome_back': 'Welcome Back',
      'account_label': 'Account',
      'enter_your_email': 'Enter your email',
      'invalid_email_prompt': 'Please enter a valid email',
      'password_label': 'Password',
      'enter_your_password': 'Enter your password',
      'empty_password_prompt': 'Please enter your password',
      'login_button': 'Log In',
      'forgot_password': 'Forgot Password?',
      'register_now': 'Register Now',
      'dev_login_success': 'Logged in successfully with DEV account!',
      'login_success': 'Login and fetch info successful!',
      'invalid_credentials': 'Incorrect email or password.',

      // Settings Screen
      'settings': 'Settings',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'dark_mode_subtitle': 'Protect your eyes at night',
      'language': 'Language',
      'emergency_section_title': 'Emergency',
      'emergency_title': 'Rescue Location Sharing',
      'emergency_subtitle': 'Send location when in danger',
      'account': 'Account',
      'security': 'Security',
      'security_subtitle': 'Change password',
      'your_photos': 'Your Photos',
      'your_photos_subtitle': 'Review the photos you have shared',
      'about_us': 'About Us',
      'development_team': 'Development Team',
      'development_team_subtitle': 'Meet the creators of Letra',
      'sponsors': 'Sponsors',
      'sponsors_subtitle': 'Partners who support the project',
      'app_info': 'Application Information',
      'app_info_subtitle': 'Version, terms, policies',
      'logout': 'Log Out',
      'choose_language': 'Choose Language',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',

      // App Info Screen
      'app_info_title': 'App Information',
      'version': 'Version 1.0.0',
      'about_letra_title': 'About Letra',
      'about_letra_body': 'Letra is a Vietnamese travel application that helps you discover and share wonderful destinations across the country.',
      'copyright': '© 2025 Letra. All rights reserved.',

      // User Profile Screen
      'personal_info_title': 'Personal Information',
      'no_name': 'No name yet',
      'no_email': 'No email yet',
      'no_phone': 'No phone number',
      'no_username': 'No username',
      'auth_error': 'Authentication error. Please log in again.',
      'update_failed': 'Update failed. Error code: ',
      'update_success': '✅ Information updated successfully!',
      'update_error': '❌ Error while updating: ',
      'upload_failed': 'Upload failed. Error code: ',
      'avatar_update_success': 'Avatar updated successfully!',
      'generic_error': 'Error: ',
      'username_label': 'Username',
      'full_name_label': 'Full Name',
      'email_label': 'Email',
      'phone_label': 'Phone Number',
      'save_changes_button': 'Save Changes',
    },
    'vi': {
       // General
      'loading': 'Đang tải...',
      'show_less': '<< Thu gọn',
      'show_more': '... Xem thêm >>',

      // Exit Dialog
      'exit_dialog_title': 'Bạn đã muốn rời đi rồi sao? 🥺',
      'exit_dialog_content': 'Bạn có chắc muốn thoát khỏi Letra không?',
      'exit_dialog_yes': 'Thoát',
      'exit_dialog_no': 'Ở lại',

      // Emergency Screen
      'emergency_warning': 'Chức năng này chỉ sử dụng trong trường hợp khẩn cấp',
      'current_location_label': 'Vị trí hiện tại của bạn',
      'address_label': 'Địa chỉ',
      'coordinates_label': 'Tọa độ',
      'accuracy_label': 'Độ chính xác',
      'share_location_button': 'Chia sẻ vị trí',
      'location_shared_button': 'Đã chia sẻ',
      'location_sent_message': 'Vị trí đã được gửi. Vui lòng giữ điện thoại bật.',
      'emergency_contacts_label': 'Số điện thoại khẩn cấp',
      'police': 'Cảnh sát',
      'fire_department': 'Cứu hỏa',
      'ambulance': 'Cấp cứu',
      'rescue': 'Cứu hộ',

      // Photos Screen
      'photos_library': 'Ảnh',
      'no_photos_message': 'Chưa có ảnh nào.\nHãy chụp một tấm!',
      'save_success': 'Đã lưu ảnh vào thư viện!',
      'save_error': 'Không thể lưu ảnh.',
      'save_general_error': 'Lỗi khi lưu ảnh: ',

      // Image Source
      'image_source_title': 'Chọn nguồn ảnh',
      'device_gallery': 'Thư viện máy',
      'app_photos': 'Ảnh đã chụp từ ứng dụng',

      // Create Post Screen
      'create_post_title': 'Tạo bài viết',
      'post_button': 'Đăng',
      'title_label': 'Tiêu đề',
      'location_label': 'Địa điểm (ví dụ: Vịnh Hạ Long)',
      'caption_label': 'Bạn đang nghĩ gì?',
      'add_image_button': 'Thêm ảnh/video',

      // Sort Options
      'sort_by': 'Sắp xếp theo',
      'sort_by_date_newest': 'Ngày (Mới nhất)',
      'sort_by_date_oldest': 'Ngày (Cũ nhất)',
      'sort_by_likes_most': 'Lượt thích (Nhiều nhất)',
      'sort_by_likes_least': 'Lượt thích (Ít nhất)',

      // Change Password Screen
      'change_password_title': 'Đổi mật khẩu',
      'current_password_label': 'Mật khẩu hiện tại',
      'new_password_label': 'Mật khẩu mới',
      'confirm_new_password_label': 'Xác nhận mật khẩu mới',
      'update_password_button': 'Cập nhật mật khẩu',

      // AI Screen
      'ai_assistant_title': 'AI Trợ lý Du lịch',
      'ai_assistant_subtitle': 'Rùa thông minh 🇻🇳',
      'ai_welcome_message': 'Xin chào! Tôi là trợ lý AI du lịch Việt Nam 🐢\nHãy hỏi tôi về các địa điểm du lịch nhé!',
      'ai_input_hint': 'Hỏi AI về du lịch Việt Nam...',
      'ai_response_halong': '🌊 Vịnh Hạ Long là di sản thiên nhiên thế giới tại Quảng Ninh. Bạn nên đi từ tháng 3-5 hoặc 9-11 để thời tiết đẹp nhất. Đừng quên thưởng thức hải sản tươi sống nhé!',
      'ai_response_sapa': '🏔️ Sapa ở Lào Cai nổi tiếng với ruộng bậc thang đẹp nhất vào tháng 9-10. Nhiệt độ mát mẻ quanh năm, nhớ mang áo ấm! Nên thử món thắng cố và cá hồi ở đây.',
      'ai_response_phuquoc': '🏝️ Phú Quốc - đảo ngọc của Việt Nam! Thời điểm lý tưởng là 11-3. Ghé thăm bãi Sao, bãi Dài, và đừng bỏ lỡ chợ đêm Phú Quốc với hải sản tươi ngon!',
      'ai_response_hoian': '🏮 Hội An phố cổ thật đẹp vào buổi tối với đèn lồng rực rỡ. Nên đi vào rằm để thả đèn hoa đăng. Thử cao lầu, mì Quảng và bánh bao vạc nhé!',
      'ai_response_danang': '🌉 Đà Nẵng có Cầu Vàng nổi tiếng, bãi biển Mỹ Khê đẹp nhất Việt Nam. Đi từ tháng 3-8 để tắm biển. Phải thử mì Quảng, bún chả cá!',
      'ai_response_nhatrang': '🏖️ Nha Trang - thiên đường biển! Lặn biển ngắm san hô ở Hòn Mun, tắm bùn khoáng, thưởng thức hải sản tươi ngon. Đi từ tháng 3-9 nhé!',
      'ai_response_dalat': '🌸 Đà Lạt - thành phố ngàn hoa! Thời tiết mát mẻ quanh năm. Ghé hồ Xuân Hương, thác Datanla, và nhớ chụp ảnh tại nhà ga cũ. Thử sữa đậu nành, bánh tráng nướng nhé!',
      'ai_response_weather': '🌤️ Miền Bắc: mùa thu (9-11) đẹp nhất\n🌞 Miền Trung: 2-8 tránh mưa bão\n☀️ Miền Nam: 11-4 khô ráo, dễ đi\n\nBạn muốn đi đâu để tôi tư vấn chi tiết hơn?',
      'ai_response_food': '🍜 Món ăn nổi tiếng:\n• Hà Nội: Phở, bún chả, bánh cuốn\n• Đà Nẵng: Mì Quảng, bún chả cá\n• Hội An: Cao lầu, bánh bao vạc\n• Sài Gòn: Bánh mì, hủ tiếu, cơm tấm\n\nBạn đang ở đâu để tôi gợi ý cụ thể?',
      'ai_response_cost': '💰 Chi phí ước tính (1 ngày):\n• Ngân sách thấp: 300-500k VNĐ\n• Trung bình: 800k-1.5tr VNĐ\n• Cao cấp: 2-5tr VNĐ\n\nBạn muốn biết chi tiết cho địa điểm nào?',
      'ai_response_default': '🐢 Để tôi giúp bạn tốt hơn, hãy hỏi về:\n• Địa điểm du lịch cụ thể\n• Thời tiết và mùa đi\n• Món ăn địa phương\n• Chi phí và lịch trình\nVí dụ: \"Nên đi Sapa vào tháng mấy?\"',

      // Friends Screen
      'friends_title': 'Bạn bè',
      'search_friends_hint': 'Tìm kiếm bạn bè...',

      // Sponsors Screen
      'sponsors_title': 'Nhà tài trợ',
      'sponsors_thank_you': 'Cảm ơn các nhà tài trợ',
      'sponsors_description': 'Dự án được hỗ trợ bởi các đối tác và nhà tài trợ tin tưởng vào tầm nhìn phát triển du lịch Việt Nam.',

      // Team Screen
      'development_team_title': 'Đội ngũ phát triển',
      'team_intro_title': 'Đội ngũ phát triển Letra',
      'team_intro_body': 'Ứng dụng được phát triển bởi đội ngũ tận tâm với sứ mệnh kết nối du khách và khám phá vẻ đẹp Việt Nam.',

      // Security Screen
      'security_title': 'Bảo mật',
      'change_password': 'Đổi mật khẩu',
      'change_password_subtitle': 'Cập nhật mật khẩu mới',

      // Home Screen
      'search_hint': 'Tìm kiếm địa điểm, bài viết...',
      'sort_tooltip_newest': 'Mới nhất',
      'sort_tooltip_oldest': 'Cũ nhất',
      'no_posts_found': 'Không tìm thấy bài viết nào.',
      'friends_button': 'Bạn bè',

      // Login Screen
      'welcome_back': 'Chào mừng trở lại',
      'account_label': 'Tài khoản',
      'enter_your_email': 'Nhập email của bạn',
      'invalid_email_prompt': 'Vui lòng nhập một email hợp lệ',
      'password_label': 'Mật khẩu',
      'enter_your_password': 'Nhập mật khẩu',
      'empty_password_prompt': 'Vui lòng nhập mật khẩu',
      'login_button': 'Đăng nhập',
      'forgot_password': 'Quên mật khẩu?',
      'register_now': 'Đăng ký ngay',
      'dev_login_success': 'Đăng nhập thành công với tài khoản DEV!',
      'login_success': 'Đăng nhập và lấy thông tin thành công!',
      'invalid_credentials': 'Email hoặc mật khẩu không đúng.',

      // Settings Screen
      'settings': 'Cài đặt',
      'appearance': 'Giao diện',
      'dark_mode': 'Chế độ tối',
      'dark_mode_subtitle': 'Bảo vệ mắt khi sử dụng ban đêm',
      'language': 'Ngôn ngữ',
      'emergency_section_title': 'Khẩn cấp',
      'emergency_title': 'Chia sẻ vị trí cứu hộ',
      'emergency_subtitle': 'Gửi vị trí khi gặp nguy hiểm',
      'account': 'Tài khoản',
      'security': 'Bảo mật',
      'security_subtitle': 'Đổi mật khẩu',
      'your_photos': 'Ảnh của bạn',
      'your_photos_subtitle': 'Xem lại những bức ảnh bạn đã chia sẻ',
      'about_us': 'Về chúng tôi',
      'development_team': 'Đội ngũ phát triển',
      'development_team_subtitle': 'Gặp gỡ những người tạo nên Letra',
      'sponsors': 'Nhà tài trợ',
      'sponsors_subtitle': 'Các đối tác hỗ trợ dự án',
      'app_info': 'Thông tin ứng dụng',
      'app_info_subtitle': 'Phiên bản, điều khoản, chính sách',
      'logout': 'Đăng xuất',
      'choose_language': 'Chọn ngôn ngữ',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',

      // App Info Screen
      'app_info_title': 'Thông tin ứng dụng',
      'version': 'Phiên bản 1.0.0',
      'about_letra_title': 'Về Letra',
      'about_letra_body': 'Letra là ứng dụng du lịch Việt Nam giúp bạn khám phá và chia sẻ những điểm đến tuyệt vời trên khắp đất nước.',
      'copyright': '© 2025 Letra. All rights reserved.',

      // User Profile Screen
      'personal_info_title': 'Thông tin cá nhân',
      'no_name': 'Chưa có tên',
      'no_email': 'Chưa có email',
      'no_phone': 'Chưa có SĐT',
      'no_username': 'Chưa có username',
      'auth_error': 'Lỗi xác thực. Vui lòng đăng nhập lại.',
      'update_failed': 'Cập nhật thất bại. Mã lỗi: ',
      'update_success': '✅ Cập nhật thông tin thành công!',
      'update_error': '❌ Lỗi khi cập nhật: ',
      'upload_failed': 'Tải lên thất bại. Mã lỗi: ',
      'avatar_update_success': 'Cập nhật ảnh đại diện thành công!',
      'generic_error': 'Lỗi: ',
      'username_label': 'Tên người dùng',
      'full_name_label': 'Họ và Tên',
      'email_label': 'Email',
      'phone_label': 'Số điện thoại',
      'save_changes_button': 'Lưu thay đổi',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
