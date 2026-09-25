import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  /// Converts the HTTP base URL to its WebSocket equivalent.
  /// e.g. http://10.0.2.2:3001/api → ws://10.0.2.2:3001
  static String get _wsBase => baseUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://')
      .replaceAll(RegExp(r'/api/?$'), '');

  static String chatWsUrl(String conversationId) =>
      '$_wsBase/chat?conversationId=$conversationId';

  static String get login => "$baseUrl/login";
  static String get createUser => "$baseUrl/createUser";
  static String updateUser(String id) => "$baseUrl/updateUser/$id";
  static String getUser(String id) => "$baseUrl/getUser/$id";
  static String activateWorker(String id) => "$baseUrl/activateWorker/$id";
  static String get getWorkerByUserId => "$baseUrl/getWorkerByUserId";

  static String get createPost => "$baseUrl/createPost";
  static String get getPosts => "$baseUrl/getPosts";
  static String getPostsForWorker(String workerId) => "$baseUrl/getPostsForWorker/$workerId";
  static String getPostsByUserId(String id) => "$baseUrl/getPostsByUserId/$id";
  static String updatePost(String id) => "$baseUrl/updatePost/$id";
  static String deletePost(String id) => "$baseUrl/deletePost/$id";

  static String get getGeneralCategories => "$baseUrl/getGeneralCategories";
  static String getGeneralCategory(String id) => "$baseUrl/getGeneralCategory/$id";
  static String get createGeneralCategory => "$baseUrl/createGeneralCategory";

  static String get getSpecificCategories => "$baseUrl/getSpecificCategories";
  static String getSpecificCategory(String id) => "$baseUrl/getSpecificCategory/$id";
  static String get createSpecificCategory => "$baseUrl/createSpecificCategory";

  static String get getWorkerCategories => "$baseUrl/getWorkerCategories";
  static String get createWorkerCategory => "$baseUrl/createWorkerCategory";

  static String get getLocations => "$baseUrl/getLocations";

  static String get apply => "$baseUrl/apply";
  static String get finishJob => "$baseUrl/finishJob";
  static String getApplicationsByPostId(String id) =>
      "$baseUrl/getApplicationsByPostId/$id";
  static String getApplicationsByUserId(String id) =>
      "$baseUrl/getApplicationsByUserId/$id";
  static String updateApplication(String id) =>
      "$baseUrl/updateApplication/$id";
  static String deleteApplication(String id) =>
      "$baseUrl/deleteApplication/$id";

  static String getNotificationsByUserId(String id) =>
      "$baseUrl/getNotificationsByUserId/$id";
  static String get saveToken => "$baseUrl/saveToken";
  static String get deleteToken => "$baseUrl/deleteToken";

  static String get resetPassword => "$baseUrl/resetPassword";

  static String getOrCreateConversation(String applicationId) =>
      "$baseUrl/getOrCreateConversation/$applicationId";
  static String getMessages(String conversationId) =>
      "$baseUrl/getMessages/$conversationId";
  static String get sendMessage => "$baseUrl/sendMessage";

  static String get createReport => "$baseUrl/createReport";

  static String get createRating => "$baseUrl/createRating";
  static String getUserRatings(String userId) => "$baseUrl/getUserRatings/$userId";
  static String getRatingByServiceAndUser(String serviceId, String userId) =>
      "$baseUrl/getRatingByServiceAndUser/$serviceId/$userId";

  static String generateUploadUrl(String fileName, String contentType) =>
      "$baseUrl/generateUploadUrl?fileName=$fileName&contentType=$contentType";
}
