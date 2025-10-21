import 'dart:ui';
import 'package:share_plus/share_plus.dart';

class ShareService {
  
  // ✅ Compartir canción
  static Future<void> shareSong({
    required String songTitle,
    required String artistName,
    required String songUrl,
    String? platform,
  }) async {
    try {
      final String text = '🎵 Escucha "$songTitle" por $artistName en H Sound!\n$songUrl';
      final String subject = '$songTitle - $artistName';
      
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: Rect.zero,
      );
    } catch (e) {
      throw Exception('Error al compartir canción: $e');
    }
  }

  // ✅ Compartir perfil de artista
  static Future<void> shareArtistProfile({
    required String artistName,
    required String profileUrl,
    String? bio,
  }) async {
    try {
      final String bioText = bio != null ? '\n$bio' : '';
      final String text = '👤 Conoce a $artistName en H Sound!$bioText\n$profileUrl';
      final String subject = 'Perfil de $artistName';
      
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: Rect.zero,
      );
    } catch (e) {
      throw Exception('Error al compartir perfil: $e');
    }
  }

  // ✅ Compartir texto personalizado
  static Future<void> shareText({
    required String text,
    required String subject,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: Rect.zero,
      );
    } catch (e) {
      throw Exception('Error al compartir: $e');
    }
  }
}