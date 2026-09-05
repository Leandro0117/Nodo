import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/categorie.dart';
import '../constants/api_constants.dart';

class CategorieService {
  Future<List<Categorie>> obtenerCategorias() async {
    debugPrint('Obteniendo categorías desde el servicio...');
    final response = await http.get(Uri.parse(ApiConstants.specificCategories));
    //debugPrint('Respuesta recibida: ${response}');
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Categorie.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las categorías');
    }
  }
}
