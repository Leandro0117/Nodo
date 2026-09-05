import 'package:flutter/material.dart';
import 'package:nodo/core/constants/api_constants.dart';
import 'package:nodo/features/trabajos/screens/thanks_screen.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nodo/core/theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  final String jobId; // UUID como String

  const ReportScreen({super.key, required this.jobId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? selectedOption;

  final List<Map<String, String>> motivos = [
    {
      'titulo': 'Contenido inapropiado',
      'descripcion':
          'Contiene lenguaje ofensivo, violencia, discriminación o imágenes no adecuadas.'
    },
    {
      'titulo': 'Información falsa o engañosa',
      'descripcion':
          'Los datos proporcionados no son correctos o pueden confundir a los usuarios.'
    },
    {
      'titulo': 'Spam o publicidad',
      'descripcion':
          'Esta publicación parece ser un anuncio o promociona algo o no parece requerir un servicio real'
    },
    {
      'titulo': 'Producto o servicio ilegal',
      'descripcion':
          'Se vende o promociona algo que no está permitido en la plataforma'
    },
    {
      'titulo': 'Estafa o fraude',
      'descripcion':
          'Sospecha de engaño, cobro indebido o intento de estafa.'
    },
    {
      'titulo': 'Derechos de autor',
      'descripcion':
          'Utiliza contenido (imágenes, textos, marcas) sin autorización del propietario.'
    },
    {
      'titulo': 'Otro (especificar)',
      'descripcion': 'Explica el motivo en el campo de comentarios.'
    },
  ];

  Future<void> enviarReporte() async {
    if (selectedOption == null || selectedOption!.isEmpty) return;

    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    if (userId == null) return;

    final url = Uri.parse(ApiConstants.report);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postId': widget.jobId,
          'userId': userId,
          'reason': selectedOption,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ThanksScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reportar: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Reportar',
          style: AppTypography.title,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Color(0xFF003366),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Por qué quieres reportar esta publicación?',
              style: AppTypography.body.copyWith(
                color: const Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ayúdanos a mantener la plataforma segura eligiendo el motivo del reporte.',
              style: AppTypography.label
                  .copyWith(color: const Color.fromARGB(255, 16, 57, 98)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: motivos.length,
                itemBuilder: (context, index) {
                  final titulo = motivos[index]['titulo']!;
                  final descripcion = motivos[index]['descripcion']!;
                  return CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.orange,
                    title: Text(
                      titulo,
                      style: AppTypography.label.copyWith(
                        color: const Color(0xFF003366),
                      ),
                    ),
                    subtitle: Text(
                      descripcion,
                      style: AppTypography.label
                          .copyWith(color: Colors.grey.shade600),
                    ),
                    value: selectedOption == titulo,
                    onChanged: (_) {
                      setState(() {
                        selectedOption = titulo;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: selectedOption != null ? enviarReporte : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedOption != null ? Colors.orange[300] : Colors.grey[300],
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                'Reportar',
                style: AppTypography.body,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Botón solo se habilita cuando se selecciona una opción',
                style: AppTypography.label.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}