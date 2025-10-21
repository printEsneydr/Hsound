import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hsound/firestore_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedGenre = 'Todos';
  String _sortBy = 'title';
  bool _searchingSongs = true;
  
  final List<String> _genres = [
    'Todos',
    'Rock', 'Pop', 'Hip Hop/Rap', 'Electrónica', 'Reggaetón',
    'Salsa', 'Merengue', 'Vallenato', 'Bachata', 'Jazz',
    'Blues', 'Clásica', 'Reggae', 'Metal', 'Indie',
    'Folk', 'R&B', 'Country', 'Alternativo', 'Otro'
  ];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final genres = await _firestoreService.getAvailableGenres();
    setState(() {
      _genres
        ..clear()
        ..add('Todos')
        ..addAll(genres);
    });
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Buscar',
          style: TextStyle(color: Color(0xFF4ADE80)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: _searchQuery.isEmpty 
                ? _buildEmptyState()
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar canciones, artistas...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4ADE80)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4ADE80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF86EFAC)),
                ),
                filled: true,
                fillColor: const Color(0xFF2D2D2D),
              ),
              onChanged: (value) => _performSearch(),
              onSubmitted: (value) => _performSearch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(_searchingSongs ? '🎵 Canciones' : '👤 Artistas'),
            selected: true,
            onSelected: (selected) {
              setState(() {
                _searchingSongs = selected;
              });
            },
            backgroundColor: const Color(0xFF2D2D2D),
            selectedColor: const Color(0xFF4ADE80),
            labelStyle: TextStyle(
              color: _searchingSongs ? const Color(0xFF1E1E1E) : Colors.white,
            ),
          ),
          
          const SizedBox(width: 12),
          
          if (_searchingSongs) ...[
            DropdownButton<String>(
              value: _selectedGenre,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _genres.map((genre) {
                return DropdownMenuItem(
                  value: genre,
                  child: Text(genre),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGenre = value!;
                });
              },
            ),
            
            const SizedBox(width: 12),
            
            DropdownButton<String>(
              value: _sortBy,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: const [
                DropdownMenuItem(value: 'title', child: Text('Título')),
                DropdownMenuItem(value: 'popularity', child: Text('Popular')),
                DropdownMenuItem(value: 'date', child: Text('Reciente')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 80),
          const SizedBox(height: 20),
          Text(
            'Busca tu música favorita',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Encuentra canciones y artistas de Pasto',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return _searchingSongs ? _buildSongResults() : _buildArtistResults();
  }

  Widget _buildSongResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.searchSongs(
        query: _searchQuery,
        genre: _selectedGenre == 'Todos' ? null : _selectedGenre,
        sortBy: _sortBy,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)));
        }

        if (snapshot.hasError) {
          return _buildErrorWithRetry(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoResults();
        }

        final songs = snapshot.data!.docs;
        return _buildSongList(songs);
      },
    );
  }

  // ✅ FUNCIÓN FALTANTE: Lista de canciones
  Widget _buildSongList(List<QueryDocumentSnapshot> songs) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final songDoc = songs[index];
        final songData = songDoc.data() as Map<String, dynamic>;
        
        return _buildSongItem(
          songId: songDoc.id,
          title: songData['title'] ?? 'Sin título',
          artist: songData['artistName'] ?? 'Artista desconocido',
          genre: songData['genre'] ?? 'General',
          platform: songData['platform'] ?? 'youtube',
          likes: songData['likes'] ?? 0,
          songUrl: songData['url'] ?? '', // ✅ URL REAL
        );
      },
    );
  }

  // ✅ FUNCIÓN FALTANTE: Error con reintento
  Widget _buildErrorWithRetry(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.orange, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Búsqueda limitada temporalmente',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Usando búsqueda básica',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: const Color(0xFF1E1E1E),
            ),
            child: const Text('Reintentar Búsqueda'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.searchArtists(query: _searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)));
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoResults();
        }

        final artists = snapshot.data!.docs;
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artistDoc = artists[index];
            final artistData = artistDoc.data() as Map<String, dynamic>;
            
            return _buildArtistItem(
              artistId: artistDoc.id,
              name: artistData['name'] ?? 'Artista',
              bio: artistData['bio'],
              photoUrl: artistData['photoUrl'],
            );
          },
        );
      },
    );
  }

  Widget _buildSongItem({
    required String songId,
    required String title,
    required String artist,
    required String genre,
    required String platform,
    required int likes,
    required String songUrl,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _getPlatformIcon(platform),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '$artist • $genre',
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          Text(
            likes.toString(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      onTap: () {
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
    );
  }

  Widget _buildArtistItem({
    required String artistId,
    required String name,
    required String? bio,
    required String? photoUrl,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF4ADE80),
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null 
            ? const Icon(Icons.person, color: Color(0xFF1E1E1E))
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        bio ?? 'Artista de H Sound',
        style: const TextStyle(color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil de $name')),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, color: Colors.grey, size: 60),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos o filtros',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _clearSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: const Color(0xFF1E1E1E),
            ),
            child: const Text('Limpiar búsqueda'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            'Error en la búsqueda',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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