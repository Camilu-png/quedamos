import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCacheService {
  /// Descarga y guarda una imagen, retorna la ruta local
  Future<String?> cacheImage(String imageUrl, String userId) async {
    try {
      // Descargar la imagen
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        print('Failed to download image: ${response.statusCode}');
        return null;
      }

      // Obtener directorio de caché
      final cacheDir = await _getCacheDirectory();
      if (cacheDir == null) {
        print('[👾 image services] Failed to get cache directory');
        return null;
      }

      // Guardar la imagen
      final filePath = path.join(cacheDir.path, '$userId.jpg');
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      print('[👾 image services] Error caching image: $e');
      return null;
    }
  }

  /// Obtiene la ruta local de una imagen si existe
  String? getLocalImagePath(String userId) {
    try {
      // Nota: Este método es síncrono, pero necesitamos el directorio de caché
      // En la práctica, se usará después de que el directorio ya exista
      // o se verificará la existencia del archivo de forma asíncrona
      return null; // Implementación simplificada
    } catch (e) {
      print('[👾 image services] Error getting local image path: $e');
      return null;
    }
  }

  /// Elimina una imagen del caché
  Future<void> deleteImage(String userId) async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (cacheDir == null) return;

      final filePath = path.join(cacheDir.path, '$userId.jpg');
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('[👾 image services] Deleted cached image for user: $userId');
      }
    } catch (e) {
      print('[👾 image services] Error deleting image: $e');
    }
  }

  /// Limpia imágenes de usuarios que ya no están en la lista
  Future<void> cleanupOrphanedImages(List<String> activeUserIds) async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (cacheDir == null) return;

      // Listar todos los archivos en el directorio
      final files = cacheDir.listSync();

      for (final file in files) {
        if (file is File) {
          // Extraer el userId del nombre del archivo
          final fileName = path.basename(file.path);
          final userId = fileName.replaceAll('.jpg', '');

          // Si el userId no está en la lista de activos, eliminar
          if (!activeUserIds.contains(userId)) {
            await file.delete();
            print('[👾 image services] Deleted orphaned image: $fileName');
          }
        }
      }
    } catch (e) {
      print('[👾 image services] Error cleaning up orphaned images: $e');
    }
  }

  /// Obtiene o crea el directorio de caché para imágenes de perfil
  Future<Directory?> _getCacheDirectory() async {
    try {
      final appCacheDir = await getApplicationCacheDirectory();
      final profileImagesDir = Directory(path.join(appCacheDir.path, 'profile_images'));

      // Crear el directorio si no existe
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      return profileImagesDir;
    } catch (e) {
      print('[👾 image services] Error getting cache directory: $e');
      return null;
    }
  }
}
