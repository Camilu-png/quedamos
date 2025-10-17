import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todos los usuarios
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Obtener amigos
  Stream<List<Map<String, dynamic>>> getFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Agregar amigo bidireccionalmente
Future<void> addFriend(String currentUserId, Map<String, dynamic> friendData) async {
  final friendId = friendData["id"];
  final batch = _firestore.batch();

  // Referencias
  final currentUserRef = _firestore
      .collection('users')
      .doc(currentUserId)
      .collection('friends')
      .doc(friendId);

  final friendUserRef = _firestore
      .collection('users')
      .doc(friendId)
      .collection('friends')
      .doc(currentUserId);

  // Obtener datos del usuario actual
  final currentUserDoc =
      await _firestore.collection('users').doc(currentUserId).get();
  final currentUserData = {
    'id': currentUserDoc.id,
    ...currentUserDoc.data() ?? {}
  };

  // Agregar ambos documentos
  batch.set(currentUserRef, {
    'id': friendId,
    'name': friendData['name'],
    'email': friendData['email'],
    'photoUrl': friendData['photoUrl'],
    'addedAt': FieldValue.serverTimestamp(),
  });

  batch.set(friendUserRef, {
    'id': currentUserData['id'],
    'name': currentUserData['name'],
    'email': currentUserData['email'],
    'photoUrl': currentUserData['photoUrl'],
    'addedAt': FieldValue.serverTimestamp(),
  });

  await batch.commit();
}


  // Eliminar amigo bidireccionalmente
  Future<void> deleteFriend(String currentUserId, String friendId) async {
    final batch = _firestore.batch();

    final userRef =
        _firestore.collection('users').doc(currentUserId).collection('friends').doc(friendId);
    final friendRef =
        _firestore.collection('users').doc(friendId).collection('friends').doc(currentUserId);

    batch.delete(userRef);
    batch.delete(friendRef);

    await batch.commit();
  }
}
