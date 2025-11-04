import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hsound/firestore_service.dart';
import 'package:hsound/artist_profile_screen.dart';

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
  'Rock', 'Pop', 'Hip Hop/Rap', "Trap", 'Electrónica', 'Reggaetón',
  'Salsa', 'Merengue', 'Vallenato', 'Bachata', 'Jazz',
  'Blues', 'Clásica', 'Reggae', 'Metal', 'Indie',
  'Folk', 'R&B', 'Country', 'Alternativo', 'Otro'
];

  @override
  void initState() {
    super.initState();
    //_loadGenres();
  }

  //Future<void> _loadGenres() async {
    //final genres = await _firestoreService.getAvailableGenres();
    //setState(() {
      //_genres
        //..clear()
        //..add('Todos')
        //..addAll(genres);
   // });
 // }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedGenre = 'Todos';
    });
  }

  // 🎯 CORREGIDO: Navegación al perfil de artista
  void _navigateToArtistProfile(String artistId, String artistName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistProfileScreen(artistId: artistId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            // 🎯 NUEVO: Filtros horizontales de géneros para canciones
            if (_searchingSongs) _buildGenreFilter(),
            Expanded(
              child: _searchQuery.isEmpty 
                  ? _buildEmptyState()
                  : _buildResults(),
            ),
          ],
        ),
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
                hintText: _searchingSongs 
                    ? 'Buscar canciones...' 
                    : 'Buscar artistas...',
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
          // Toggle Canciones/Artistas
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Botón Canciones
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchingSongs = true;
                      _clearSearch();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _searchingSongs 
                          ? const Color(0xFF4ADE80) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: _searchingSongs 
                              ? const Color(0xFF1E1E1E) 
                              : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Canciones',
                          style: TextStyle(
                            color: _searchingSongs 
                                ? const Color(0xFF1E1E1E) 
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón Artistas
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchingSongs = false;
                      _clearSearch();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_searchingSongs 
                          ? const Color(0xFF4ADE80) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: !_searchingSongs 
                              ? const Color(0xFF1E1E1E) 
                              : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Artistas',
                          style: TextStyle(
                            color: !_searchingSongs 
                                ? const Color(0xFF1E1E1E) 
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Filtros adicionales solo para canciones
          if (_searchingSongs) ...[
            // Dropdown de ordenamiento
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4ADE80)),
              ),
              child: DropdownButton<String>(
                value: _sortBy,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4ADE80)),
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
            ),
          ],
        ],
      ),
    );
  }

  // 🎯 NUEVO: Filtros horizontales de géneros
  Widget _buildGenreFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Géneros:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final isSelected = genre == _selectedGenre;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      genre,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF1E1E1E) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    backgroundColor: const Color(0xFF2D2D2D),
                    selectedColor: const Color(0xFF4ADE80),
                    onSelected: (selected) {
                      setState(() {
                        _selectedGenre = genre;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchingSongs ? Icons.search : Icons.person_search,
            color: Colors.grey,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            _searchingSongs 
                ? 'Busca tus canciones favoritas' 
                : 'Busca artistas locales',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Encuentra música y artistas de Pasto',
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
          songUrl: songData['url'] ?? '',
        );
      },
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
      onTap: () => _navigateToArtistProfile(artistId, name), // 🎯 AHORA SÍ FUNCIONA
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchingSongs ? Icons.music_off : Icons.person_off,
            color: Colors.grey,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _searchingSongs 
                ? 'No se encontraron canciones' 
                : 'No se encontraron artistas',
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
      case 'soundcloud':
        return const Text('☁️', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.music_note, color: Color(0xFF4ADE80), size: 16);
    }
  }
}