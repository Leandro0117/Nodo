import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:nodo/core/constants/api_constants.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/core/utils/debug_log.dart';
import 'package:nodo/shared/providers/register_provider.dart';

/// Registro en dos pasos:
/// 1. [prepareRegistration] valida el formulario, confirma con el backend que
///    la cédula, el correo y el celular estén libres, y guarda los datos.
/// 2. [createAccount] crea la cuenta cuando el celular ya fue verificado por
///    SMS. Así nunca existen cuentas con un celular sin confirmar.
class RegisterController extends ChangeNotifier {
  static const _connectionError =
      'No pudimos conectar con el servidor. Verifica tu conexión e inténtalo de nuevo.';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _pendingUser;
  List<String> _pendingCategories = const [];

  /// Celular pendiente de verificar (10 dígitos), para el paso del código.
  String? get pendingPhone => _pendingUser?['phone'] as String?;

  /// Recorta la respuesta del backend para que el log sea legible.
  String _resumen(http.Response r) {
    final body = r.body.length > 300 ? '${r.body.substring(0, 300)}…' : r.body;
    return '${r.statusCode} · $body';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Paso 1: valida, revisa que los datos no estén en uso y avanza al código.
  Future<void> prepareRegistration({
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
    logPaso('Paso 1', 'Preparando el registro');
    if (!formKey.currentState!.validate()) {
      logPaso('Paso 1', '✗ El formulario no pasó la validación');
      return;
    }

    final password = passwordController.text.trim();
    if (password != confirmPasswordController.text.trim()) {
      logPaso('Paso 1', '✗ Las contraseñas no coinciden');
      _showError(context, 'Las contraseñas no coinciden.');
      return;
    }

    final isWorker = selectedUserType == "trabajador";
    final location = locationController.text.trim();
    final description = descriptionController.text.trim();

    final user = <String, dynamic>{
      "dni": idController.text.trim(),
      "firstName": nameController.text.trim(),
      "lastName": lastName1Controller.text.trim(),
      "secondLastName": lastName2Controller.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "birthDate": dateController.text.trim(),
      "password": password,
      "isWorker": isWorker,
      "location": isWorker && location.isNotEmpty ? location : null,
      "description": isWorker && description.isNotEmpty ? description : null,
    };

    _setLoading(true);
    try {
      logPaso('Paso 1', 'API configurada: ${ApiConstants.baseUrl}');
      logPaso('Paso 1', 'Consultando disponibilidad → POST ${ApiConstants.userAvailability} '
          '· celular ${enmascarar(user["phone"] as String)} · correo ${user["email"]} · '
          'cédula ${user["dni"]}');
      // Antes de gastar un SMS, confirmar que el registro no va a chocar
      // con una cuenta existente.
      final response = await http.post(
        Uri.parse(ApiConstants.userAvailability),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": user["email"],
          "phone": user["phone"],
          "dni": user["dni"],
        }),
      );
      logPaso('Paso 1', 'Respuesta de checkAvailability: ${_resumen(response)}');
      if (!context.mounted) {
        logPaso('Paso 1', '✗ La pantalla se cerró antes de recibir la respuesta');
        return;
      }

      if (response.statusCode == 200) {
        _pendingUser = user;
        _pendingCategories = List.of(selectedCategories);
        logPaso('Paso 1', '✓ Datos libres. Avanzando a la verificación del celular');
        onContinue();
      } else {
        if (response.statusCode == 404) {
          logPaso('Paso 1', '✗ 404: el backend no tiene /user/availability. '
              '¿Aplicaste el parche en el backend y lo reiniciaste?');
        }
        logPaso('Paso 1', '✗ Se muestra: "${_friendlyRegisterError(response)}"');
        _showError(context, _friendlyRegisterError(response));
      }
    } catch (e, stack) {
      logPaso('Paso 1', '✗ Excepción (sin respuesta del backend): $e');
      logPaso('Paso 1', 'Revisa que el backend esté corriendo y que API_BASE_URL apunte a él');
      debugPrint('$stack');
      if (context.mounted) _showError(context, _connectionError);
    } finally {
      _setLoading(false);
    }
  }

  /// Paso 2: crea la cuenta con el token que prueba que el celular es del usuario.
  Future<bool> createAccount(
    BuildContext context, {
    required String phoneIdToken,
  }) async {
    final user = _pendingUser;
    if (user == null) {
      logPaso('Paso 2 · cuenta', '✗ No hay datos pendientes del formulario (_pendingUser es null)');
      _showError(context, 'Se perdieron los datos del registro. Vuelve a empezar.');
      return false;
    }
    logPaso('Paso 2 · cuenta', 'Creando la cuenta → POST ${ApiConstants.user()} '
        '· token ${enmascarar(phoneIdToken, visibles: 6)}');

    final registerProvider = context.read<RegisterProvider>();
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.user()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({...user, "phoneIdToken": phoneIdToken}),
      );
      logPaso('Paso 2 · cuenta', 'Respuesta de createUser: ${_resumen(response)}');
      if (!context.mounted) return false;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final id = body['user']['id'] as String;
        registerProvider.setRegisterData(
          id: id,
          email: user["email"] as String,
          password: user["password"] as String,
        );
        logPaso('Paso 2 · cuenta', '✓ Cuenta creada con id $id');
        if (user["isWorker"] == true && _pendingCategories.isNotEmpty) {
          logPaso('Paso 2 · cuenta', 'Asignando ${_pendingCategories.length} rubro(s) al trabajador');
          await _createWorkerCategory(id, _pendingCategories);
        }
        _pendingUser = null;
        _pendingCategories = const [];
        return true;
      }

      if (response.statusCode == 401) {
        logPaso('Paso 2 · cuenta', '✗ 401: el backend rechazó el token. Compara el proyecto de '
            'Firebase de la app (log "SMS") con el del backend (log "[firebase]")');
      }
      logPaso('Paso 2 · cuenta', '✗ Se muestra: "${_friendlyRegisterError(response)}"');
      _showError(context, _friendlyRegisterError(response));
      return false;
    } catch (e, stack) {
      logPaso('Paso 2 · cuenta', '✗ Excepción (sin respuesta del backend): $e');
      debugPrint('$stack');
      if (context.mounted) _showError(context, _connectionError);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _friendlyRegisterError(http.Response response) {
    switch (response.statusCode) {
      case 409:
        return 'Ya existe una cuenta con esa cédula, correo o teléfono.';
      case 401:
        return 'No pudimos confirmar tu número. Pide un código nuevo e inténtalo otra vez.';
      case 400:
        return 'Revisa los datos del formulario: hay campos inválidos o incompletos.';
      default:
        return 'No pudimos completar el registro. Intenta de nuevo en unos minutos.';
    }
  }

  /// Registra los rubros del trabajador.
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

      logPaso('Paso 2 · cuenta', 'Respuesta de createWorkerCategory: ${_resumen(response)}');
    } catch (e) {
      logPaso('Paso 2 · cuenta', '✗ Excepción al asignar rubros: $e');
    }
  }
}
