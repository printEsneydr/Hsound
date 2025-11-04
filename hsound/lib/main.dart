import 'package:flutter/material.dart';  // Flutter UI
import 'package:firebase_core/firebase_core.dart'; // Inicialización de Firebase
import 'package:hsound/add_song_screen.dart'; // Importa la pantalla para agregar canciones
import 'package:hsound/edit_profile_screen.dart'; // Importa la pantalla de edición de perfil
import 'package:hsound/favorites_screen.dart';
import 'package:hsound/firestore_service.dart';
import 'package:hsound/song_player_screen.dart'; // Importa la pantalla del reproductor de canciones
import 'firebase_options.dart'; // Configuración de Firebase
import 'login_screen.dart'; // Importa la pantalla de login
import 'register_screen.dart'; // Importa la pantalla de registro
import 'home_screen.dart'; // Importa la pantalla principal post login (HomeScreen)
import 'splash_screen.dart'; // Importa la pantalla de splash
import 'profile_screen.dart'; // Importa la pantalla de perfil
import 'search_screen.dart'; // Importa la pantalla de búsqueda
import 'package:hsound/artist_profile_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ✅ TEMPORAL: Migrar canciones existentes (ejecutar una vez)
  final firestoreService = FirestoreService();
  await firestoreService.updateSongsWithSearchKeywords();
  print('✅ Migración de keywords completada');
  runApp(const MyApp());
  // En main.dart, después de la migración de canciones:
await firestoreService.updateUsersWithSearchKeywords();
print('✅ Migración de keywords de usuarios completada');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hsound',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),      
      
      // 🎯 CORREGIDO: Nuevo sistema de rutas
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(), 
        
        // HomeScreen como ruta principal
        // Las pantallas de Search, Favorites y Profile ahora están DENTRO del HomeScreen
        '/home': (context) => const HomeScreen(),
        
        '/edit_profile': (context) => const EditProfileScreen(),
        '/add_song': (context) => const AddSongScreen(),
        
        '/artist_profile': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ArtistProfileScreen(artistId: args['artistId']);
  },
  
        // Rutas que SÍ necesitan navegación separada:
        '/song_player': (context) { 
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SongPlayerScreen(
            songUrl: args['url'],
            songTitle: args['title'],
            artistName: args['artist'],
            platform: args['platform'],
          );
        },
        
        // ELIMINADAS (opcional 
        // '/search': (context) => const SearchScreen(), // Ahora está dentro de HomeScreen
        // '/favorites': (context) => const FavoritesScreen(), // Ahora está dentro de HomeScreen  
        // '/profile': (context) => const ProfileScreen(), // Ahora está dentro de HomeScreen
      },
    );
  }
}