import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hsound/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isArtist = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userProfile = await _firestoreService.getUserProfile();
      if (userProfile.exists) {
        final data = userProfile.data() as Map<String, dynamic>;
        setState(() {
          _userData = data;
          _isArtist = data['isArtist'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ NUEVA: Función para eliminar canción
  Future<void> _deleteSong(String songId, String songTitle) async {
    // Diálogo de confirmación
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Eliminar Canción',
            style: TextStyle(color: Color(0xFF4ADE80)),
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar "$songTitle"?\n\nEsta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      try {
        await _firestoreService.deleteSong(songId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Canción "$songTitle" eliminada'),
            backgroundColor: const Color(0xFF4ADE80),
          ),
        );

        // Recargar la página para actualizar la lista
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NUEVA: Función para abrir enlaces sociales
  Future<void> _launchSocialUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir enlace: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Color(0xFF4ADE80)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4ADE80)),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de información del usuario
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          backgroundColor: const Color(0xFF4ADE80),
                          radius: 40,
                          child: user?.photoURL != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.photoURL!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Color(0xFF1E1E1E),
                                  size: 40,
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Nombre
                        Text(
                          _userData?['name'] ?? 'Usuario',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Email
                        Text(
                          user?.email ?? 'No email',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Badge de artista
                        if (_isArtist)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🎵 ARTISTA',
                              style: TextStyle(
                                color: Color(0xFF1E1E1E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Biografía
                        if (_userData?['bio'] != null &&
                            _userData!['bio'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _userData!['bio'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sección de enlaces sociales (solo para artistas)
                  if (_isArtist && _hasSocialLinks())
                    _buildSocialLinksSection(),

                  const SizedBox(height: 20),

                  // Solo para artistas: Sección de Mis Canciones
                  if (_isArtist) ...[
                    const Text(
                      '🎵 Mis Canciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getArtistSongs(user!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF4ADE80)),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.music_off,
                                    color: Colors.grey, size: 50),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aún no has subido canciones',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/add_song');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4ADE80),
                                    foregroundColor: const Color(0xFF1E1E1E),
                                  ),
                                  child: const Text('Subir Mi Primera Canción'),
                                ),
                              ],
                            ),
                          );
                        }

                        final songs = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final songDoc = songs[index];
                            final songData =
                                songDoc.data() as Map<String, dynamic>;

                            return _buildSongItem(
                              songId: songDoc.id,
                              title: songData['title'] ?? 'Sin título',
                              genre: songData['genre'] ?? 'General',
                              platform: songData['platform'] ?? 'youtube',
                              onDelete: () => _deleteSong(
                                  songDoc.id, songData['title'] ?? 'Canción'),
                            );
                          },
                        );
                      },
                    ),
                  ],

                  // Para usuarios normales: Botón para convertirse en artista
                  if (!_isArtist) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFF4ADE80),
                            size: 50,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '¿Eres artista?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Conviértete en artista para subir tu música y llegar a más personas',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/edit_profile');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ADE80),
                              foregroundColor: const Color(0xFF1E1E1E),
                            ),
                            child: const Text('Convertirme en Artista'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  //  BOTÓN AGREGAR CANCIÓN (solo para artistas)
                  if (_isArtist) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToAddSong,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF4ADE80),
                          foregroundColor: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text(
                          'Agregar Canción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // BOTÓN CERRAR SESIÓN (para todos)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutConfirmation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            const Color(0xFF4ADE80), // MISMO VERDE
                        foregroundColor:
                            const Color(0xFF1E1E1E), //  TEXTO OSCURO
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout,
                          color: Color(0xFF1E1E1E)), //  ICONO OSCURO
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E), //  TEXTO OSCURO
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  //  Verificar si tiene enlaces sociales
  bool _hasSocialLinks() {
    return (_userData?['youtubeUrl'] != null &&
            _userData!['youtubeUrl'].toString().isNotEmpty) ||
        (_userData?['spotifyUrl'] != null &&
            _userData!['spotifyUrl'].toString().isNotEmpty) ||
        (_userData?['instagramUrl'] != null &&
            _userData!['instagramUrl'].toString().isNotEmpty);
  }

  //  Sección de enlaces sociales
  // ✅ MEJORADA: Sección de enlaces sociales
  Widget _buildSocialLinksSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📱 Sígueme en:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Enlaces de música
          if (_userData?['youtubeUrl'] != null &&
              _userData!['youtubeUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.video_library,
              label: 'YouTube',
              url: _userData!['youtubeUrl'],
              color: Colors.red,
            ),

          if (_userData?['spotifyUrl'] != null &&
              _userData!['spotifyUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.music_note,
              label: 'Spotify',
              url: _userData!['spotifyUrl'],
              color: Color(0xFF1DB954), // Verde Spotify
            ),

          if (_userData?['tiktokUrl'] != null &&
              _userData!['tiktokUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.video_camera_back,
              label: 'TikTok',
              url: _userData!['tiktokUrl'],
              color: Color(0xFF000000), // Negro TikTok
            ),

          // Enlaces sociales
          if (_userData?['instagramUrl'] != null &&
              _userData!['instagramUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.camera_alt,
              label: 'Instagram',
              url: _userData!['instagramUrl'],
              color: Color(0xFFE4405F), // Rosa Instagram
            ),

          if (_userData?['facebookUrl'] != null &&
              _userData!['facebookUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.facebook,
              label: 'Facebook',
              url: _userData!['facebookUrl'],
              color: Color(0xFF1877F2), // Azul Facebook
            ),

          // Enlaces de contacto
          if (_userData?['whatsappUrl'] != null &&
              _userData!['whatsappUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.phone,
              label: 'WhatsApp',
              url: _userData!['whatsappUrl'],
              color: Color(0xFF25D366), // Verde WhatsApp
            ),

          if (_userData?['contactEmail'] != null &&
              _userData!['contactEmail'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.email,
              label: 'Email de Contacto',
              url: 'mailto:${_userData!['contactEmail']}',
              color: Color(0xFFEA4335), // Rojo Gmail
            ),
        ],
      ),
    );
  }

  //  Item de enlace social
  Widget _buildSocialLinkItem({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _launchSocialUrl(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar cada canción con botón de eliminar
  Widget _buildSongItem({
    required String songId,
    required String title,
    required String genre,
    required String platform,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  genre,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Botón de eliminar
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            tooltip: 'Eliminar canción',
          ),
        ],
      ),
    );
  }

  // Iconos por plataforma
  Widget _getPlatformIcon(String platform) {
    switch (platform) {
      case 'youtube':
        return const Text('🎥', style: TextStyle(fontSize: 16));
      case 'spotify':
        return const Text('🎵', style: TextStyle(fontSize: 16));
      case 'deezer':
        return const Text('🔊', style: TextStyle(fontSize: 16));
      case 'youtube_music':
        return const Text('🎶', style: TextStyle(fontSize: 16));
      case 'soundcloud':
        return const Text('☁️', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.music_note, color: Color(0xFF4ADE80), size: 16);
    }
  }

  // ✅ NUEVA: Función para mostrar modal de cerrar sesión
  Future<void> _showLogoutConfirmation() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(color: Color(0xFF4ADE80)),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: const Color(0xFF1E1E1E),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

// ✅ NUEVA: Función para navegar a agregar canción
  void _navigateToAddSong() {
    Navigator.pushNamed(context, '/add_song');
  }
}
