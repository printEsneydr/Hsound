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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Guardar perfil
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _firestoreService.saveUserProfile({
          'name': _nameController.text,
          'bio': _bioController.text,
          'youtubeUrl': _youtubeController.text,
          'spotifyUrl': _spotifyController.text,
          'instagramUrl': _instagramController.text,
          'tiktokUrl': _tiktokController.text,
          'whatsappUrl': _whatsappController.text,
          'facebookUrl': _facebookController.text,
          'contactEmail': _emailController.text,
          'isArtist': _isArtist,
          'photoUrl': FirebaseAuth.instance.currentUser?.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Color(0xFF4ADE80),
          ),
        );
        
        Navigator.pop(context); // Volver atrás
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            onPressed: _saveProfile,
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
                      // Switch para artista/usuario
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Soy Artista',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Switch(
                              value: _isArtist,
                              onChanged: (value) {
                                setState(() {
                                  _isArtist = value;
                                });
                              },
                              activeColor: const Color(0xFF4ADE80),
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
                          return null;
                        },
                      ),
                      
                      // Campo biografía
                      _buildTextField(
                        controller: _bioController,
                        label: 'Biografía',
                        hintText: 'Cuéntanos sobre ti...',
                        icon: Icons.description,
                        maxLines: 4,
                      ),
                      
                      // Solo para artistas: enlaces de música y redes
                      if (_isArtist) ...[
                        const SizedBox(height: 20),
                        const Text(
                          '🎵 Enlaces de Música',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        _buildTextField(
                          controller: _youtubeController,
                          label: 'YouTube',
                          hintText: 'https://youtube.com/tu-canal',
                          icon: Icons.video_library,
                        ),
                        
                        _buildTextField(
                          controller: _spotifyController,
                          label: 'Spotify',
                          hintText: 'https://spotify.com/tu-artista',
                          icon: Icons.music_note,
                        ),

                        _buildTextField(
                          controller: _tiktokController,
                          label: 'TikTok',
                          hintText: 'https://tiktok.com/@tu-usuario',
                          icon: Icons.video_camera_back,
                        ),
                        
                        const SizedBox(height: 20),
                        const Text(
                          '📱 Redes Sociales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildTextField(
                          controller: _instagramController,
                          label: 'Instagram',
                          hintText: 'https://instagram.com/tu-usuario',
                          icon: Icons.camera_alt,
                        ),

                        _buildTextField(
                          controller: _facebookController,
                          label: 'Facebook',
                          hintText: 'https://facebook.com/tu-pagina',
                          icon: Icons.facebook,
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          '📞 Contacto/Booking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildTextField(
                          controller: _whatsappController,
                          label: 'WhatsApp',
                          hintText: 'https://wa.me/573001234567',
                          icon: Icons.phone,
                        ),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email de Contacto',
                          hintText: 'artista@email.com',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ],
                  ),
                ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _youtubeController.dispose();
    _spotifyController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}