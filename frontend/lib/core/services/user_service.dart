import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../constants/api_constants.dart';

class UserService {
  Future<User> getUser(String id) async {
    final response = await http.get(Uri.parse(ApiConstants.user(id)));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al obtener el usuario (${response.statusCode})');
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(ApiConstants.user(id)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el perfil (${response.statusCode})');
    }
  }

  Future<void> activateWorker(String id, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.activateWorker(id)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al activar el perfil de trabajador');
    }
  }
}
