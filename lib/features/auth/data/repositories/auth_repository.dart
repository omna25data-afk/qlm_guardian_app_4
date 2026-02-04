import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();

  Future<User> login(String phoneNumber, String password) async { 
    // Changed parameter from email to phoneNumber
    
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber, // Send phone_number as expected by backend
        'password': password
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data);
      
      if (user.token != null) {
        await _storage.write(key: 'auth_token', value: user.token);
      }
      return user;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      await http.post(
        Uri.parse(ApiConstants.logout),
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': 'Bearer $token'
        },
      );
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
