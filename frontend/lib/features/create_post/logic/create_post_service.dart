import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/utils/image_utils.dart';
import 'package:flutter/material.dart';

class CreatePostService {
  // Crear la publicación y devolver el ID
  Future<String?> createPost(
      Map<String, dynamic> postData) async {
    final response = await http.post(
      Uri.parse(ApiConstants.createPost),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(postData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id']; // asegúrate de que tu backend devuelva esto
    } else {
      String mensaje = 'No se pudo crear la publicación.';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) mensaje = body['message'];
      } catch (_) {}
      throw Exception(mensaje);
    }
  }

  // Actualizar las URLs de las fotos
  Future<bool> updatePhotos(String postId, List<String> urls) async {
    final response = await http.put(
      Uri.parse(ApiConstants.updatePost(postId)),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"photos": urls}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudieron guardar las fotos de la publicación.');
    } else {
      return true;
    }
  }

  // Borra una publicación. Se usa para deshacer la creación si algo falla
  // después (p. ej. la subida de imágenes), así no queda una publicación
  // huérfana sin fotos.
  Future<void> deletePost(String postId) async {
    await http.delete(Uri.parse(ApiConstants.deletePost(postId)));
  }

  // Trabaja con XFile (y no dart:io File) para que la subida funcione tanto
  // en mobile/desktop como en Flutter Web, donde no existe un filesystem real.
  Future<List<String>> uploadImagesToFirebase(
      String postId, List<XFile> localImages) async {
    List<String> urls = [];

    try {
      for (int i = 0; i < localImages.length; i++) {
        final bytes = await localImages[i].readAsBytes();
        final webpBytes = await ImageUtils.convertToWebPBytes(bytes);

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.webp';
        final ref = FirebaseStorage.instance
            .ref()
            .child('publicaciones/$postId/$fileName');

        final uploadTask = ref.putData(
          webpBytes,
          SettableMetadata(contentType: 'image/webp'),
        );
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception('No se pudo cargar la imagen. Inténtalo de nuevo.');
    }

    return urls;
  }
}
