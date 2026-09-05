import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nodo/core/constants/api_constants.dart';
import 'package:flutter/material.dart';

class JobService {
  static Future<void> apply(
      String publicacionId, String trabajadorId) async {
    debugPrint("💬Postulando...");
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.apply),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'postId': publicacionId,
          'workerId': trabajadorId,
        }),
      );
      debugPrint("💬Respuesta del servidor: ");

      debugPrint(response.body);
      if (response.statusCode == 200) {
        // Postulación exitosa
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Postulación exitosa: $responseData');
      } else {
        // Error en la postulación
        throw Exception('Error al postularse: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en postularse: $e');
      rethrow; // Re-lanzamos la excepción para manejarla en el UI
    }
  }

  static Future<void> deleteApplication(String applicationId) async {
    debugPrint("💬Eliminando postulación...");
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.application(applicationId)),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      debugPrint("💬Respuesta del servidor: ");

      debugPrint(response.body);
      if (response.statusCode == 200) {
        // Postulación exitosa
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Postulación exitosa: $responseData');
      } else {
        // Error en la postulación
        throw Exception('Error al postularse: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en postularse: $e');
      rethrow; // Re-lanzamos la excepción para manejarla en el UI
    }
  }

  static Future<void> acceptApplication(
      String applicationId, String newStatus) async {
    final url =
        Uri.parse(ApiConstants.application(applicationId));

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode == 200) {
      debugPrint("❕❕❕Status code 200");
    } else {
      debugPrint("❕❕❕Error");
    }
  }

  static Future<List<dynamic>> fetchPosts() async {
    debugPrint("💬 Haciendo fetch a publicaciones");
    final response = await http.get(
      Uri.parse(ApiConstants.posts),
      headers: {'Content-Type': 'application/json'},
    );
    debugPrint("💬 PubLicaciones: ");
    debugPrint(response.body);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar publicaciones: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> fetchPostsForWorker(String workerId) async {
    debugPrint("💬 Haciendo fetch a publicaciones para trabajador $workerId");
    final response = await http.get(
      Uri.parse(ApiConstants.postsForWorker(workerId)),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar publicaciones: ${response.statusCode}');
    }
  }

  static Future<Map<String, String>> fetchClientNames(
      List posts) async {
    debugPrint("💬 Haciendo fetch a usuarios");

    final Map<String, String> names = {};
    final clientIds =
        posts.map((p) => p['clientId']).toSet().toList();
    for (final clientId in clientIds) {
      final response = await http.get(
        Uri.parse(ApiConstants.user(clientId)),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint("Usuario");
      debugPrint(response.body);
      if (response.statusCode == 200) {
        final clientData = json.decode(response.body);
        names[clientId] = clientData['firstName'];
      } else {
        names[clientId] = 'Cliente $clientId';
      }
    }
    debugPrint("Nombres: ");
    debugPrint(names.toString());

    return names;
  }

  static Future<List<dynamic>> fetchApplicationsByUser(
      String userId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.applicationsByUserId(userId)),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    debugPrint("💬 Postulaciones: ");
    debugPrint(response.statusCode.toString());

    if (response.statusCode == 200) {
      debugPrint("✅ Se encontraron postulaciones");

      return jsonDecode(response.body);
    } else if (response.statusCode == 204) {
      debugPrint("⚠️ No se encontraron postulaciones");
      return [];
    } else {
      throw Exception('Error al cargar postulaciones');
    }
  }

  static IconData getIconForCategory(String categoryId) {
    switch (categoryId) {
      case 'cat1':
        return Icons.plumbing;
      case 'cat2':
        return Icons.bug_report;
      case 'cat3':
        return Icons.electrical_services;
      case 'cat4':
        return Icons.computer;
      default:
        return Icons.work;
    }
  }

  static String formatTimeAgo(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Recién publicado';
    }
  }

  static Future<void> markAsFinished(String applicationId) async {
    debugPrint("❕❕❕❕Finalizando trabajo");

    final url = Uri.parse(ApiConstants.finishJob);

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'applicationId': applicationId,
      }),
    );
    debugPrint("STATUS CODE: ");
    debugPrint(response.statusCode.toString());
  }

  static Future<void> cancelJob(String? applicationId) async {
    // Llama a tu API y cambia el estado del trabajo a "cancelado"
  }
}
