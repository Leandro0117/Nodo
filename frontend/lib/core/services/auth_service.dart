import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/api_constants.dart';
import 'package:nodo/models/user.dart';

class AuthService {
  Future<User?> login(String identificador, String contrasena) async {
    http.Response response;
    try {
      response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identificador,
          'password': contrasena,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      throw Exception(
          'No pudimos conectar con el servidor. Verifica tu conexión e inténtalo de nuevo.');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuario = User.fromJson(data['user']);
      // El registro del token push es secundario: si falla (intermitente,
      // depende de Play Services/red), no debe bloquear un login exitoso.
      try {
        await _guardarTokenFCM(usuario.id);
      } catch (e) {
        debugPrint('No se pudo guardar el token FCM: $e');
      }
      return usuario;
    }

    if (response.statusCode == 401) {
      throw Exception('Usuario o contraseña incorrectos.');
    }

    if (response.statusCode == 403) {
      throw Exception(
          'Tu cuenta no está activa en este momento. Escríbenos si crees que es un error.');
    }

    throw Exception('Ocurrió un error al iniciar sesión. Intenta de nuevo.');
  }

  Future<void> logout(String userId) async {
    try {
      await _deleteTokenFCM(userId);
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  Future<void> _guardarTokenFCM(String userId) async {
    final nuevoToken = await FirebaseMessaging.instance.getToken();
    if (nuevoToken == null) return;

    final prefs = await SharedPreferences.getInstance();
    final tokenGuardado = prefs.getString('fcm_token');

    if (tokenGuardado == nuevoToken) return;

    final response = await http.post(
      Uri.parse(ApiConstants.token),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'token': nuevoToken}),
    );

    if (response.statusCode == 200) {
      await prefs.setString('fcm_token', nuevoToken);
    } else {
      debugPrint('Error al guardar token FCM: ${response.body}');
    }
  }

  Future<void> _deleteTokenFCM(String userId) async {
    await FirebaseMessaging.instance.deleteToken();
    await http.delete(
      Uri.parse(ApiConstants.token),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
  }
}
