import 'dart:convert';

import 'package:http/http.dart' as http;

class HealthController {
  Future<String> showWelcomeMessage() async {
    return await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Welcome to KindMap!';
      } else {
        throw Exception(
            'Failed to fetch welcome message: ${response.statusCode}');
      }
    });
  }

  Future<Map<String, dynamic>> performHealthCheck() async {
    return await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/keep-alive"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    });
  }
}
