import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // Auth
  static String get login => "$baseUrl/login";
  static String get resetPassword => "$baseUrl/resetPassword";
  // POST guarda el token FCM, DELETE lo elimina.
  static String get token => "$baseUrl/token";

  // Usuarios
  static String user([String? id]) =>
      id == null ? "$baseUrl/user" : "$baseUrl/user/$id";
  // Antes de enviar el SMS del registro: ¿cédula, correo y celular libres?
  static String get userAvailability => "$baseUrl/user/availability";
  // Irreversible: bloquea la cuenta y borra sus datos personales.
  static String deactivateUser(String id) => "$baseUrl/user/$id/deactivate";
  static String activateWorker(String id) => "$baseUrl/activateWorker/$id";
  static String get workerByUserId => "$baseUrl/workerByUserId";

  // Publicaciones
  static String get posts => "$baseUrl/posts";
  static String post([String? id]) =>
      id == null ? "$baseUrl/post" : "$baseUrl/post/$id";
  static String postsForWorker(String workerId) =>
      "$baseUrl/postsForWorker/$workerId";
  static String postsByUserId(String id) => "$baseUrl/postsByUserId/$id";

  // Categorías
  static String get generalCategories => "$baseUrl/generalCategories";
  static String generalCategory([String? id]) =>
      id == null ? "$baseUrl/generalCategory" : "$baseUrl/generalCategory/$id";

  static String get specificCategories => "$baseUrl/specificCategories";
  static String specificCategory([String? id]) => id == null
      ? "$baseUrl/specificCategory"
      : "$baseUrl/specificCategory/$id";

  static String get workerCategories => "$baseUrl/workerCategories";
  static String get workerCategory => "$baseUrl/workerCategory";

  // Ubicaciones
  static String get locations => "$baseUrl/locations";

  // Postulaciones y trabajos
  static String get apply => "$baseUrl/apply";
  static String get finishJob => "$baseUrl/finishJob";
  static String application(String id) => "$baseUrl/application/$id";
  static String applicationsByPostId(String id) =>
      "$baseUrl/applicationsByPostId/$id";
  static String applicationsByUserId(String id) =>
      "$baseUrl/applicationsByUserId/$id";

  // Notificaciones
  static String notificationsByUserId(String id) =>
      "$baseUrl/notificationsByUserId/$id";

  // Reportes
  static String get report => "$baseUrl/report";

  // Almacenamiento
  static String generateUploadUrl(String fileName, String contentType) =>
      "$baseUrl/generateUploadUrl?fileName=$fileName&contentType=$contentType";
}
