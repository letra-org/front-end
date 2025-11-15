import 'dart:convert';
import 'package:http/http.dart' as http;

// 1. CLASS MODEL (Có thể đặt ở file riêng, nhưng để đơn giản ta đặt chung)
class LoginDataModel {
  final String username;
  final String password;

  LoginDataModel({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

// 2. CLASS DỊCH VỤ API
class ApiService {
  // Điểm cuối API (Thay thế bằng URL của bạn)
  static const String _apiUrl = 'https://your-backend-server.com/api/login'; 

  // Hàm Gửi Dữ Liệu Đăng Nhập
  // Trả về true nếu thành công, false nếu thất bại (dễ dàng xử lý ở UI)
  Future<bool> sendLoginData(LoginDataModel data) async {
    final jsonData = jsonEncode(data.toJson());

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonData,
      );

      // Xử lý mã trạng thái (ví dụ: 200 OK, 201 Created)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Có thể thêm logic xử lý token hoặc dữ liệu trả về ở đây
        print('Phản hồi thành công: ${response.body}');
        return true; 
      } else {
        // Lỗi từ phía Server (4xx, 5xx)
        print('Lỗi Server: ${response.statusCode}. ${response.body}');
        return false;
      }
    } catch (e) {
      // Lỗi kết nối (Mất mạng, sai URL)
      print('Lỗi kết nối: $e');
      return false;
    }
  }
}