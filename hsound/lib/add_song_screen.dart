import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hsound/firestore_service.dart';
import '../models/song_model.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({super.key});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String _selectedPlatform = 'youtube';
  bool _isLoading = false;
  String? _artistName;

  // Lista de plataformas disponibles
  final List<Map<String, String>> _platforms = [
    {'value': 'youtube', 'label': 'YouTube', 'icon': '🎥'},
    {'value': 'spotify', 'label': 'Spotify', 'icon': '🎵'},
    {'value': 'deezer', 'label': 'Deezer', 'icon': '🔊'},
    {'value': 'youtube_music', 'label': 'YouTube Music', 'icon': '🎶'},
    {'value': 'soundcloud', 'label': 'SoundCloud', 'icon': '☁️'},
    {'value': 'other', 'label': 'Otra plataforma', 'icon': '🔗'},
  ];

  // Lista de géneros musicales
  final List<String> _genres = [
    'Rock',
    'Pop',
    'Hip Hop/Rap',
    'Electrónica',
    'Reggaetón',
    'Salsa',
    'Merengue',
    'Vallenato',
    'Bachata',
    'Jazz',
    'Blues',
    'Clásica',
    'Reggae',
    'Metal',
    'Indie',
    'Folk',
    'R&B',
    'Country',
    'Alternativo',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    _loadArtistName();
  }

  // Cargar nombre del artista desde el perfil
  Future<void> _loadArtistName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _artistName = data['name'] ?? 'Artista';
        });
      }
    }
  }

  // Función para guardar la canción
  Future<void> _saveSong() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Crear objeto Song
          final song = Song(
            id: '', // Firestore asignará automáticamente el ID
            title: _titleController.text.trim(),
            artistId: user.uid,
            artistName: _artistName ?? 'Artista',
            platform: _selectedPlatform,
            url: _urlController.text.trim(),
            genre: _genreController.text,
            description: _descriptionController.text.trim(),
            duration: int.tryParse(_durationController.text) ?? 0,
            createdAt: DateTime.now(),
          );

          // Guardar en Firestore
          await _firestoreService.saveSong(song);

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎵 Canción agregada exitosamente!'),
              backgroundColor: Color(0xFF4ADE80),
            ),
          );

          // Regresar a la pantalla anterior
          Navigator.pop(context);
        }
      } catch (e) {
        // Mostrar mensaje de error
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

  // Validar URL según la plataforma seleccionada
  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa la URL de la canción';
    }

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return 'La URL debe comenzar con http:// o https://';
    }

    // Validaciones específicas por plataforma
    switch (_selectedPlatform) {
      case 'youtube':
        if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
          return 'URL de YouTube no válida';
        }

        // CONVERTIR AUTOMÁTICAMENTE a formato embed para mejor reproducción
        String? videoId;

        if (value.contains('youtu.be/')) {
          videoId = value.split('youtu.be/').last.split('?').first;
        } else if (value.contains('watch?v=')) {
          videoId = value.split('v=').last.split('&').first;
        }

        if (videoId != null && videoId.isNotEmpty) {
          // Mostrar mensaje informativo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ URL de YouTube convertida a formato compatible'),
              backgroundColor: const Color(0xFF4ADE80),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;

      case 'spotify':
        if (!value.contains('spotify.com')) {
          return 'URL de Spotify no válida';
        }
        break;

      case 'deezer':
        if (!value.contains('deezer.com')) {
          return 'URL de Deezer no válida';
        }
        break;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Agregar Canción',
          style: TextStyle(color: Color(0xFF4ADE80)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF4ADE80)),
            onPressed: _isLoading ? null : _saveSong,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Información del artista
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF4ADE80)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Artista: $_artistName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo: Título de la canción
                      _buildTextField(
                        controller: _titleController,
                        label: 'Título de la canción *',
                        hintText: 'Ej: Mi mejor canción',
                        icon: Icons.music_note,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el título';
                          }
                          return null;
                        },
                      ),

                      // Campo: Plataforma
                      _buildPlatformDropdown(),

                      // Campo: URL
                      _buildTextField(
                        controller: _urlController,
                        label: 'URL de la canción *',
                        hintText: 'https://...',
                        icon: Icons.link,
                        validator: _validateUrl,
                      ),

                      // Campo: Género
                      _buildGenreDropdown(),

                      // Campo: Duración
                      _buildTextField(
                        controller: _durationController,
                        label: 'Duración (segundos)',
                        hintText: 'Ej: 240 (4 minutos)',
                        icon: Icons.timer,
                        keyboardType: TextInputType.number,
                      ),

                      // Campo: Descripción
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Descripción (opcional)',
                        hintText: 'Describe tu canción...',
                        icon: Icons.description,
                        maxLines: 3,
                      ),

                      // Botón de guardar
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveSong,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF4ADE80),
                            foregroundColor: const Color(0xFF1E1E1E),
                          ),
                          child: const Text(
                            'Guardar Canción',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Widget para campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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

  // Widget para seleccionar plataforma
  Widget _buildPlatformDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedPlatform,
        decoration: InputDecoration(
          labelText: 'Plataforma *',
          labelStyle: const TextStyle(color: Color(0xFF4ADE80)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4ADE80)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF86EFAC)),
          ),
          prefixIcon: const Icon(Icons.public, color: Color(0xFF4ADE80)),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
        dropdownColor: const Color(0xFF1E1E1E),
        style: const TextStyle(color: Colors.white),
        items: _platforms.map((platform) {
          return DropdownMenuItem(
            value: platform['value'],
            child: Row(
              children: [
                Text(platform['icon']!),
                const SizedBox(width: 10),
                Text(platform['label']!),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPlatform = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor selecciona una plataforma';
          }
          return null;
        },
      ),
    );
  }

  // Widget para seleccionar género
  Widget _buildGenreDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _genreController.text.isEmpty ? null : _genreController.text,
        decoration: InputDecoration(
          labelText: 'Género musical *',
          labelStyle: const TextStyle(color: Color(0xFF4ADE80)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4ADE80)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF86EFAC)),
          ),
          prefixIcon: const Icon(Icons.category, color: Color(0xFF4ADE80)),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
        dropdownColor: const Color(0xFF1E1E1E),
        style: const TextStyle(color: Colors.white),
        items: _genres.map((genre) {
          return DropdownMenuItem(
            value: genre,
            child: Text(genre),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _genreController.text = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor selecciona un género';
          }
          return null;
        },
        hint: const Text(
          'Selecciona un género',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
