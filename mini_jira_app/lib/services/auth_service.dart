import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');
    
    try {
      // FastAPI OAuth2 formu olarak beklediği için body Map olarak gönderilir
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
        
        // Başarılı girişte Token'ı cihaz hafızasına kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        return true;
      }
      return false; // Hatalı e-posta veya şifre
    } catch (e) {
      print("Giriş servisi hatası: $e");
      return false;
    }
  }
}