import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guardian_app/features/admin/data/models/admin_area_model.dart';

class AdminAreasRepository {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AdminAreasRepository({required this.baseUrl});

  Future<List<AdminArea>> getAreas({int page = 1, String? searchQuery, String? type, String? parentId}) async {
    final token = await _storage.read(key: 'auth_token');
    
    // Construct query parameters
    Map<String, String> queryParams = {
      'page': page.toString(),
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['filter[name]'] = searchQuery;
    }
    if (type != null) {
      queryParams['filter[type]'] = type;
    }
    if (parentId != null) {
      queryParams['filter[parent_id]'] = parentId;
    }
    // Only active areas
    queryParams['filter[is_active]'] = '1';

    final uri = Uri.parse('$baseUrl/geographic-areas').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['data'];
        return items.map((json) => AdminArea.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching areas: $e');
    }
  }

  Future<List<AdminArea>> getDistricts({String? query}) => getAreas(searchQuery: query, type: 'عزلة');
  Future<List<AdminArea>> getVillages({String? query, String? parentId}) => getAreas(searchQuery: query, type: 'قرية', parentId: parentId);
  Future<List<AdminArea>> getLocalities({String? query, String? parentId}) => getAreas(searchQuery: query, type: 'محل', parentId: parentId);
  Future<void> createArea(Map<String, dynamic> data) async {
    final token = await _storage.read(key: 'auth_token');
    final uri = Uri.parse('$baseUrl/admin/areas');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create area: ${response.body}');
    }
  }
}

