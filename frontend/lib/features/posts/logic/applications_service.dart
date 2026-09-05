import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nodo/core/constants/api_constants.dart';
import 'package:nodo/features/posts/models/job_application.dart';

class ApplicationsService {
  Future<List<JobApplication>> getApplicationsByPostId(String postId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.applicationsByPostId(postId)),
    );

    if (response.statusCode == 204) {
      return [];
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => JobApplication.fromJson(json)).toList();
    }

    throw Exception('Error al cargar las postulaciones (${response.statusCode})');
  }

  Future<bool> updateApplicationStatus(
      String applicationId, String newStatus) async {
    final response = await http.put(
      Uri.parse(ApiConstants.application(applicationId)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );
    return response.statusCode == 200;
  }
}
