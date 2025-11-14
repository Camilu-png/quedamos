import '../repositories/friends_repository.dart';

/// Servicio de amigos que usa el repositorio híbrido con cache local
/// Mantiene compatibilidad con la interfaz original
class FriendsService {
  final FriendsRepository _repository;

  FriendsService({FriendsRepository? repository})
      : _repository = repository ?? FriendsRepository();

  // Obtener todos los usuarios
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _repository.getAllUsersStream();
  }

  // Obtener amigos (con cache local)
  Stream<List<Map<String, dynamic>>> getFriends(String userId) {
    return _repository.getFriendsStream(userId).map(
          (friends) => friends
              .map((friend) => {
                    'id': friend.id,
                    'name': friend.name,
                    'email': friend.email,
                    'photoUrl': friend.photoUrl,
                    'localPhotoPath': friend.localPhotoPath,
                    'addedAt': friend.addedAt,
                  })
              .toList(),
        );
  }

  // Agregar amigo bidireccionalmente (con cache local)
  Future<void> addFriend(
    String currentUserId,
    Map<String, dynamic> friendData,
  ) async {
    // Necesitamos los datos del usuario actual
    final currentUserData = await _repository
        .remoteDataSource
        .getUserData(currentUserId);
    
    if (currentUserData == null) {
      throw Exception('[👾 friends services] Current user data not found');
    }

    await _repository.addFriend(currentUserId, friendData, currentUserData);
  }

  // Eliminar amigo bidireccionalmente (con cache local)
  Future<void> deleteFriend(String currentUserId, String friendId) async {
    await _repository.deleteFriend(currentUserId, friendId);
  }

  // Enviar solicitud de amistad (con cache local)
  Future<void> sendFriendRequest(
    String fromUserId,
    Map<String, dynamic> toUserData,
  ) async {
    final fromUserData = await _repository
        .remoteDataSource
        .getUserData(fromUserId);
    
    if (fromUserData == null) {
      throw Exception('[👾 friends services] From user data not found');
    }

    await _repository.sendFriendRequest(fromUserId, toUserData, fromUserData);
  }

  // Obtener solicitudes recibidas (con cache local)
  Stream<List<Map<String, dynamic>>> getFriendRequests(String userId) {
    return _repository.getFriendRequestsStream(userId).map(
          (requests) => requests
              .where((r) => r.status.name == 'pending')
              .map((request) => {
                    'id': request.id,
                    'from': request.from,
                    'to': request.to,
                    'name': request.name,
                    'email': request.email,
                    'photoUrl': request.photoUrl,
                    'localPhotoPath': request.localPhotoPath,
                    'status': request.status.name,
                    'createdAt': request.createdAt,
                  })
              .toList(),
        );
  }

  // Obtener todas las solicitudes de amistad (con cache local)
  Stream<List<Map<String, dynamic>>> getAllFriendRequests(String userId) {
    return _repository.getFriendRequestsStream(userId).map(
          (requests) => requests
              .map((request) => {
                    'id': request.id,
                    'from': request.from,
                    'to': request.to,
                    'name': request.name,
                    'email': request.email,
                    'photoUrl': request.photoUrl,
                    'localPhotoPath': request.localPhotoPath,
                    'status': request.status.name,
                    'createdAt': request.createdAt,
                  })
              .toList(),
        );
  }

  // Aceptar solicitud (con cache local)
  Future<void> acceptFriendRequest(
    String currentUserId,
    Map<String, dynamic> requestData,
  ) async {
    final currentUserData = await _repository
        .remoteDataSource
        .getUserData(currentUserId);
    
    if (currentUserData == null) {
      throw Exception('[👾 friends services] Current user data not found');
    }

    await _repository.acceptFriendRequest(
      currentUserId,
      requestData,
      currentUserData,
    );
  }

  // Rechazar solicitud (con cache local)
  Future<void> rejectFriendRequest(String currentUserId, String fromUserId) async {
    await _repository.rejectFriendRequest(currentUserId, fromUserId);
  }

  // Sincronizar cambios pendientes
  Future<void> syncPendingChanges(String userId) async {
    final currentUserData = await _repository
        .remoteDataSource
        .getUserData(userId);
    
    if (currentUserData == null) {
      throw Exception('[👾 friends services] Current user data not found');
    }

    await _repository.syncPendingChanges(userId, currentUserData);
  }

  void dispose() {
    _repository.dispose();
  }
}
