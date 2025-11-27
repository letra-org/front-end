class ApiConfig {
  static const String baseUrl = 'https://hvn785k2-8000.asse.devtunnels.ms';

  // Auth
  static const String login = '$baseUrl/auth/login';

  // Users
  static const String registerUser = '$baseUrl/users/';
  static const String currentUser = '$baseUrl/users/me';
  static const String updateUserAvatar = '$baseUrl/users/me/avatar';

  // Posts
  static const String createPost = '$baseUrl/posts/';
}
