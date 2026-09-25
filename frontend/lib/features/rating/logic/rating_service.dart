import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nodo/core/constants/api_constants.dart';

class RatingService {
  /// Envía la calificación de [raterId] hacia [ratedId] por el servicio [serviceId].
  static Future<void> submitRating({
    required String serviceId,
    required String raterId,
    required String ratedId,
    required int score,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.createRating),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'serviceId': serviceId,
        'raterId': raterId,
        'ratedId': ratedId,
        'score': score,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('❌ Error al enviar calificación: ${response.body}');
      throw Exception('Error al enviar calificación (${response.statusCode})');
    }
    debugPrint('✅ Calificación enviada');
  }

  /// Devuelve las calificaciones de un usuario separadas por rol.
  /// Estructura: `{ asWorker: { avg, count }, asClient: { avg, count } }`
  static Future<Map<String, dynamic>?> getUserRatings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getUserRatings(userId)),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ No se pudieron cargar calificaciones del usuario: $e');
      return null;
    }
  }

  /// Devuelve la calificación existente del [userId] para el [serviceId], o null si no existe.
  static Future<Map<String, dynamic>?> getMyRating(
      String serviceId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getRatingByServiceAndUser(serviceId, userId)),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ No se pudo cargar calificación previa: $e');
      return null;
    }
  }
}
