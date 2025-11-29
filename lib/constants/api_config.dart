class ApiConfig {
  static const String baseUrl = 'https://hvn785k2-8000.asse.devtunnels.ms';

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
}
