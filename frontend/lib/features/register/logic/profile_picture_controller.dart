import 'dart:io';
import 'dart:convert';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nodo/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:nodo/shared/providers/register_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// import 'package:nodo/shared/providers/user_provider.dart';
// import 'package:mime/mime.dart';

class ProfilePictureController extends ChangeNotifier {
  bool acceptedTerms = false;
  File imageFile = File('');
  bool isLoading = false;

  /// Seleccionar imagen desde galería
  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> uploadImageViaBackend(
      String id, File imagen) async {
      final fileName = '${id}_${path.basename(imagen.path)}';
    debugPrint("Subiendo imagen mediante backend: $fileName");

    try {
      // Obtener URL firmada desde tu backend
        final extension = path.extension(imagen.path).toLowerCase();

      final mimeType = extension == '.png' ? 'image/png' :
                 extension == '.heic' ? 'image/heic' : 'image/jpeg';
      final response = await http.get(
        Uri.parse(ApiConstants.generateUploadUrl(fileName, mimeType)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final uploadUrl = data['url'];
        debugPrint("URL de subida obtenida: $uploadUrl");
        // Subir imagen directamente a Firebase usando esa URL
        // 2️⃣ Detectar tipo MIME automáticamente (jpg, png, etc.)
        //final mimeType =
        //    lookupMimeType(imagen.path) ?? 'application/octet-stream';

        // 3️⃣ Subir imagen directamente a Firebase Storage mediante la URL firmada
        final bytes = await imagen.readAsBytes();
        final putResponse = await http.put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': mimeType},
          body: bytes,
        );

        if (putResponse.statusCode != 200) {
          throw Exception('Error subiendo imagen: ${putResponse.body}');
        }

        if (putResponse.statusCode == 200) {
          debugPrint('✅ Imagen subida correctamente');
        } else {
          debugPrint('❌ Error subiendo imagen: ${putResponse.statusCode}');
        }
      } else {
        debugPrint('❌ Error obteniendo URL firmada: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error: $e');
    }
  }

  /*
  /// Subir imagen a Firebase Storage
  Future<String> subirImagenAFirebase(File imagen, String id) async {
    debugPrint("Subiendo imagen para el usuario: $id");
    try {
      final nombreArchivo = '${id}_${path.basename(imagen.path)}';
      final ref =
          FirebaseStorage.instance.ref().child('perfiles/$nombreArchivo');

      final uploadTask = ref.putFile(imagen);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint("Error al subir imagen: $e");
      rethrow;
    }
  }
  */
  /// Enviar URL de la imagen al backend
  Future<void> sendImageToBackend(String id, String urlFoto) async {
    debugPrint("Enviando URL de imagen al backend para el usuario: $id");
    final String apiUrl = ApiConstants.user(id);
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'profilePhoto': urlFoto}),
      );

      if (response.statusCode != 200) {
        debugPrint('Error al actualizar imagen: ${response.body}');
      }
    } catch (e) {
      debugPrint('Excepción al enviar imagen: $e');
    }
  }

  /// Confirmar acción final del registro
  Future<bool> confirm(BuildContext context) async {
    if (!acceptedTerms || isLoading) return false;

    isLoading = true;
    notifyListeners();

    try {
      final registerProvider =
          Provider.of<RegisterProvider>(context, listen: false);
      final id = registerProvider.id;
      if (id == null) throw Exception('ID de usuario no encontrado');
      uploadImageViaBackend(id, imageFile);
      /*
      final urlImagen = imageFile != null
          ? await subirImagenAFirebase(imageFile!, id)
          : "https://firebasestorage.googleapis.com/v0/b/nodo-b1ff4.firebasestorage.app/o/perfiles%2FiconNodoBlue.png?alt=media&token=22b11580-c0ac-403e-89e3-5f09cc5cd25c";

      await enviarImagenAlBackend(id, urlImagen);
      */
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_welcome', true);

      return true;
    } catch (e) {
      debugPrint('Error en confirmar: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar el estado de aceptación de términos
  void toggleAccepted(bool? value) {
    acceptedTerms = value ?? false;
    notifyListeners();
  }
}
