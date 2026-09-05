import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/location.dart';
import '../constants/api_constants.dart';

class LocationService {
  Future<List<Location>> obtenerUbicaciones() async {
    final response = await http.get(Uri.parse(ApiConstants.locations));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Location.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las ubicaciones');
    }
  }
}
