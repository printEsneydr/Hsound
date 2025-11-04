import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos editables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _spotifyController = TextEditingController();
  final TextEditingController _soundcloudController = TextEditingController(); // 🎵 NUEVO
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isArtist = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Cargar datos existentes del usuario
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProfile = await _firestoreService.getUserProfile();
      if (userProfile.exists) {
        final data = userProfile.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _youtubeController.text = data['youtubeUrl'] ?? '';
          _spotifyController.text = data['spotifyUrl'] ?? '';
          _soundcloudController.text = data['soundcloudUrl'] ?? ''; // 🎵 NUEVO
          _instagramController.text = data['instagramUrl'] ?? '';
          _tiktokController.text = data['tiktokUrl'] ?? '';
          _whatsappController.text = data['whatsappUrl'] ?? '';
          _facebookController.text = data['facebookUrl'] ?? '';
          _emailController.text = data['contactEmail'] ?? '';
          _isArtist = data['isArtist'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      _showErrorSnackBar('Error al cargar perfil: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🎯 MEJORADO: SnackBar con mejor contraste
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF15803D), // Verde más oscuro
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

  // Guardar perfil - CORREGIDO
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 🎯 CORREGIDO: Usar updateUserProfile en lugar de saveUserProfile
        await _firestoreService.updateUserProfile({
          'name': _nameController.text,
          'bio': _bioController.text,
          'youtubeUrl': _youtubeController.text,
          'spotifyUrl': _spotifyController.text,
          'soundcloudUrl': _soundcloudController.text, // 🎵 NUEVO
          'instagramUrl': _instagramController.text,
          'tiktokUrl': _tiktokController.text,
          'whatsappUrl': _whatsappController.text,
          'facebookUrl': _facebookController.text,
          'contactEmail': _emailController.text,
          'isArtist': _isArtist,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _showSuccessSnackBar('✅ Perfil actualizado correctamente');
        
        Navigator.pop(context); // Volver atrás
      } catch (e) {
        print('Error saving profile: $e');
        _showErrorSnackBar('❌ Error al guardar: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Color(0xFF4ADE80)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF4ADE80)),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Información del estado de artista
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isArtist 
                              ? const Color(0xFF15803D).withOpacity(0.2) 
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isArtist 
                                ? const Color(0xFF4ADE80) 
                                : const Color(0xFF2D2D2D),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isArtist ? Icons.verified : Icons.person,
                              color: _isArtist ? const Color(0xFF4ADE80) : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isArtist ? 'Cuenta de Artista' : 'Cuenta de Usuario',
                                    style: TextStyle(
                                      color: _isArtist ? const Color(0xFF4ADE80) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _isArtist 
                                        ? 'Puedes agregar canciones y mostrar tus redes' 
                                        : 'Para convertirte en artista ve a tu perfil',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo nombre
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre',
                        hintText: 'Tu nombre o nombre artístico',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu nombre';
                          }
                          if (value.length < 2) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      // Campo biografía
                      _buildTextField(
                        controller: _bioController,
                        label: 'Biografía',
                        hintText: 'Cuéntanos sobre ti, tu música, inspiración...',
                        icon: Icons.description,
                        maxLines: 4,
                      ),
                      
                      // Solo para artistas: enlaces de música y redes
                      if (_isArtist) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader('🎵 Enlaces de Música'),
                        
                        _buildSocialTextField(
                          controller: _youtubeController,
                          label: 'YouTube',
                          hintText: 'https://youtube.com/@tucanal',
                          icon: Icons.video_library,
                          platform: 'youtube',
                        ),
                        
                        _buildSocialTextField(
                          controller: _spotifyController,
                          label: 'Spotify',
                          hintText: 'https://open.spotify.com/artist/tu-id',
                          icon: Icons.music_note,
                          platform: 'spotify',
                        ),

                        _buildSocialTextField(
                          controller: _soundcloudController,
                          label: 'SoundCloud',
                          hintText: 'https://soundcloud.com/tu-usuario',
                          icon: Icons.cloud,
                          platform: 'soundcloud',
                        ),

                        _buildSocialTextField(
                          controller: _tiktokController,
                          label: 'TikTok',
                          hintText: 'https://tiktok.com/@tu-usuario',
                          icon: Icons.video_camera_back,
                          platform: 'tiktok',
                        ),
                        
                        const SizedBox(height: 20),
                        _buildSectionHeader('📱 Redes Sociales'),
                        
                        _buildSocialTextField(
                          controller: _instagramController,
                          label: 'Instagram',
                          hintText: 'https://instagram.com/tu-usuario',
                          icon: Icons.camera_alt,
                          platform: 'instagram',
                        ),

                        _buildSocialTextField(
                          controller: _facebookController,
                          label: 'Facebook',
                          hintText: 'https://facebook.com/tu-pagina',
                          icon: Icons.facebook,
                          platform: 'facebook',
                        ),

                        const SizedBox(height: 20),
                        _buildSectionHeader('📞 Contacto/Booking'),
                        
                        _buildSocialTextField(
                          controller: _whatsappController,
                          label: 'WhatsApp',
                          hintText: 'https://wa.me/573001234567',
                          icon: Icons.phone,
                          platform: 'whatsapp',
                        ),

                        _buildSocialTextField(
                          controller: _emailController,
                          label: 'Email de Contacto',
                          hintText: 'artista@email.com',
                          icon: Icons.email,
                          platform: 'email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Ingresa un email válido';
                              }
                            }
                            return null;
                          },
                        ),
                      ],

                      // Botón de guardar
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ADE80),
                            foregroundColor: const Color(0xFF1E1E1E),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1E1E1E),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'GUARDAR CAMBIOS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF4ADE80)),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4ADE80)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF86EFAC)),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF4ADE80)),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
        validator: validator,
      ),
    );
  }

  // 🎯 NUEVO: Campo para redes sociales con validación opcional
  Widget _buildSocialTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String platform,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF4ADE80)),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2D2D2D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4ADE80)),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF4ADE80), size: 20),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _youtubeController.dispose();
    _spotifyController.dispose();
    _soundcloudController.dispose(); // 🎵 NUEVO
    _instagramController.dispose();
    _tiktokController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}