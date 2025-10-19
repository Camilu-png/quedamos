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

  // Enviar solicitud de amistad (se registra en ambos usuarios)
Future<void> sendFriendRequest(String fromUserId, Map<String, dynamic> toUserData) async {
  final batch = _firestore.batch();

  // Referencias de subcolecciones
  final toRequestRef = _firestore
      .collection('users')
      .doc(toUserData['id'])
      .collection('friendRequests')
      .doc(fromUserId);

  final fromRequestRef = _firestore
      .collection('users')
      .doc(fromUserId)
      .collection('friendRequests')
      .doc(toUserData['id']);

  // Datos de los usuarios
  final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
  final fromUserData = {'id': fromUserDoc.id, ...fromUserDoc.data() ?? {}};

  // Documento en el receptor (solicitud recibida)
  batch.set(toRequestRef, {
    'from': fromUserData['id'],
    'to': toUserData['id'],
    'name': fromUserData['name'],
    'email': fromUserData['email'],
    'photoUrl': fromUserData['photoUrl'],
    'status': 'pending', // pendiente de aceptar
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Documento en el emisor (solicitud enviada)
  batch.set(fromRequestRef, {
    'from': fromUserData['id'],
    'to': toUserData['id'],
    'name': toUserData['name'],
    'email': toUserData['email'],
    'photoUrl': toUserData['photoUrl'],
    'status': 'sent', // enviada, esperando respuesta
    'createdAt': FieldValue.serverTimestamp(),
  });

  print("👾 friendRequest ${fromUserData['name']} -> ${toUserData['name']}");

  await batch.commit();
}


  // Obtener solicitudes recibidas
  Stream<List<Map<String, dynamic>>> getFriendRequests(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Obtener todas las solicitudes de amistad (enviadas y recibidas)
Stream<List<Map<String, dynamic>>> getAllFriendRequests(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('friendRequests')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
}


  // Aceptar solicitud
  Future<void> acceptFriendRequest(String currentUserId, Map<String, dynamic> requestData) async {
    final fromUserId = requestData['from'];

    // 1. Agregar a amigos
    await addFriend(currentUserId, requestData);

    // 2. Eliminar solicitud
    final requestRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(fromUserId);

    await requestRef.delete();
  }

  // Rechazar solicitud
  Future<void> rejectFriendRequest(String currentUserId, String fromUserId) async {
    final requestRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(fromUserId);

    await requestRef.delete();
  }
}
