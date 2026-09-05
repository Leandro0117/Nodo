import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/constants/api_constants.dart';
import 'package:nodo/core/theme/app_theme.dart';

class CategoryFilterDetailScreen extends StatefulWidget {
  final List<String> initialSelected;
  const CategoryFilterDetailScreen({super.key, this.initialSelected = const []});

  @override
  State<CategoryFilterDetailScreen> createState() =>
      _CategoryFilterDetailScreenState();
}

class _CategoryFilterDetailScreenState
    extends State<CategoryFilterDetailScreen> {
  List<Map<String, dynamic>> categorias = [];
  Set<String> categoriasSeleccionadas = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    categoriasSeleccionadas = Set.from(widget.initialSelected);
    _fetchCategorias();
  }

  Future<void> _fetchCategorias() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.specificCategories),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categorias = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar categorías: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  bool get todoSeleccionado =>
      categorias.isNotEmpty &&
      categoriasSeleccionadas.length == categorias.length;

  void toggleTodo(bool? val) => setState(() {
        if (val == true) {
          categoriasSeleccionadas =
              Set.from(categorias.map((c) => c['id'].toString()));
        } else {
          categoriasSeleccionadas.clear();
        }
      });

  void toggleCategoria(String id, bool? val) => setState(() {
        if (val == true) {
          categoriasSeleccionadas.add(id);
        } else {
          categoriasSeleccionadas.remove(id);
        }
      });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Text('Tipo de trabajo',
                      style: AppTypography.title
                          .copyWith(color: AppColors.blue)),
                  SizedBox(height: 12.h),
                  if (_isLoading)
                    const Expanded(
                        child: Center(child: CircularProgressIndicator()))
                  else if (_errorMessage.isNotEmpty)
                    Expanded(
                        child: Center(
                            child: Text(_errorMessage,
                                style: AppTypography.body.copyWith(
                                    color: AppColors.slateGrey))))
                  else ...[
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.orange,
                      title: Text('Todas',
                          style: AppTypography.body
                              .copyWith(color: AppColors.blue)),
                      value: todoSeleccionado,
                      onChanged: toggleTodo,
                    ),
                    Divider(
                        height: 1,
                        color: AppColors.slateGrey.withValues(alpha: 0.15)),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: categorias.length,
                        itemBuilder: (_, i) {
                          final cat = categorias[i];
                          final id = cat['id'].toString();
                          return CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.orange,
                            title: Text(cat['name'],
                                style: AppTypography.body
                                    .copyWith(color: AppColors.blue)),
                            value: categoriasSeleccionadas.contains(id),
                            onChanged: (val) => toggleCategoria(id, val),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(
                            context, categoriasSeleccionadas.toList()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          categoriasSeleccionadas.isEmpty
                              ? 'Aceptar'
                              : 'Aplicar (${categoriasSeleccionadas.length})',
                          style:
                              AppTypography.label.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
