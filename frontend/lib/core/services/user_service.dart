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

  /// Lanza una excepción con un mensaje listo para mostrar si la contraseña
  /// no coincide o si el servidor no pudo desactivar la cuenta.
  Future<void> deactivateAccount(String id, String password) async {
    http.Response response;
    try {
      response = await http.post(
        Uri.parse(ApiConstants.deactivateUser(id)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw Exception(
          'No pudimos conectar con el servidor. Verifica tu conexión e inténtalo de nuevo.');
    }

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) {
      throw Exception('La contraseña no es correcta.');
    }
    if (response.statusCode == 409) {
      throw Exception(
          'Tienes un trabajo en curso. Finalízalo antes de desactivar tu cuenta.');
    }
    throw Exception('No pudimos desactivar tu cuenta. Intenta de nuevo.');
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
