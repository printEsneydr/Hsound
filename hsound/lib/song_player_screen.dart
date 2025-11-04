import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hsound/share_service.dart';
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
  InAppWebViewController? webViewController;
  bool _isLoading = true;
  bool _showError = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _debugPlatformInfo();
  }

  void _debugPlatformInfo() {
    print('🎵 ═══════════════════════════════════════');
    print('🎵 HSOUND PLAYER DEBUG');
    print('🎵 ═══════════════════════════════════════');
    print('📱 Platform: ${widget.platform}');
    print('🔗 Original URL: ${widget.songUrl}');
    
    if (widget.platform == 'spotify') {
      final trackId = _extractSpotifyTrackId(widget.songUrl);
      final embedUrl = _getSpotifyEmbedUrl();
      print('🎵 Spotify Track ID: $trackId');
      print('🎵 Spotify Embed URL: $embedUrl');
    }
    
    print('🎵 ═══════════════════════════════════════\n');
  }

  String _getPlatformEmbedUrl() {
    switch (widget.platform) {
      case 'youtube':
        return _getYouTubeEmbedUrl();
      
      case 'spotify':
        return _getSpotifyEmbedUrl();
      
      case 'soundcloud':
        return _getSoundCloudEmbedUrl();
      
      case 'youtube_music':
        return _getYouTubeEmbedUrl();
      
      default:
        return widget.songUrl;
    }
  }

  // ✅ YOUTUBE - Versión móvil web
  String _getYouTubeEmbedUrl() {
    final videoId = _extractYouTubeVideoId(widget.songUrl);
    if (videoId.isNotEmpty) {
      return 'https://m.youtube.com/watch?v=$videoId';
    }
    return widget.songUrl;
  }

  // ✅ SPOTIFY - Embed con preview de 30 segundos
  String _getSpotifyEmbedUrl() {
    final trackId = _extractSpotifyTrackId(widget.songUrl);
    
    if (trackId.isEmpty) {
      print('❌ No se pudo extraer Spotify Track ID');
      return widget.songUrl;
    }

    final embedUrl = 'https://open.spotify.com/embed/track/$trackId?utm_source=generator&theme=0';
    
    print('✅ Spotify Embed generado: $embedUrl');
    return embedUrl;
  }

  String _getSoundCloudEmbedUrl() {
    final encodedUrl = Uri.encodeComponent(widget.songUrl);
    return 'https://w.soundcloud.com/player/?url=$encodedUrl&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true';
  }

  String _extractYouTubeVideoId(String url) {
    try {
      if (url.contains('youtu.be/')) {
        return url.split('youtu.be/').last.split('?').first.split('&').first;
      }
      
      if (url.contains('youtube.com/watch?v=')) {
        return url.split('v=').last.split('&').first;
      }
      
      if (url.contains('youtube.com/embed/')) {
        return url.split('embed/').last.split('?').first;
      }
      
      RegExp regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
        caseSensitive: false,
      );
      
      final match = regExp.firstMatch(url);
      if (match != null) {
        return match.group(1) ?? '';
      }
      
      return '';
    } catch (e) {
      print('❌ Error extrayendo YouTube ID: $e');
      return '';
    }
  }

  String _extractSpotifyTrackId(String url) {
    try {
      print('🔍 Extrayendo Spotify ID de: $url');
      
      String cleanUrl = url.split('?').first;
      print('🔍 URL limpia: $cleanUrl');
      
      // Remover /intl-XX/
      cleanUrl = cleanUrl.replaceAll(RegExp(r'/intl-[a-z]{2}/'), '/');
      print('🔍 URL sin intl: $cleanUrl');
      
      if (cleanUrl.contains('spotify.com/track/')) {
        final parts = cleanUrl.split('track/');
        if (parts.length > 1) {
          final trackId = parts[1]
              .split('/').first
              .split('?').first
              .split('#').first
              .trim();
          
          if (trackId.isNotEmpty && trackId.length > 10) {
            print('✅ Track ID extraído: $trackId');
            return trackId;
          }
        }
      }
      
      RegExp regExp = RegExp(r'spotify\.com\/(?:intl-[a-z]{2}\/)?(?:embed\/)?track\/([a-zA-Z0-9]{22})');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final trackId = match.group(1) ?? '';
        if (trackId.isNotEmpty) {
          print('✅ Track ID extraído (RegExp): $trackId');
          return trackId;
        }
      }
      
      print('❌ No se pudo extraer Track ID');
      return '';
    } catch (e) {
      print('❌ Error extrayendo Spotify ID: $e');
      return '';
    }
  }

  // ✅ ABRIR SPOTIFY CON DEEP LINK
  Future<void> _openSpotifyApp() async {
    try {
      final trackId = _extractSpotifyTrackId(widget.songUrl);
      
      if (trackId.isNotEmpty) {
        final spotifyUri = Uri.parse('spotify:track:$trackId');
        
        if (await canLaunchUrl(spotifyUri)) {
          await launchUrl(spotifyUri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      
      final webUrl = Uri.parse(widget.songUrl);
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return;
      }
      
      throw Exception('No se pudo abrir Spotify');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir Spotify: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openInNativeApp() async {
    if (widget.platform == 'spotify') {
      await _openSpotifyApp();
      return;
    }
    
    try {
      final Uri url = Uri.parse(widget.songUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir ${widget.songUrl}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir enlace: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareCurrentSong() async {
    try {
      await ShareService.shareSong(
        songTitle: widget.songTitle,
        artistName: widget.artistName,
        songUrl: widget.songUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _showError = false;
    });
    webViewController?.reload();
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
            icon: const Icon(Icons.share, color: Color(0xFF4ADE80)),
            onPressed: _shareCurrentSong,
            tooltip: 'Compartir canción',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Color(0xFF4ADE80)),
            onPressed: _openInNativeApp,
            tooltip: 'Abrir en app externa',
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
          _buildSongInfo(),
          
          // ✅ AVISO ESPECIAL PARA SPOTIFY
          if (widget.platform == 'spotify')
            _buildSpotifyNotice(),
          
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
            ),
          Expanded(
            child: _showError ? _buildErrorWidget() : _buildWebView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Column(
        children: [
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
            style: const TextStyle(
              color: Color(0xFF4ADE80),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ AVISO PARA SPOTIFY
  Widget _buildSpotifyNotice() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1DB954).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1DB954),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Preview de 30 segundos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            'Por políticas de Spotify, solo puedes escuchar un preview de 30 segundos aquí. Para la canción completa, usa el botón de abajo.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openSpotifyApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text(
                'Abrir canción completa en Spotify',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    final embedUrl = _getPlatformEmbedUrl();
    
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(embedUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            
            cacheEnabled: true,
            clearCache: false,
            
            supportZoom: true,
            builtInZoomControls: true,
            displayZoomControls: false,
            
            userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            
            useHybridComposition: true,
            transparentBackground: false,
            useShouldOverrideUrlLoading: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
            print('✅ WebView creado');
          },
          
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url.toString();
            
            if (url.startsWith('intent://') || 
                url.startsWith('spotify:') ||
                url.startsWith('market://')) {
              print('🚫 Bloqueado: $url');
              return NavigationActionPolicy.CANCEL;
            }
            
            return NavigationActionPolicy.ALLOW;
          },
          
          onLoadStart: (controller, url) {
            setState(() {
              _isLoading = true;
              _showError = false;
            });
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onLoadStop: (controller, url) async {
            setState(() {
              _isLoading = false;
            });
            
            if (widget.platform == 'spotify') {
              await controller.evaluateJavascript(source: '''
                var style = document.createElement('style');
                style.innerHTML = 'body { background: #1E1E1E !important; margin: 0; padding: 0; }';
                document.head.appendChild(style);
              ''');
            }
          },
          onReceivedError: (controller, request, error) {
            if (!error.description.contains('ERR_UNKNOWN_URL_SCHEME')) {
              setState(() {
                _isLoading = false;
                _showError = true;
              });
            }
          },
        ),

        if (_isLoading)
          Container(
            color: const Color(0xFF1E1E1E),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando ${_getPlatformName(widget.platform)}...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (_progress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(32),
      child: Center(
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
              _getErrorMessage(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            ElevatedButton.icon(
              onPressed: _retryLoading,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 12),
            
            TextButton.icon(
              onPressed: _openInNativeApp,
              icon: const Icon(Icons.open_in_new, color: Color(0xFF4ADE80)),
              label: const Text(
                'Abrir en app externa',
                style: TextStyle(color: Color(0xFF4ADE80)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    switch (widget.platform) {
      case 'spotify':
        return 'No se pudo cargar Spotify. Intenta abrir en la app oficial.';
      case 'youtube':
        return 'No se pudo cargar YouTube. Verifica tu conexión a internet.';
      default:
        return 'No se pudo cargar el contenido. Verifica tu conexión.';
    }
  }

  Widget _getPlatformIcon(String platform) {
    switch (platform) {
      case 'youtube':
        return const Text('🎥', style: TextStyle(fontSize: 20));
      case 'spotify':
        return const Text('🎵', style: TextStyle(fontSize: 20));
      case 'soundcloud':
        return const Text('☁️', style: TextStyle(fontSize: 20));
      case 'youtube_music':
        return const Text('🎶', style: TextStyle(fontSize: 20));
      default:
        return const Icon(Icons.music_note, color: Color(0xFF4ADE80), size: 24);
    }
  }

  String _getPlatformName(String platform) {
    switch (platform) {
      case 'youtube':
        return 'YouTube';
      case 'spotify':
        return 'Spotify';
      case 'soundcloud':
        return 'SoundCloud';
      case 'youtube_music':
        return 'YouTube Music';
      default:
        return 'Reproductor';
    }
  }
}