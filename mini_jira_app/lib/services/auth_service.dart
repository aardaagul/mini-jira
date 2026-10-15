import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        body: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        // Başarılı girişte Token'ı ve kullanıcı e-postasını cihaz hafızasına kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_email', email.trim());
        return true;
      }
      return false;
    } catch (e) {
      print("Giriş servisi hatası: $e");
      return false;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return null;
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['detail'] is List) {
          return "Lütfen geçerli bir e-posta adresi girin (Örn: ad@mail.com).";
        }
        return data['detail']?.toString() ?? 'Kayıt başarısız oldu.';
      }
    } catch (e) {
      return 'Sunucu bağlantı hatası: $e';
    }
  }
}