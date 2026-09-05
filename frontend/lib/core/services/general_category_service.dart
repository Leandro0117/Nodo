import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/categorie.dart';
import '../constants/api_constants.dart';

class GeneralCategoryService {
  Future<List<Categorie>> obtenerCategorias() async {
    debugPrint('Obteniendo categorías generales desde el servicio...');
    final response = await http
        .get(Uri.parse(ApiConstants.generalCategories))
        .timeout(const Duration(seconds: 3));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Categorie.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las categorías generales');
    }
  }
}
