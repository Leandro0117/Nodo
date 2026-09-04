import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nodo/features/create_post/logic/create_post_service.dart';
import 'package:nodo/features/posts/logic/posts_controller.dart';
import 'package:nodo/features/posts/utils/post_format_utils.dart';

class EditPostController extends ChangeNotifier {
  final CreatePostService _service;
  final PostsController postsController;
  final String postId;

  EditPostController(this._service, this.postsController, this.postId, dynamic post) {
    tituloController.text = post['title'] ?? '';
    ubicacionController.text = post['location'] ?? '';
    presupuestoController.text = formatBudget(post['budget']);
    descripcionController.text = post['description'] ?? '';
    final deadline = post['deadline'];
    if (deadline != null) {
      fechaLimiteController.text = deadline.toString().substring(0, 10);
    }
    final categories = post['categories'];
    if (categories is List) {
      selectedCategories = categories
          .map((c) {
            final id = c['specificCategory']?['id'] ?? c['specificCategoryId'];
            return id?.toString();
          })
          .whereType<String>()
          .toList();
    }
    final photos = post['photos'];
    if (photos is List) {
      existingPhotos = photos.whereType<String>().toList();
    }
  }

  bool isLoading = false;
  String? errorMessage;

  final tituloController = TextEditingController();
  final ubicacionController = TextEditingController();
  final presupuestoController = TextEditingController();
  final fechaLimiteController = TextEditingController();
  final descripcionController = TextEditingController();

  List<String> selectedCategories = [];
  List<String> existingPhotos = [];
  List<XFile> newLocalImages = [];

  void setErrorMessage(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setCategories(List<String> categoryIds) {
    selectedCategories = categoryIds;
    notifyListeners();
  }

  void setUbicacion(String value) {
    ubicacionController.text = value;
    notifyListeners();
  }

  void setNewLocalImages(List<XFile> files) {
    newLocalImages = files;
    notifyListeners();
  }

  bool validateFields() {
    if (tituloController.text.isEmpty ||
        selectedCategories.isEmpty ||
        ubicacionController.text.isEmpty ||
        presupuestoController.text.isEmpty ||
        fechaLimiteController.text.isEmpty ||
        descripcionController.text.isEmpty) {
      setErrorMessage("Todos los campos son obligatorios");
      return false;
    }
    setErrorMessage(null);
    return true;
  }

  Future<bool> saveChanges(BuildContext context) async {
    if (!validateFields()) return false;

    try {
      setLoading(true);

      final data = {
        "title": tituloController.text,
        "specificCategoryIds": selectedCategories,
        "location": ubicacionController.text,
        "budget": parseBudget(presupuestoController.text),
        "deadline": fechaLimiteController.text,
        "description": descripcionController.text,
      };

      if (newLocalImages.isNotEmpty) {
        final urls =
            await _service.uploadImagesToFirebase(postId, newLocalImages);
        if (urls.isNotEmpty) {
          data["photos"] = urls;
        }
      }

      final success = await postsController.updatePost(postId, data);
      if (!success) {
        setErrorMessage(postsController.errorMessage);
      }
      return success;
    } catch (e) {
      final mensaje = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      setErrorMessage(mensaje);
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    tituloController.dispose();
    ubicacionController.dispose();
    presupuestoController.dispose();
    fechaLimiteController.dispose();
    descripcionController.dispose();
    super.dispose();
  }
}
