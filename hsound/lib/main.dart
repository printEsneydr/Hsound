import 'package:flutter/material.dart';  // Flutter UI
import 'package:firebase_core/firebase_core.dart'; // Inicialización de Firebase
import 'package:hsound/add_song_screen.dart'; // Importa la pantalla para agregar canciones
import 'package:hsound/edit_profile_screen.dart'; // Importa la pantalla de edición de perfil
import 'package:hsound/firestore_service.dart';
import 'package:hsound/song_player_screen.dart'; // Importa la pantalla del reproductor de canciones
import 'firebase_options.dart'; // Configuración de Firebase
import 'login_screen.dart'; // Importa la pantalla de login
import 'register_screen.dart'; // Importa la pantalla de registro
import 'home_screen.dart'; // Importa la pantalla principal post login (HomeScreen)
import 'splash_screen.dart'; // Importa la pantalla de splash
import 'profile_screen.dart'; // Importa la pantalla de perfil
import 'search_screen.dart'; // Importa la pantalla de búsqueda

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
      
      //home: const HomeScreen(), // Directo al home (SOLO TESTING)

      //se agrega la screen de splash para mostrar el logo al iniciar la app
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(), 
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(), // NUEVA RUTA
        '/add_song': (context) => const AddSongScreen(),
        // Agregar la ruta para SongPlayerScreen con argumentos 
        // para pasar la información de la canción a reproducir 
        '/song_player': (context) { 
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SongPlayerScreen(
            songUrl: args['url'],
            songTitle: args['title'],
            artistName: args['artist'],
            platform: args['platform'],
          );
          },
          '/search': (context) => const SearchScreen(), // ruta para SearchScreen
      },
    );
  }
}
