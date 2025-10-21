import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Guardar perfil de usuario
  Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));
    }
  }
  
  // Obtener perfil de usuario
  Future<DocumentSnapshot> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    return await _firestore.collection('users').doc(user!.uid).get();
  }
  
  // Obtener perfil de usuario como Stream (para updates en tiempo real)
  Stream<DocumentSnapshot> getUserProfileStream() {
    final user = FirebaseAuth.instance.currentUser;
    return _firestore.collection('users').doc(user!.uid).snapshots();
  }
  
  // ✅ ACTUALIZADA: Guardar canción usando el modelo Song
  Future<void> saveSong(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('songs').add(song.toFirestore());
    }
  }
  
  // Obtener canciones del artista
  Stream<QuerySnapshot> getArtistSongs(String artistId) {
    return _firestore
        .collection('songs')
        .where('artistId', isEqualTo: artistId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Obtener todas las canciones (para explorar)
  Stream<QuerySnapshot> getAllSongs() {
    return _firestore
        .collection('songs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtener canciones por género
  Stream<QuerySnapshot> getSongsByGenre(String genre) {
    return _firestore
        .collection('songs')
        .where('genre', isEqualTo: genre)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Eliminar canción
  Future<void> deleteSong(String songId) async {
    try {
      await _firestore.collection('songs').doc(songId).delete();
      print('Canción $songId eliminada exitosamente');
    } catch (e) {
      print('Error al eliminar canción: $e');
      throw e;
    }
  }

  // ✅ CORREGIDA: Búsqueda avanzada de canciones (VERSIÓN CON MANEJO DE ERRORES)
  Stream<QuerySnapshot> searchSongs({
    required String query,
    String? genre,
    String? sortBy, // 'popularity', 'date', 'title'
    int limit = 20,
  }) {
    try {
      Query searchQuery = _firestore.collection('songs');

      // Búsqueda por texto
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        searchQuery = searchQuery
            .where('searchKeywords', arrayContains: lowerQuery);
      }

      // Filtro por género
      if (genre != null && genre.isNotEmpty && genre != 'Todos') {
        searchQuery = searchQuery.where('genre', isEqualTo: genre);
      }

      // Ordenamiento
      switch (sortBy) {
        case 'popularity':
          searchQuery = searchQuery.orderBy('likes', descending: true);
          break;
        case 'date':
          searchQuery = searchQuery.orderBy('createdAt', descending: true);
          break;
        case 'title':
        default:
          searchQuery = searchQuery.orderBy('title', descending: false);
          break;
      }

      return searchQuery.limit(limit).snapshots();
      
    } catch (e) {
      // ✅ Usar búsqueda básica y filtrar en memoria
      print('Índice no encontrado, usando búsqueda en memoria: $e');
      return _fallbackSearch(query: query, genre: genre, sortBy: sortBy, limit: limit);
    }
  }

  //  BÚSQUEDA DE RESPUESTA CUANDO FALTAN ÍNDICES
Stream<QuerySnapshot> _fallbackSearch({
  required String query,
  String? genre,
  String? sortBy,
  int limit = 20,
}) {
  // Simplemente devolvemos una búsqueda básica que SÍ funciona
  Query searchQuery = _firestore.collection('songs');
  
  // Solo búsqueda por texto (sin filtros complejos)
  if (query.isNotEmpty) {
    final lowerQuery = query.toLowerCase();
    searchQuery = searchQuery
        .where('searchKeywords', arrayContains: lowerQuery)
        .orderBy('title') // Ordenamiento simple que SÍ funciona
        .limit(limit);
  } else {
    searchQuery = searchQuery
        .orderBy('title')
        .limit(limit);
  }
  
  return searchQuery.snapshots();
}

  // Búsqueda de artistas
  Stream<QuerySnapshot> searchArtists({
    required String query,
    int limit = 10,
  }) {
    if (query.isEmpty) {
      return _firestore
          .collection('users')
          .where('isArtist', isEqualTo: true)
          .limit(limit)
          .snapshots();
    }

    return _firestore
        .collection('users')
        .where('isArtist', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .orderBy('name')
        .limit(limit)
        .snapshots();
  }

  // Obtener géneros únicos para filtros
  Future<List<String>> getAvailableGenres() async {
    final snapshot = await _firestore
        .collection('songs')
        .orderBy('genre')
        .get();

    final genres = snapshot.docs
        .map((doc) => doc['genre'] as String? ?? 'General')
        .toSet()
        .toList();

    return genres..sort();
  }

  // Función para crear keywords de búsqueda
  List<String> createSearchKeywords(String text) {
    if (text.isEmpty) return [];
    
    final words = text.toLowerCase().split(' ');
    final keywords = <String>[];
    
    for (final word in words) {
      if (word.trim().isNotEmpty) {
        // Agregar la palabra completa
        keywords.add(word.trim());
        
        // Agregar substrings para búsqueda parcial (solo palabras de 3+ caracteres)
        if (word.trim().length > 2) {
          for (int i = 1; i <= word.trim().length; i++) {
            final substring = word.trim().substring(0, i);
            if (substring.length >= 2) { // Solo substrings de 2+ caracteres
              keywords.add(substring);
            }
          }
        }
      }
    }
    
    // Agregar el texto completo en minúsculas
    keywords.add(text.toLowerCase().trim());
    
    return keywords.toSet().toList(); // Remover duplicados
  }

  // ✅ NUEVA: Función para actualizar canciones existentes con searchKeywords
  Future<void> updateSongsWithSearchKeywords() async {
    try {
      final snapshot = await _firestore.collection('songs').get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final artistName = data['artistName'] as String? ?? '';
        
        // Crear keywords combinando título y artista
        final searchKeywords = createSearchKeywords('$title $artistName');
        
        // Actualizar el documento
        await _firestore.collection('songs').doc(doc.id).update({
          'searchKeywords': searchKeywords,
        });
        
        print('✅ Canción ${doc.id} actualizada con keywords');
      }
    } catch (e) {
      print('Error actualizando keywords: $e');
    }
  }
}