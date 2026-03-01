import 'dart:convert';
import 'package:http/http.dart' as http;

class RemoteDataSource {
  final String baseUrl;
  RemoteDataSource({required this.baseUrl});

  Future<String?> getString(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/restaurant/$endpoint'));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      // Error handled by returning null
    }
    return null;
  }

  Future<void> postData(String endpoint, dynamic data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/restaurant/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to post data to $endpoint: ${response.statusCode}');
      }
    } catch (e) {
      // Error handled by throwing exception or logging
    }
  }

  Future<int?> getInt(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/restaurant/$endpoint'));
      if (response.statusCode == 200) {
        return int.parse(response.body);
      }
    } catch (e) {
      // Error handled by returning null
    }
    return null;
  }
}
