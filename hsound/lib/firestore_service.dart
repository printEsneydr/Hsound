import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song_model.dart'; // ✅ AGREGAR ESTE IMPORT

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Guardar perfil de usuario
  Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));
    }
  }
  
  // Obtener perfil de usuario
  Future<DocumentSnapshot> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    return await _firestore.collection('users').doc(user!.uid).get();
  }
  
  // Obtener perfil de usuario como Stream (para updates en tiempo real)
  Stream<DocumentSnapshot> getUserProfileStream() {
    final user = FirebaseAuth.instance.currentUser;
    return _firestore.collection('users').doc(user!.uid).snapshots();
  }
  
  // ✅ ACTUALIZADA: Guardar canción usando el modelo Song
  Future<void> saveSong(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('songs').add(song.toFirestore());
    }
  }
  
  // Obtener canciones del artista
  Stream<QuerySnapshot> getArtistSongs(String artistId) {
    return _firestore
        .collection('songs')
        .where('artistId', isEqualTo: artistId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Obtener todas las canciones (para explorar)
  Stream<QuerySnapshot> getAllSongs() {
    return _firestore
        .collection('songs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  //  Obtener canciones por género
  Stream<QuerySnapshot> getSongsByGenre(String genre) {
    return _firestore
        .collection('songs')
        .where('genre', isEqualTo: genre)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  // Eliminar canción
Future<void> deleteSong(String songId) async {
  try {
    await _firestore.collection('songs').doc(songId).delete();
    print('Canción $songId eliminada exitosamente');
  } catch (e) {
    print('Error al eliminar canción: $e');
    throw e;
  }
}
}