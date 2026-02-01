import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';

class AdminGuardianRepository {
  final AuthRepository _authRepository;

  AdminGuardianRepository(this._authRepository);

  Future<List<AdminGuardian>> getGuardians({
    int page = 1,
    String status = 'all',
    String? searchQuery,
  }) async {
    final token = await _authRepository.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      'page': page.toString(),
    };
    
    if (status != 'all') {
      // Map English status to Arabic DB values
      final mappedStatus = status == 'active' ? 'على رأس العمل' : 
                          (status == 'stopped' ? 'متوقف عن العمل' : status);
      queryParams['filter[employment_status]'] = mappedStatus;
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // For now, search by serial number or use a specific filter if configured
      // Spatie Exact Filter on serial_number
      queryParams['filter[serial_number]'] = searchQuery;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/guardians')
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
      return data.map((e) => AdminGuardian.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load guardians: ${response.statusCode}');
    }
  }
  Future<void> createGuardian(Map<String, dynamic> data, {String? imagePath}) async {
    final token = await _authRepository.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/guardians');
    
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    
    _addFieldsToRequest(request, data);
    
    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('personal_photo', imagePath));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create guardian: ${response.body}');
    }
  }

  Future<void> updateGuardian(int id, Map<String, dynamic> data, {String? imagePath}) async {
    final token = await _authRepository.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/guardians/$id');
    
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    
    _addFieldsToRequest(request, data);
    request.fields['_method'] = 'PUT'; // Laravel trick for PUT multipart
    
    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('personal_photo', imagePath));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Failed to update guardian: ${response.body}');
    }
  }

  void _addFieldsToRequest(http.MultipartRequest request, Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          request.fields['$key[$i]'] = value[i].toString();
        }
      } else if (value != null) {
        request.fields[key] = value.toString();
      }
    });
  }

  Future<void> deleteGuardian(int id) async {
    final token = await _authRepository.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/guardians/$id');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete guardian');
    }
  }
}
