import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hsound/share_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser ;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navegar a diferentes pantallas según el índice
    switch (index) {
      case 0: // Inicio - ya estamos en home
        break;
      case 1: // Buscar}
        Navigator.pushNamed(context, '/search'); // IR A SEARCH SCREEN
        break;
      case 2: // Biblioteca
        // Navigator.pushNamed(context, '/library'); // Crearemos después
          _showComingSoon(context);
    
        break;
      case 3: // Perfil
        Navigator.pushNamed(context, '/profile'); // IR AL PERFIL
        break;
    }
  }
//Función para mostrar mensaje "próximamente"
void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('📚 Biblioteca - Próximamente'),
      backgroundColor: Color(0xFF4ADE80),
      duration: Duration(seconds: 2),
    ),
  );
  
  //Regresar al índice anterior después de mostrar el mensaje
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {
      _selectedIndex = 0; // Volver a Inicio
    });
  });
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
        actions: [
          //  BOTÓN DE LOGOUT EN EL APPBAR (esquina superior derecha)
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF4ADE80)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de bienvenida
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB0B0B0).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF4ADE80),
                    radius: 30,
                    child: Icon(
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
                          user?.email ?? 'Usuario',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Aquí se reemplaza la sección "Tus Playlists" y el GridView por el StreamBuilder de canciones recientes
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('songs')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4ADE80)));
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red));
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
                      Text(
                        'Aún no hay canciones. ¡Sé el primero en subir una!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }

                final songs = snapshot.data!.docs;

                return Expanded(
                  child: Column(
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
                  ),
                );
              },
            ),

            // Reproductor musical
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF4ADE80),
                        radius: 24,
                        child: Icon(
                          Icons.music_note,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Canción Actual',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Artista - Álbum',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType
              .fixed, //  esto ayuda a mantener estilo cuando hay más de 3 items
          backgroundColor: const Color(0xFF1E1E1E), //  fuerza el color oscuro
          selectedItemColor: const Color(0xFF4ADE80),
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Biblioteca'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPlaylistCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF4ADE80),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
          
          //Botón de compartir
          IconButton(
            onPressed: () => _shareSong(title, artist),
            icon: const Icon(Icons.share, color: Color(0xFF4ADE80)),
            tooltip: 'Compartir canción',
          ),
        ],
      ),
    ),
  );
}

//Función para compartir canción
void _shareSong(String title, String artist) async {
  try {
    // Aquí necesitarías obtener la URL real de la canción
    // Por ahora usaremos una URL genérica
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
}