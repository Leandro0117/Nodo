import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nodo/features/create_post/logic/create_post_service.dart';
import 'package:nodo/features/posts/logic/posts_controller.dart';
import 'package:nodo/features/posts/utils/post_format_utils.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';

class CreatePostController extends ChangeNotifier {
  final CreatePostService _service;

  CreatePostController(this._service);

  bool isLoading = false;
  String? errorMessage;

  // Campos
  final tituloController = TextEditingController();
  final ubicacionController = TextEditingController();
  final presupuestoController = TextEditingController();
  final fechaLimiteController = TextEditingController();
  final descripcionController = TextEditingController();

  List<String> selectedCategories = [];
  List<XFile> localImages = []; // imágenes locales
  List<String> imageUrls = []; // URLs tras subida

  void setErrorMessage(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void toggleCategory(String categoryId) {
    if (selectedCategories.contains(categoryId)) {
      selectedCategories.remove(categoryId);
    } else {
      selectedCategories.add(categoryId);
    }
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

  void setLocalImages(List<XFile> files) {
    localImages = files;
    notifyListeners();
  }

  void clearForm() {
    tituloController.clear();
    ubicacionController.clear();
    presupuestoController.clear();
    fechaLimiteController.clear();
    descripcionController.clear();
    selectedCategories.clear();
    localImages.clear();
    imageUrls.clear();
    errorMessage = null;
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

  Future<void> createPost(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    if (!validateFields()) return;

    String? createdPostId;

    try {
      setLoading(true);

      final data = {
        "clientId": userProvider.user?.id,
        "title": tituloController.text,
        "specificCategoryIds": selectedCategories,
        "location": ubicacionController.text,
        "budget": parseBudget(presupuestoController.text),
        "deadline": fechaLimiteController.text,
        "description": descripcionController.text,
      };

      final id = await _service.createPost(data);
      createdPostId = id;
      
      if (localImages.isNotEmpty) {
        final urls = await _service.uploadImagesToFirebase(id!, localImages);
        if (urls.isNotEmpty) {
          await _service.updatePhotos(id, urls);
        }
      }

      clearForm();
      if (!context.mounted) return;

      final postsController = Provider.of<PostsController>(context, listen: false);
      await postsController.loadPosts();
      postsController.setSelectedIndex(0);
      postsController.highlightPost(createdPostId);
      postsController.requestHomeTab(0);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      // Si la publicación ya se había creado pero algo falló después (subir
      // o guardar las fotos), no debe quedar una publicación a medias.
      if (createdPostId != null) {
        try {
          await _service.deletePost(createdPostId);
        } catch (_) {}
      }
      final mensaje = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      setErrorMessage(mensaje);
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
