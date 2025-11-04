import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hsound/firestore_service.dart';
import 'package:hsound/models/song_model.dart';
import 'package:hsound/share_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;

  void _shareSong(String title, String artist) async {
    try {
      final String songUrl = 'https://hsound-app.com/song/123'; // URL temporal
      await ShareService.shareSong(
        songTitle: title,
        artistName: artist,
        songUrl: songUrl,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _getPlatformIcon(String platform) {
    switch (platform) {
      case 'youtube':
        return const Text('🎥', style: TextStyle(fontSize: 16));
      case 'spotify':
        return const Text('🎵', style: TextStyle(fontSize: 16));
      case 'deezer':
        return const Text('🔊', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.music_note, color: Color(0xFF4ADE80), size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(color: Color(0xFF4ADE80)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    color: Colors.grey,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aún no tienes favoritos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Toca el corazón en las canciones que te gusten',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Volver al home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: const Color(0xFF1E1E1E),
                    ),
                    child: const Text('Explorar Canciones'),
                  ),
                ],
              ),
            );
          }

          final songs = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final songDoc = songs[index];
                final data = songDoc.data() as Map<String, dynamic>;

                return _buildFavoriteSongItem(
                  songId: songDoc.id,
                  title: data['title'] ?? 'Sin título',
                  artist: data['artistName'] ?? 'Artista desconocido',
                  genre: data['genre'] ?? 'General',
                  platform: data['platform'] ?? 'youtube',
                  likes: data['likes'] ?? 0,
                  songUrl: data['url'] ?? '',
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteSongItem({
    required String songId,
    required String title,
    required String artist,
    required String genre,
    required String platform,
    required int likes,
    required String songUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de plataforma
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _getPlatformIcon(platform),
          ),
          const SizedBox(width: 16),
          
          // Información de la canción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$artist • $genre',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$likes likes',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de like (ya está en favoritos, mostrar lleno)
              StreamBuilder<bool>(
                stream: Stream.fromFuture(_firestoreService.isSongLiked(songId)),
                builder: (context, snapshot) {
                  final isLiked = snapshot.data ?? true;
                  
                  return IconButton(
                    onPressed: () async {
                      await _firestoreService.toggleLike(songId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Removido de favoritos'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    tooltip: 'Quitar de favoritos',
                  );
                },
              ),
              
              // Botón de compartir
              IconButton(
                onPressed: () => _shareSong(title, artist),
                icon: const Icon(Icons.share, color: Color(0xFF4ADE80)),
                tooltip: 'Compartir canción',
              ),
              
              // Botón de reproducir
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/song_player',
                    arguments: {
                      'url': songUrl,
                      'title': title,
                      'artist': artist,
                      'platform': platform,
                    },
                  );
                },
                icon: const Icon(Icons.play_arrow, color: Color(0xFF4ADE80)),
                tooltip: 'Reproducir canción',
              ),
            ],
          ),
        ],
      ),
    );
  }
}