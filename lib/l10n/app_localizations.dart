import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'loading': 'Loading...',
      'show_less': '<< Show less',
      'show_more': '... Show more >>',

      // Emergency Screen
      'emergency_warning': 'This feature should only be used in an emergency',
      'current_location_label': 'Your Current Location',
      'address_label': 'Address',
      'coordinates_label': 'Coordinates',
      'accuracy_label': 'Accuracy',
      'share_location_button': 'Share Location',
      'location_shared_button': 'Location Shared',
      'location_sent_message':
          'Location has been sent. Please keep your phone on.',
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
      'albums_tab': 'Albums',
      'library_tab': 'Library',
      'create_album': 'Create Album',
      'album_name_hint': 'Enter album name',
      'delete_album_confirm': 'Are you sure you want to delete this album?',
      'add_to_album': 'Add to Album',
      'album_empty': 'This album is empty',
      'select_photos': 'Select Photos',
      'album_created_success': 'Album created successfully!',
      'already_in_album': 'Photo is already in this album',

      // Image Source
      'image_source_title': 'Choose Image Source',
      'device_gallery': 'Device Gallery',
      'app_photos': 'App Photos',
      'create_post_title': 'Create Post',
      'post_button': 'Post',
      'title_label': 'Title',
      'location_label': 'Location (e.g., Ha Long Bay)',
      'caption_label': 'What are you thinking?',
      'add_image_button': 'Add Image/Video',
      'add_image_tooltip': 'Add Image',
      'add_video_tooltip': 'Add Video',

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
      'ai_delete_success': 'Delete done!',
      'ai_conversation': 'Conversation',
      'ai_messages': 'messages',

      // Friends Screen
      'friends_title': 'Friends',
      'search_friends_hint': 'Search for friends...',

      // Sponsors Screen
      'sponsors_title': 'Sponsors',
      'sponsors_thank_you': 'Thank You to Our Sponsors',
      'sponsors_description':
          'This project is supported by partners and sponsors who believe in the vision of developing tourism in Vietnam.',

      // Team Screen
      'development_team_title': 'Development Team',
      'team_intro_title': 'The Letra Development Team',
      'team_intro_body':
          'The application was developed by a dedicated team with a mission to connect tourists and explore the beauty of Vietnam.',

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
      'chat_title': 'Chat',
      'type_your_message_hint': 'Type your message...',
      'whats_on_your_mind': "What's on your mind?",
      'connecting': 'Connecting...',
      'connected': 'Connected',
      'disconnected': 'Disconnected',
      'connection_error': 'Connection Error',
      'auth_token_missing': 'Authentication token missing.',
      'offline_message_notice':
          'Friend is currently offline. Messages will be delivered later.',
      'chat_with': 'Chat with',
      'exit_confirm_title': 'Exit App?',
      'exit_confirm_message': 'Are you sure you want to exit the app?',
      'exit_button': 'Exit',
      'stay_button': 'Stay',
      'ai_match_reason': 'Match Reason:',
      'ai_recommendation_summary':
          'Based on your profile, here are some suggestions:',
      'no_description': 'No description available.',
      'unknown_destination': 'Unknown Destination',
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
      'about_letra_body':
          'Letra is a Vietnamese travel application that helps you discover and share wonderful destinations across the country.',
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
      'current_password_empty': 'Please enter your current password',
      'new_password_short': 'Password must be at least 6 characters',
      'passwords_mismatch': 'Passwords do not match',
      'invalid_data_error': 'Invalid data.',
      'password_recovery': 'Password Recovery',
      'password_recovery_instructions':
          'Enter your email address and we will send you a link to reset your password.',
      'empty_email_prompt': 'Please enter your email',
      'send_recovery_email_button': 'Send Recovery Email',
      'back_to_login': 'Back to Login',
      'email_sent_title': 'Email Sent!',
      'check_your_email_part1': 'Please check your email ',
      'check_your_email_part2': ' for instructions to reset your password.',
      'no_email_found_message':
          'Didn\'t receive an email? Check your spam folder or try again.',
      'reset_password_title': 'Reset Password',
      'reset_password_subtitle': 'Create a new secure password',
      'reset_password_button': 'Reset Password',
      'reset_success_message': 'Your password has been successfully reset!',
      'unfriend_button': 'Unfriend',
      'unfriend_confirm_title': 'Unfriend?',
      'unfriend_confirm_message':
          'Are you sure you want to remove this friend?',
      'unfriend_success': 'Removed friend successfully',
      'yes_label': 'Yes',
      'no_label': 'No',
      'generate_ai_caption': 'Generate AI Caption',
      'ai_generating': 'AI is thinking...',
      'ai_caption_error': 'Failed to generate caption',
      'no_image_selected': 'Please select an image first',
      'generate_ai_story': 'Generate AI Story',
      'ai_album_story_error': 'Failed to generate story',
      'select_multiple_images': 'Please select at least 2 images',
      'change_password_success':
          'Password changed successfully. Please login again with your new password.',
      'enable_location_sharing': 'Enable Emergency Location Sharing',
      'location_permission_denied':
          'Location permission is required for this feature',
      'location_permission_settings': 'Please enable location in settings',
      //Create Posts Screen
      'post_created_successfully': 'Post created successfully',
      'post_creation_failed': 'Post creation failed',
      'delete_post_confirm_title': 'Delete Post',
      'delete_post_confirm_message':
          'Are you sure you want to delete this post?',
      'delete_post_success': 'Post deleted successfully',
      'delete_post_failed': 'Failed to delete post',
    },
    'vi': {
      // General
      'loading': 'Đang tải...',
      'show_less': '<< Thu gọn',
      'show_more': '... Xem thêm >>',

      // Emergency Screen
      'emergency_warning':
          'Chức năng này chỉ sử dụng trong trường hợp khẩn cấp',
      'current_location_label': 'Vị trí hiện tại của bạn',
      'address_label': 'Địa chỉ',
      'coordinates_label': 'Tọa độ',
      'accuracy_label': 'Độ chính xác',
      'share_location_button': 'Chia sẻ vị trí',
      'location_shared_button': 'Đã chia sẻ',
      'location_sent_message':
          'Vị trí đã được gửi. Vui lòng giữ điện thoại bật.',
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
      'albums_tab': 'Album',
      'library_tab': 'Thư viện',
      'create_album': 'Tạo Album',
      'album_name_hint': 'Nhập tên album',
      'delete_album_confirm': 'Bạn có chắc muốn xóa album này không?',
      'add_to_album': 'Thêm vào Album',
      'album_empty': 'Album này đang trống',
      'select_photos': 'Chọn ảnh',
      'album_created_success': 'Đã tạo album thành công!',
      'already_in_album': 'Ảnh đã có trong album này',

      // Image Source
      'image_source_title': 'Chọn nguồn ảnh',
      'device_gallery': 'Thư viện thiết bị',
      'app_photos': 'Ảnh trong ứng dụng',

      // Create Post Screen
      'create_post_title': 'Tạo bài viết',
      'post_button': 'Đăng',
      'title_label': 'Tiêu đề',
      'location_label': 'Địa điểm (ví dụ: Vịnh Hạ Long)',
      'caption_label': 'Bạn đang nghĩ gì?',
      'add_image_button': 'Thêm ảnh/video',
      'add_image_tooltip': 'Thêm ảnh',
      'add_video_tooltip': 'Thêm video',

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
      'ai_delete_success': 'Đã xoá thành công',
      'ai_conversation': 'Cuộc trò chuyện',
      'ai_messages': 'tin nhắn',

      // Friends Screen
      'friends_title': 'Bạn bè',
      'search_friends_hint': 'Tìm kiếm bạn bè...',

      // Sponsors Screen
      'sponsors_title': 'Nhà tài trợ',
      'sponsors_thank_you': 'Cảm ơn các nhà tài trợ',
      'sponsors_description':
          'Dự án được hỗ trợ bởi các đối tác và nhà tài trợ tin tưởng vào tầm nhìn phát triển du lịch Việt Nam.',

      // Team Screen
      'development_team_title': 'Đội ngũ phát triển',
      'team_intro_title': 'Đội ngũ phát triển Letra',
      'team_intro_body':
          'Ứng dụng được phát triển bởi đội ngũ tận tâm với sứ mệnh kết nối du khách và khám phá vẻ đẹp Việt Nam.',

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
      'chat_title': 'Trò chuyện',
      'type_your_message_hint': 'Nhập tin nhắn...',
      'whats_on_your_mind': 'Bạn đang nghĩ gì?',
      'connecting': 'Đang kết nối...',
      'connected': 'Đã kết nối',
      'disconnected': 'Đã ngắt kết nối',
      'connection_error': 'Lỗi kết nối',
      'auth_token_missing': 'Thiếu mã xác thực.',
      'offline_message_notice':
          'Bạn bè hiện đang ngoại tuyến. Tin nhắn sẽ được gửi sau.',
      'chat_with': 'Trò chuyện với',
      'exit_confirm_title': 'Thoát ứng dụng?',
      'exit_confirm_message': 'Bạn có chắc chắn muốn thoát ứng dụng không?',
      'exit_button': 'Thoát',
      'stay_button': 'Ở lại',
      'ai_match_reason': 'Lý do phù hợp:',
      'ai_recommendation_summary':
          'Dựa trên lựa chọn của bạn, đây là một vài gợi ý:',
      'no_description': 'Không có mô tả.',
      'unknown_destination': 'Điểm đến không xác định',
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
      'about_letra_body':
          'Letra là ứng dụng du lịch Việt Nam giúp bạn khám phá và chia sẻ những điểm đến tuyệt vời trên khắp đất nước.',
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
      'current_password_empty': 'Vui lòng nhập mật khẩu hiện tại',
      'new_password_short': 'Mật khẩu phải có ít nhất 6 ký tự',
      'passwords_mismatch': 'Mật khẩu không khớp',
      'invalid_data_error': 'Dữ liệu không hợp lệ.',
      'password_recovery': 'Khôi phục mật khẩu',
      'password_recovery_instructions':
          'Nhập địa chỉ email của bạn và chúng tôi sẽ gửi cho bạn một liên kết để đặt lại mật khẩu.',
      'empty_email_prompt': 'Vui lòng nhập email của bạn',
      'send_recovery_email_button': 'Gửi email khôi phục',
      'back_to_login': 'Quay lại đăng nhập',
      'email_sent_title': 'Đã gửi email!',
      'check_your_email_part1': 'Vui lòng kiểm tra email ',
      'check_your_email_part2': ' để xem hướng dẫn đặt lại mật khẩu.',
      'no_email_found_message':
          'Bạn không nhận được email? Hãy kiểm tra hòm thư rác hoặc thử lại.',
      'reset_password_title': 'Đặt lại mật khẩu',
      'reset_password_subtitle': 'Tạo mật khẩu an toàn mới',
      'reset_password_button': 'Đặt lại mật khẩu',
      'reset_success_message': 'Mật khẩu của bạn đã được đặt lại thành công!',
      'unfriend_button': 'Hủy kết bạn',
      'unfriend_confirm_title': 'Hủy kết bạn?',
      'unfriend_confirm_message':
          'Bạn có chắc chắn muốn hủy kết bạn với người này?',
      'unfriend_success': 'Đã hủy kết bạn thành công',
      'yes_label': 'Có',
      'no_label': 'Không',
      'generate_ai_caption': 'Tạo chú thích AI',
      'ai_generating': 'AI đang suy nghĩ...',
      'ai_caption_error': 'Không thể tạo chú thích',
      'no_image_selected': 'Vui lòng chọn ảnh trước',
      'generate_ai_story': 'Tạo câu chuyện AI',
      'ai_album_story_error': 'Không thể tạo câu chuyện',
      'select_multiple_images': 'Vui lòng chọn ít nhất 2 ảnh',
      'change_password_success':
          'Đổi mật khẩu thành công. Vui lòng đăng nhập lại với mật khẩu mới.',
      'enable_location_sharing': 'Bật chia sẻ vị trí khẩn cấp',
      'location_permission_denied':
          'Cần quyền truy cập vị trí để sử dụng tính năng này',
      'location_permission_settings': 'Vui lòng bật vị trí trong cài đặt',
      //Create Posts Screen
      'post_created_successfully': 'Bài viết đã được tạo thành công',
      'post_creation_failed': 'Tạo bài viết thất bại',
      'delete_post_confirm_title': 'Xóa bài viết',
      'delete_post_confirm_message':
          'Bạn có chắc chắn muốn xóa bài viết này không?',
      'delete_post_success': 'Xóa bài viết thành công',
      'delete_post_failed': 'Xóa bài viết thất bại'
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
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
