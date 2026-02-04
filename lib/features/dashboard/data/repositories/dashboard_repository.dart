import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  final AuthRepository authRepository;

  DashboardRepository({required this.authRepository});

  Future<DashboardData> getDashboard() async {
    final token = await authRepository.getToken();
    final response = await http.get(
      Uri.parse(ApiConstants.dashboard),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token ?? '', // Fallback header for Hostinger
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decodedBody);
      return DashboardData.fromJson(json);
    } else {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
  }
}
