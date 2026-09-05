import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/user_provider.dart';

class PostsService {
  final UserProvider userProvider;

  PostsService(this.userProvider);

  Future<List<dynamic>> getPostsByUserId() async {
    final userId = userProvider.user!.id;
    final response = await http.get(
      Uri.parse(ApiConstants.postsByUserId(userId)),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData is List) {
        return responseData;
      } else if (responseData is Map &&
          (responseData['message'] == 'No existen registros' ||
              responseData['message'] == 'No records found')) {
        return [];
      }
      throw Exception('Formato de respuesta inesperado');
    }
    throw Exception(
        'Error al cargar las publicaciones (${response.statusCode})');
  }

  Future<bool> deletePost(String postId) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.post(postId)),
    );
    return response.statusCode == 200;
  }

  Future<bool> finishJob(String postId) async {
    final response = await http.put(
      Uri.parse(ApiConstants.finishJob),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'postId': postId}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updatePost(
      String postId, Map<String, dynamic> data) async {
    final url = Uri.parse(ApiConstants.post(postId));

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      String mensaje = 'No se pudo actualizar la publicación.';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) mensaje = body['message'];
      } catch (_) {}
      throw Exception(mensaje);
    }
  }
}
