import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SongPlayerScreen extends StatefulWidget {
  final String songUrl;
  final String songTitle;
  final String artistName;
  final String platform;

  const SongPlayerScreen({
    super.key,
    required this.songUrl,
    required this.songTitle,
    required this.artistName,
    required this.platform,
  });

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E1E))
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          setState(() {
            _loadingProgress = progress / 100;
          });
        },
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
            _showError = false;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
        },
        onWebResourceError: (WebResourceError error) {
          setState(() {
            _isLoading = false;
            _showError = true;
          });
        },
        onNavigationRequest: (NavigationRequest request) {
          // Permitir navegación a YouTube/Spotify
          if (request.url.contains('youtube.com') || 
              request.url.contains('youtu.be') ||
              request.url.contains('spotify.com') ||
              request.url.contains('deezer.com')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(_getPlatformUrl(widget.songUrl)));
  }

  // MEJORADA: Función para adaptar la URL según la plataforma
  String _getPlatformUrl(String originalUrl) {
    switch (widget.platform) {
      case 'youtube':
        return _convertYouTubeUrl(originalUrl);
      
      case 'spotify':
        // Spotify no funciona en WebView, abrir directamente
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openInNativeApp();
        });
        return 'about:blank';
      
      case 'deezer':
        // Deezer tampoco funciona bien en WebView
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openInNativeApp();
        });
        return 'about:blank';
      
      default:
        return originalUrl;
    }
  }

  // NUEVA: Función mejorada para convertir URLs de YouTube
  String _convertYouTubeUrl(String originalUrl) {
    try {
      String videoId = '';
      
      // Formato 1: youtu.be/ID
      if (originalUrl.contains('youtu.be/')) {
        videoId = originalUrl.split('youtu.be/').last.split('?').first;
      }
      // Formato 2: youtube.com/watch?v=ID
      else if (originalUrl.contains('youtube.com/watch?v=')) {
        videoId = originalUrl.split('v=').last.split('&').first;
      }
      // Formato 3: youtube.com/embed/ID (ya está bien)
      else if (originalUrl.contains('youtube.com/embed/')) {
        return originalUrl;
      }
      // Formato 4: URL directa con parámetros
      else {
        final uri = Uri.parse(originalUrl);
        videoId = uri.queryParameters['v'] ?? '';
      }
      
      if (videoId.isNotEmpty) {
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1';
      }
      
      return originalUrl;
    } catch (e) {
      return originalUrl;
    }
  }

  // Función para abrir en la app nativa
  Future<void> _openInNativeApp() async {
    try {
      final Uri url = Uri.parse(widget.songUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir ${widget.songUrl}');
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

  // Función para intentar cargar de nuevo
  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _showError = false;
    });
    controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Reproduciendo',
          style: TextStyle(
            color: Color(0xFF4ADE80),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4ADE80)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Color(0xFF4ADE80)),
            onPressed: _openInNativeApp,
            tooltip: 'Abrir en app nativa',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4ADE80)),
            onPressed: _retryLoading,
            tooltip: 'Reintentar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de la canción
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Icono de plataforma
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: _getPlatformIcon(widget.platform),
                ),
                const SizedBox(height: 16),
                
                Text(
                  widget.songTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                Text(
                  widget.artistName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                
                Text(
                  _getPlatformName(widget.platform),
                  style: TextStyle(
                    color: const Color(0xFF4ADE80),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // WebView, Loading o Error
          Expanded(
            child: _showError
                ? _buildErrorWidget()
                : Stack(
                    children: [
                      WebViewWidget(controller: controller),
                      
                      // Loading overlay
                      if (_isLoading)
                        Container(
                          color: const Color(0xFF1E1E1E),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Cargando reproductor...',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_loadingProgress > 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: LinearProgressIndicator(
                                    value: _loadingProgress,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar error
  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 20),
          const Text(
            'Error al cargar el reproductor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Puedes intentar abrir la canción en la app nativa',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _retryLoading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  foregroundColor: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _openInNativeApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir en App'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Iconos por plataforma
  Widget _getPlatformIcon(String platform) {
    switch (platform) {
      case 'youtube':
        return const Text('🎥', style: TextStyle(fontSize: 20));
      case 'spotify':
        return const Text('🎵', style: TextStyle(fontSize: 20));
      case 'deezer':
        return const Text('🔊', style: TextStyle(fontSize: 20));
      case 'youtube_music':
        return const Text('🎶', style: TextStyle(fontSize: 20));
      case 'soundcloud':
        return const Text('☁️', style: TextStyle(fontSize: 20));
      default:
        return const Icon(Icons.music_note, color: Color(0xFF4ADE80), size: 24);
    }
  }

  // Nombres de plataforma
  String _getPlatformName(String platform) {
    switch (platform) {
      case 'youtube':
        return 'YouTube';
      case 'spotify':
        return 'Spotify';
      case 'deezer':
        return 'Deezer';
      case 'youtube_music':
        return 'YouTube Music';
      case 'soundcloud':
        return 'SoundCloud';
      default:
        return 'Plataforma externa';
    }
  }
}