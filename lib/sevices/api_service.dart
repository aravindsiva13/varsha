import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // base URL
  static const String baseUrl = 'https://dummyjson.com';

  // headers
  static Map<String, String> get headers => {
        "Content-Type": "application/json",
      };

  // GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("GET Failed: ${response.statusCode} ${response.body}");
    }
  }

  // POST
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("POST Failed: ${response.statusCode} ${response.body}");
    }
  }
}
