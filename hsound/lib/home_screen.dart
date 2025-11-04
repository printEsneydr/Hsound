import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hsound/share_service.dart';
import 'package:hsound/firestore_service.dart';
import 'package:hsound/search_screen.dart';
import 'package:hsound/favorites_screen.dart'; 
import 'package:hsound/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedIndex = 0;
  String _displayName = 'Usuario'; // 🎯 CAMBIADO: Usar email como fallback

  final List<Widget> _pages = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayName(); // 🎯 CAMBIADO: Método más simple
    _initializePages();
  }

  void _initializePages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _pages.addAll([
          _buildHomeContent(),
          const SearchScreen(),
          const FavoritesScreen(),
          const ProfileScreen(),
        ]);
        _isInitialized = true;
      });
    });
  }

  // 🎯 **MÉTODO SUPER SIMPLE**: Email primero, nombre si está disponible rápido
  void _loadDisplayName() async {
    // 🎯 PRIMERO: Usar el email inmediatamente (siempre disponible)
    setState(() {
      _displayName = user?.email ?? 'Usuario';
    });

    // 🎯 SEGUNDO: Intentar cargar el nombre de Firestore en segundo plano
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get()
            .timeout(const Duration(seconds: 3)); // 🎯 Timeout de 3 segundos
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final name = userData['name']?.toString();
          
          // 🎯 Solo actualizar si el nombre es válido y diferente al email
          if (name != null && name.isNotEmpty && name != user?.email) {
            setState(() {
              _displayName = name;
            });
          }
        }
      } catch (e) {
        print('⚠️ No se pudo cargar nombre de Firestore: $e');
        // 🎯 No hacemos nada, mantenemos el email que ya está mostrando
      }
    }
  }

  // 🎯 Alertas mejoradas
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 HEADER SIMPLE - Nunca se queda cargando
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ADE80).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF1E1E1E),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido/a!',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayName, // 🎯 SIEMPRE tiene un valor (email o nombre)
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disfruta de la música',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contenido de canciones (se mantiene igual)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('songs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
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
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Canciones Recientes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Aún no hay canciones. ¡Sé el primero en subir una!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final songs = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Canciones Recientes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${songs.length} canciones disponibles',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final data = song.data() as Map<String, dynamic>;

                          return _buildSongItem(
                            songId: song.id,
                            title: data['title'] ?? 'Sin título',
                            artist: data['artistName'] ?? 'Artista desconocido',
                            platform: data['platform'] ?? 'youtube',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/song_player',
                                arguments: {
                                  'url': data['url'],
                                  'title': data['title'],
                                  'artist': data['artistName'],
                                  'platform': data['platform'],
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'HSOUND',
          style: TextStyle(
            color: Color(0xFF4ADE80),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: _isInitialized && _pages.isNotEmpty
          ? _pages[_selectedIndex]
          : const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: const Color(0xFF4ADE80),
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem({
    required String songId,
    required String title,
    required String artist,
    required String platform,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _getPlatformIcon(platform),
            ),
            const SizedBox(width: 16),
            
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
                    artist,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            StreamBuilder<bool>(
              stream: Stream.fromFuture(_firestoreService.isSongLiked(songId)),
              builder: (context, snapshot) {
                final isLiked = snapshot.data ?? false;
                
                return IconButton(
                  onPressed: () async {
                    try {
                      await _firestoreService.toggleLike(songId);
                      _showSuccessSnackBar(
                        isLiked 
                          ? '❌ Removido de favoritos' 
                          : '❤️ Agregado a favoritos'
                      );
                    } catch (e) {
                      _showErrorSnackBar('Error: $e');
                    }
                  },
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                );
              },
            ),
            
            IconButton(
              onPressed: () => _shareSong(title, artist),
              icon: const Icon(Icons.share, color: Color(0xFF4ADE80)),
            ),
          ],
        ),
      ),
    );
  }

  void _shareSong(String title, String artist) async {
    try {
      await ShareService.shareSong(
        songTitle: title,
        artistName: artist,
        songUrl: 'https://hsound-app.com/song/123',
      );
      _showSuccessSnackBar('📤 Canción compartida');
    } catch (e) {
      _showErrorSnackBar('Error al compartir: $e');
    }
  }

  Widget _getPlatformIcon(String platform) {
    switch (platform) {
      case 'youtube': return const Text('🎥', style: TextStyle(fontSize: 16));
      case 'spotify': return const Text('🎵', style: TextStyle(fontSize: 16));
      case 'soundcloud': return const Text('☁️', style: TextStyle(fontSize: 16));
      default: return const Icon(Icons.music_note, color: Color(0xFF4ADE80), size: 16);
    }
  }
}