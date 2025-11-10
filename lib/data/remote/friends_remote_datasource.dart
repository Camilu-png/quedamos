import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/friend.dart';
import '../../models/friend_request.dart';

class FriendsRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Friends operations
  Stream<List<Friend>> getFriendsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friend.fromFirestore({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<List<Friend>> getFriends(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();

    return snapshot.docs
        .map((doc) => Friend.fromFirestore({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<void> addFriend(String currentUserId, Friend friend, Map<String, dynamic> currentUserData) async {
    final batch = _firestore.batch();

    final currentUserRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friend.id);

    final friendUserRef = _firestore
        .collection('users')
        .doc(friend.id)
        .collection('friends')
        .doc(currentUserId);

    batch.set(currentUserRef, friend.toFirestore());

    final currentFriend = Friend(
      id: currentUserData['id'] as String,
      name: currentUserData['name'] as String,
      email: currentUserData['email'] as String,
      photoUrl: currentUserData['photoUrl'] as String?,
      addedAt: DateTime.now(),
    );

    batch.set(friendUserRef, currentFriend.toFirestore());

    await batch.commit();
  }

  Future<void> deleteFriend(String currentUserId, String friendId) async {
    final batch = _firestore.batch();

    final userRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId);

    final friendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUserId);

    batch.delete(userRef);
    batch.delete(friendRef);

    await batch.commit();
  }

  // Friend Requests operations
  Stream<List<FriendRequest>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromFirestore({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<List<FriendRequest>> getFriendRequests(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .get();

    return snapshot.docs
        .map((doc) => FriendRequest.fromFirestore({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<List<FriendRequest>> getPendingFriendRequests(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
        .map((doc) => FriendRequest.fromFirestore({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<void> sendFriendRequest(
    String fromUserId,
    Map<String, dynamic> toUserData,
    Map<String, dynamic> fromUserData,
  ) async {
    final batch = _firestore.batch();

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

    final toRequest = FriendRequest(
      id: fromUserId,
      from: fromUserId,
      to: toUserData['id'] as String,
      name: fromUserData['name'] as String,
      email: fromUserData['email'] as String,
      photoUrl: fromUserData['photoUrl'] as String?,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    final fromRequest = FriendRequest(
      id: toUserData['id'] as String,
      from: fromUserId,
      to: toUserData['id'] as String,
      name: toUserData['name'] as String,
      email: toUserData['email'] as String,
      photoUrl: toUserData['photoUrl'] as String?,
      status: FriendRequestStatus.sent,
      createdAt: DateTime.now(),
    );

    batch.set(toRequestRef, toRequest.toFirestore());
    batch.set(fromRequestRef, fromRequest.toFirestore());

    await batch.commit();
  }

  Future<void> acceptFriendRequest(
    String currentUserId,
    FriendRequest request,
    Map<String, dynamic> currentUserData,
  ) async {
    final batch = _firestore.batch();

    // Add as friends
    final friend = Friend(
      id: request.from,
      name: request.name,
      email: request.email,
      photoUrl: request.photoUrl,
      addedAt: DateTime.now(),
    );

    await addFriend(currentUserId, friend, currentUserData);

    // Delete requests
    final currentRequestRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(request.from);

    final fromRequestRef = _firestore
        .collection('users')
        .doc(request.from)
        .collection('friendRequests')
        .doc(currentUserId);

    batch.delete(currentRequestRef);
    batch.delete(fromRequestRef);

    await batch.commit();
  }

  Future<void> rejectFriendRequest(String currentUserId, String fromUserId) async {
    final batch = _firestore.batch();

    final currentRequestRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(fromUserId);

    final fromRequestRef = _firestore
        .collection('users')
        .doc(fromUserId)
        .collection('friendRequests')
        .doc(currentUserId);

    batch.delete(currentRequestRef);
    batch.delete(fromRequestRef);

    await batch.commit();
  }

  // Users operations
  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }
}
