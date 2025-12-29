class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String changepassword = '$baseUrl/auth/change-password';
  static const String forgotpassword = '$baseUrl/auth/forgot-password';
  static const String resetpassword = '$baseUrl/auth/reset-password';

  // Users
  static const String registerUser = '$baseUrl/users/';
  static const String currentUser = '$baseUrl/users/me';
  static String getUserById(int userId) => '$baseUrl/users/$userId';
  static const String searchUsers = '$baseUrl/users/search';
  static const String updateUserAvatar = '$baseUrl/users/me/avatar';
  static const String create = '$baseUrl/users/create';

  // Posts
  static const String createPost = '$baseUrl/posts/';
  static const String getPosts = '$baseUrl/posts/';
  static String deletePost(int postId) => '$baseUrl/posts/$postId';
  static String likePost(String postId) => '$baseUrl/posts/$postId/like';

  // Friends
  static const String addFriend = '$baseUrl/friends/add';
  static const String listFriends = '$baseUrl/friends/list';
  static const String listPendingRequests = '$baseUrl/friends/pending';
  static const String acceptFriendRequest = '$baseUrl/friends/accept';
  static const String rejectFriendRequest = '$baseUrl/friends/reject';

  // AI & Recommendations
  static const String recommendNew = '$baseUrl/recommend/new';
  static const String recommendThreads = '$baseUrl/recommend/threads';
  static String recommendChat(String threadId) =>
      '$baseUrl/recommend/$threadId';
  static String recommendDelete(String threadId) =>
      '$baseUrl/recommend/$threadId';
  static String recommendFeedback(String threadId) =>
      '$baseUrl/recommend/$threadId/feedback';
  static String recommendHistory(String threadId) =>
      '$baseUrl/recommend/$threadId';

  // Landmark Detection
  static const String landmarkDetect = '$baseUrl/landmark/detect';
  static const String landmarkDetectUpload = '$baseUrl/landmark/detect/upload';

  // Media & AI Features
  static const String generateCaption = '$baseUrl/media/caption';
  static const String createAlbumStory = '$baseUrl/media/album';

  // Friend Chat (Placeholders)
  static String getMessageHistory(String friendId) =>
      '$baseUrl/messages/$friendId';
  static const String friendChatWebSocket =
      'ws://127.0.0.1:8000/ws/chat'; // Using 127.0.0.1 for better compatibility

  static const String notificationUnreadCount = '$baseUrl/chat/unread-count';
  static String markMessagesRead(String friendId) =>
      '$baseUrl/chat/messages/$friendId/read';
}
