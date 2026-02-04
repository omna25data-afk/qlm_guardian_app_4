import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../models/registry_entry.dart';

class RegistryRepository {
  final AuthRepository authRepository;

  RegistryRepository({required this.authRepository});

  Future<List<RegistryEntry>> getRegistryEntries({
    String? status, 
    String? searchQuery,
    int? bookNumber,
    int? recordBookId,
    int? contractTypeId,
    int? hijriYear,
    int? hijriMonth,
    String? sortBy,
    String? sortOrder,
  }) async {
    final token = await authRepository.getToken();
    var queryParams = {
      'status': status,
      'search': searchQuery,
      'book_number': bookNumber?.toString(),
      'guardian_record_book_id': recordBookId?.toString(),
      'contract_type_id': contractTypeId?.toString(),
      'hijri_year': hijriYear?.toString(),
      'hijri_month': hijriMonth?.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    queryParams.removeWhere((key, value) => value == null);

    final uri = Uri.parse(ApiConstants.registryEntries).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token ?? '', // Fallback header for Hostinger
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> decoded = jsonDecode(decodedBody);
      final List<dynamic> data = decoded['data'] ?? [];
      return data.map((e) => RegistryEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load registry entries: ${response.statusCode}');
    }
  }

  Future<RegistryEntry> createEntry(Map<String, String> entryData) async {
    final token = await authRepository.getToken();
    final url = Uri.parse(ApiConstants.registryEntries);
    
    final response = await http.post(
      url, 
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token ?? '', // Fallback header for Hostinger
      }, 
      body: entryData
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      final entryJson = data['data'] ?? data;
      return RegistryEntry.fromJson(entryJson);
    } else {
      throw Exception('Failed to create entry: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
