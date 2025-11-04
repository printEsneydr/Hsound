import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hsound/firestore_service.dart';
import 'package:hsound/share_service.dart';
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
      _showErrorSnackBar('Error al cargar perfil: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🎯 MEJORADO: SnackBars con mejor contraste
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ✅ Función para eliminar canción
  Future<void> _deleteSong(String songId, String songTitle) async {
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
        _showSuccessSnackBar('✅ Canción "$songTitle" eliminada');
        setState(() {});
      } catch (e) {
        _showErrorSnackBar('❌ Error al eliminar: $e');
      }
    }
  }

  // Función para abrir enlaces sociales
  Future<void> _launchSocialUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir $url');
      }
    } catch (e) {
      _showErrorSnackBar('Error al abrir enlace: $e');
    }
  }

  // Función para compartir perfil
  void _shareProfile() async {
    try {
      final String profileUrl = 'https://hsound-app.com/artist/${user!.uid}';
      final String artistName = _userData?['name'] ?? 'Artista';
      final String bio = _userData?['bio'] ?? '';
      
      await ShareService.shareArtistProfile(
        artistName: artistName,
        profileUrl: profileUrl,
        bio: bio,
      );
    } catch (e) {
      _showErrorSnackBar('Error al compartir perfil: $e');
    }
  }

  // 🎯 NUEVO: Función para contactar al equipo
  void _contactTeam() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            '🎵 ¿Quieres ser Artista en HSound?',
            style: TextStyle(color: Color(0xFF4ADE80), fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para garantizar la calidad de nuestro contenido, verificamos manualmente a todos los artistas que desean unirse a HSound.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '📋 Requisitos:',
                  style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildRequirementItem('• Ser artista activo en Pasto, Nariño'),
                _buildRequirementItem('• Tener música original publicada'),
                _buildRequirementItem('• Contar con redes sociales activas'),
                _buildRequirementItem('• Comprometerse con la comunidad musical'),
                const SizedBox(height: 16),
                const Text(
                  '📞 Contáctanos:',
                  style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildContactItem('📧 Email:', 'esneydribarra1970@gmail.com'),
                _buildContactItem('📱 WhatsApp:', '+57 323 2157962'),
                _buildContactItem('👨‍💻 Desarrollador:', 'Esneyder Ibarra'),
                const SizedBox(height: 8),
                const Text(
                  'Envíanos tu información y enlaces a tu música para revisar tu perfil.',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Entendido',
                style: TextStyle(color: Color(0xFF4ADE80)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchSocialUrl('mailto:esneydribarra1970@gmail.com?subject=Solicitud%20de%20Artista%20HSound&body=Hola,%20me%20interesa%20ser%20artista%20en%20HSound.%20Mi%20nombre%20es:%20%0A%0ARedes%20sociales:%20%0AMúsica%20publicada:%20%0A%0A¡Gracias!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: const Color(0xFF1E1E1E),
              ),
              child: const Text('Enviar Email'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _buildContactItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Color(0xFF4ADE80)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF4ADE80)),
            onPressed: _shareProfile,
            tooltip: 'Compartir perfil',
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4ADE80)),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de información del usuario
                  _buildUserInfoCard(),
                  const SizedBox(height: 20),

                  // Sección de enlaces sociales (solo para artistas)
                  if (_isArtist && _hasSocialLinks())
                    _buildSocialLinksSection(),

                  const SizedBox(height: 20),

                  // Solo para artistas: Sección de Mis Canciones
                  if (_isArtist) 
                    _buildArtistSongsSection(),

                  // 🎯 MODIFICADO: Para usuarios normales - Sección de contacto
                  if (!_isArtist) 
                    _buildContactSection(),

                  // BOTÓN AGREGAR CANCIÓN (solo para artistas)
                  if (_isArtist) 
                    _buildAddSongButton(),

                  const SizedBox(height: 20),

                  // BOTÓN CERRAR SESIÓN
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
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
          Text(
            _userData?['name'] ?? 'Usuario',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? 'No email',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_isArtist)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🎵 ARTISTA VERIFICADO',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_userData?['bio'] != null && _userData!['bio'].toString().isNotEmpty)
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
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user,
            color: Color(0xFF4ADE80),
            size: 50,
          ),
          const SizedBox(height: 12),
          const Text(
            '🎵 ¿Eres artista de Pasto?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Únete a HSound y comparte tu música con la comunidad',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Verificamos manualmente a cada artista para mantener la calidad de nuestro contenido musical.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _contactTeam,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Solicitar Verificación'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _launchSocialUrl('https://wa.me/573232157962?text=Hola,%20me%20interesa%20ser%20artista%20en%20HSound');
            },
            child: const Text(
              'O contactar por WhatsApp',
              style: TextStyle(color: Color(0xFF4ADE80)),
            ),
          ),
        ],
      ),
    );
  }

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
              color: Color(0xFF1DB954),
            ),

          if (_userData?['soundcloudUrl'] != null &&
              _userData!['soundcloudUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.cloud,
              label: 'SoundCloud',
              url: _userData!['soundcloudUrl'],
              color: Color(0xFFFF7700),
            ),

          if (_userData?['tiktokUrl'] != null &&
              _userData!['tiktokUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.video_camera_back,
              label: 'TikTok',
              url: _userData!['tiktokUrl'],
              color: Color(0xFF000000),
            ),

          // Enlaces sociales
          if (_userData?['instagramUrl'] != null &&
              _userData!['instagramUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.camera_alt,
              label: 'Instagram',
              url: _userData!['instagramUrl'],
              color: Color(0xFFE4405F),
            ),

          if (_userData?['facebookUrl'] != null &&
              _userData!['facebookUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.facebook,
              label: 'Facebook',
              url: _userData!['facebookUrl'],
              color: Color(0xFF1877F2),
            ),

          // Enlaces de contacto
          if (_userData?['whatsappUrl'] != null &&
              _userData!['whatsappUrl'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.phone,
              label: 'WhatsApp',
              url: _userData!['whatsappUrl'],
              color: Color(0xFF25D366),
            ),

          if (_userData?['contactEmail'] != null &&
              _userData!['contactEmail'].toString().isNotEmpty)
            _buildSocialLinkItem(
              icon: Icons.email,
              label: 'Email de Contacto',
              url: 'mailto:${_userData!['contactEmail']}',
              color: Color(0xFFEA4335),
            ),
        ],
      ),
    );
  }

  Widget _buildArtistSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
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
                    const Icon(Icons.music_off, color: Colors.grey, size: 50),
                    const SizedBox(height: 12),
                    const Text(
                      'Aún no has subido canciones',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _navigateToAddSong,
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
                final songData = songDoc.data() as Map<String, dynamic>;

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
    );
  }

  Widget _buildAddSongButton() {
    return SizedBox(
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
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showLogoutConfirmation,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF4ADE80),
          foregroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, color: Color(0xFF1E1E1E)),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
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
        (_userData?['soundcloudUrl'] != null &&
            _userData!['soundcloudUrl'].toString().isNotEmpty) ||
        (_userData?['instagramUrl'] != null &&
            _userData!['instagramUrl'].toString().isNotEmpty);
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
      case 'soundcloud':
        return const Text('☁️', style: TextStyle(fontSize: 16));
      case 'youtube_music':
        return const Text('🎶', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.music_note, color: Color(0xFF4ADE80), size: 16);
    }
  }

  // Función para mostrar modal de cerrar sesión
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

  // Función para navegar a agregar canción
  void _navigateToAddSong() {
    Navigator.pushNamed(context, '/add_song');
  }
}