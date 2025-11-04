import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String platform; // 'youtube', 'spotify', 'deezer', etc.
  final String url;
  final String genre;
  final String? description;
  final int duration; // en segundos
  final DateTime createdAt;
  final int likes;
  final int plays;
  final List<String> searchKeywords; // Lista de palabras clave para búsqueda
  final bool isLiked; //CAMPO PARA ESTADO DE LIKE


  Song({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.platform,
    required this.url,
    required this.genre,
    this.description,
    required this.duration,
    required this.createdAt,
    this.likes = 0,
    this.plays = 0,
    required this.searchKeywords, // inicializar en el constructor
    this.isLiked = false, // Valor por defecto


  });

  // Convertir de Firestore a objeto Song
  factory Song.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? 'Sin título',
      artistId: data['artistId'] ?? '',
      artistName: data['artistName'] ?? 'Artista desconocido',
      platform: data['platform'] ?? 'youtube',
      url: data['url'] ?? '',
      genre: data['genre'] ?? 'General',
      description: data['description'],
      duration: data['duration'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      plays: data['plays'] ?? 0,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []), // manejar null
      isLiked: false, // Se actualizará después
    );
  }

  // Convertir objeto Song a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artistId': artistId,
      'artistName': artistName,
      'platform': platform,
      'url': url,
      'genre': genre,
      'description': description,
      'duration': duration,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': likes,
      'plays': plays,
      'searchKeywords': searchKeywords, // incluir en el Map
    };
  }
    // ✅ NUEVO: Método para actualizar el estado de like
  Song copyWith({bool? isLiked}) {
    return Song(
      id: id,
      title: title,
      artistId: artistId,
      artistName: artistName,
      platform: platform,
      url: url,
      genre: genre,
      description: description,
      duration: duration,
      createdAt: createdAt,
      likes: likes,
      plays: plays,
      searchKeywords: searchKeywords,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
