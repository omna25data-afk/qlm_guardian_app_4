import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../models/record_book.dart';

class RecordsRepository {
  final AuthRepository authRepository;

  RecordsRepository({required this.authRepository});

  Future<List<RecordBook>> getRecordBooks() async {
    final token = await authRepository.getToken();
    final response = await http.get(
      Uri.parse(ApiConstants.recordBooks),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token!, // Fallback header
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decodedBody);
      // Determine if list is directly returned or wrapped in 'data'
      final List<dynamic> data = json is List ? json : (json['data'] ?? []);
      return data.map((e) => RecordBook.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load record books: ${response.statusCode}');
    }
  }
}
