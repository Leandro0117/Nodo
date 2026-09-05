import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nodo/core/constants/api_constants.dart';
// import 'package:nodo/shared/providers/user_provider.dart';
import 'package:nodo/shared/providers/register_provider.dart';

import 'package:provider/provider.dart';

class RegisterController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 🔹 Método para registrar usuario
  Future<void> registerUser({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController lastName1Controller,
    required TextEditingController lastName2Controller,
    required TextEditingController idController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required String? selectedUserType,
    required VoidCallback onContinue,
    required TextEditingController phoneController,
    required TextEditingController dateController,
    required TextEditingController locationController,
    required List<String> selectedCategories,
    required TextEditingController descriptionController,
    required TextEditingController emailController,
  }) async {
    if (!formKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      final dni = idController.text.trim();
      final firstName = nameController.text.trim();
      final lastName = lastName1Controller.text.trim();
      final secondLastName = lastName2Controller.text.trim();
      final birthDate = dateController.text.trim();
      final password = passwordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();
      final phone = phoneController.text.trim();
      final isWorker = selectedUserType == "trabajador";
      final location = isWorker && locationController.text.trim().isNotEmpty
          ? locationController.text.trim()
          : null;

      final description = isWorker && descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null;

      final categories = selectedCategories;
      final email = emailController.text.trim();

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden.')),
        );
        _setLoading(false);
        return;
      }

      final registerProvider = Provider.of<RegisterProvider>(context, listen: false);

      final url = Uri.parse(ApiConstants.user());

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "dni": dni,
          "firstName": firstName,
          "lastName": lastName,
          "secondLastName": secondLastName,
          "email": email,
          "phone": phone,
          "birthDate": birthDate,
          "password": password,
          "isWorker": isWorker,
          "location": location,
          "description": description,
        }),
      );

      if (!context.mounted) return;
      if (response.statusCode == 200) {
        debugPrint("✅ Usuario agregado: ${response.body}");
        final body = jsonDecode(response.body);
        final id = body['user']['id'] as String;
        registerProvider.setRegisterData(id: id, email: email, password: password);
        if (isWorker && categories.isNotEmpty) {
          await _createWorkerCategory(id, categories);
        }
        onContinue();
      } else {
        debugPrint("❌ Error al registrar: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyRegisterError(response)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No pudimos conectar con el servidor. Verifica tu conexión e inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  String _friendlyRegisterError(http.Response response) {
    switch (response.statusCode) {
      case 409:
        return 'Ya existe una cuenta con esa cédula, correo o teléfono.';
      case 400:
        return 'Revisa los datos del formulario: hay campos inválidos o incompletos.';
      default:
        return 'No pudimos completar el registro. Intenta de nuevo en unos minutos.';
    }
  }

  /// 🔹 Función privada para registrar las categorías del trabajador
  Future<void> _createWorkerCategory(
      String workerId, List<String> generalCategoryIds) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.workerCategory),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "workerId": workerId,
          "generalCategoryIds": generalCategoryIds,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Worker-Categories registradas:");
      } else {
        debugPrint("⚠️ Error registrando worker-category: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error en conexión al registrar categorías: $e");
    }
  }
}
