class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String changepassword = '$baseUrl/auth/change-password';
  static const String forgotpassword = '$baseUrl/auth/forgot-password';
  static const String resetpassword = '$baseUrl/auth/reset-password';


  // Users
  static const String registerUser = '$baseUrl/users/';
  static const String currentUser = '$baseUrl/users/me';
  static const String updateUserAvatar = '$baseUrl/users/me/avatar';
  static const String create = '$baseUrl/users/create';

  // Posts
  static const String createPost = '$baseUrl/posts/';
  static const String getPosts = '$baseUrl/posts/'; // Added this line

  // Friends
  static const String addFriend = '$baseUrl/friends/add';
  static const String listFriends = '$baseUrl/friends/list';
  static const String listPendingRequests = '$baseUrl/friends/pending';
  static const String acceptFriendRequest = '$baseUrl/friends/accept';
  static const String rejectFriendRequest = '$baseUrl/friends/reject';

  // AI
  static const String aiChat = '$baseUrl/chat';

  // Friend Chat (Placeholders)
  static String getMessageHistory(String friendId) => '$baseUrl/messages/$friendId';
  static const String friendChatWebSocket = 'ws://localhost:8000/ws/chat'; // Placeholder URL
}
