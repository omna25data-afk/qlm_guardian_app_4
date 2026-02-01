import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/admin/data/models/admin_renewal_model.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';

class AdminRenewalsRepository {
  final AuthRepository _authRepository;

  AdminRenewalsRepository(this._authRepository);

  Future<List<AdminRenewal>> getLicenses({
    int page = 1,
    String? searchQuery,
  }) async {
    return _fetchRenewals('/license-managements', page, searchQuery);
  }

  Future<List<AdminRenewal>> getCards({
    int page = 1,
    String? searchQuery,
  }) async {
    return _fetchRenewals('/electronic-card-renewals', page, searchQuery);
  }

  Future<List<AdminRenewal>> _fetchRenewals(String endpoint, int page, String? searchQuery) async {
    final token = await _authRepository.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      'page': page.toString(),
    };
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Basic filter by ID for now as Spatie exact text search needs setup
      queryParams['filter[id]'] = searchQuery;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as List;
      return data.map((e) => AdminRenewal.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load renewals: ${response.statusCode}');
    }
  }
}
