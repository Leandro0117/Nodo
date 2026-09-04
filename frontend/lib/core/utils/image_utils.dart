import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  /// Comprime bytes de imagen a formato WebP.
  /// Usa compressWithList (basado en bytes) en vez de compressAndGetFile
  /// (basado en rutas de archivo), ya que este último no está soportado en Flutter Web.
  static Future<Uint8List> convertToWebPBytes(Uint8List bytes) async {
    return FlutterImageCompress.compressWithList(
      bytes,
      quality: 80,
      format: CompressFormat.webp,
    );
  }
}
