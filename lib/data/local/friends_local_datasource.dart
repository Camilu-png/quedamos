import 'package:sqflite/sqflite.dart';
import '../../models/friend.dart';
import '../../models/friend_request.dart';
import 'database_helper.dart';

class FriendsLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Friends CRUD
  Future<void> insertFriend(Friend friend) async {
    final db = await _dbHelper.database;
    await db.insert(
      'friends',
      friend.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertFriends(List<Friend> friends) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var friend in friends) {
      batch.insert(
        'friends',
        friend.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Friend>> getAllFriends() async {
    final db = await _dbHelper.database;
    final result = await db.query('friends', orderBy: 'addedAt DESC');
    return result.map((map) => Friend.fromMap(map)).toList();
  }

  Future<Friend?> getFriendById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'friends',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Friend.fromMap(result.first);
  }

  Future<void> deleteFriend(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'friends',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllFriends() async {
    final db = await _dbHelper.database;
    await db.delete('friends');
  }

  Future<List<Friend>> getUnsyncedFriends() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'friends',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((map) => Friend.fromMap(map)).toList();
  }

  Future<void> updateFriend(Friend friend) async {
    final db = await _dbHelper.database;
    await db.update(
      'friends',
      friend.toMap(),
      where: 'id = ?',
      whereArgs: [friend.id],
    );
  }

  // Friend Requests CRUD
  Future<void> insertFriendRequest(FriendRequest request) async {
    final db = await _dbHelper.database;
    final map = request.toMap();
    await db.insert(
      'friend_requests',
      {
        'id': map['id'],
        'from_user': map['from'],
        'to_user': map['to'],
        'name': map['name'],
        'email': map['email'],
        'photoUrl': map['photoUrl'],
        'localPhotoPath': map['localPhotoPath'],
        'status': map['status'],
        'createdAt': map['createdAt'],
        'isSynced': map['isSynced'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertFriendRequests(List<FriendRequest> requests) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var request in requests) {
      final map = request.toMap();
      batch.insert(
        'friend_requests',
        {
          'id': map['id'],
          'from_user': map['from'],
          'to_user': map['to'],
          'name': map['name'],
          'email': map['email'],
          'photoUrl': map['photoUrl'],
          'localPhotoPath': map['localPhotoPath'],
          'status': map['status'],
          'createdAt': map['createdAt'],
          'isSynced': map['isSynced'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<FriendRequest>> getAllFriendRequests() async {
    final db = await _dbHelper.database;
    final result = await db.query('friend_requests', orderBy: 'createdAt DESC');
    return result.map((map) => _friendRequestFromDbMap(map)).toList();
  }

  Future<List<FriendRequest>> getPendingFriendRequests() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'friend_requests',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => _friendRequestFromDbMap(map)).toList();
  }

  Future<void> deleteFriendRequest(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'friend_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllFriendRequests() async {
    final db = await _dbHelper.database;
    await db.delete('friend_requests');
  }

  Future<List<FriendRequest>> getUnsyncedFriendRequests() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'friend_requests',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((map) => _friendRequestFromDbMap(map)).toList();
  }

  Future<void> updateFriendRequest(FriendRequest request) async {
    final db = await _dbHelper.database;
    final map = request.toMap();
    await db.update(
      'friend_requests',
      {
        'id': map['id'],
        'from_user': map['from'],
        'to_user': map['to'],
        'name': map['name'],
        'email': map['email'],
        'photoUrl': map['photoUrl'],
        'localPhotoPath': map['localPhotoPath'],
        'status': map['status'],
        'createdAt': map['createdAt'],
        'isSynced': map['isSynced'],
      },
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  FriendRequest _friendRequestFromDbMap(Map<String, dynamic> map) {
    return FriendRequest.fromMap({
      'id': map['id'],
      'from': map['from_user'],
      'to': map['to_user'],
      'name': map['name'],
      'email': map['email'],
      'photoUrl': map['photoUrl'],
      'localPhotoPath': map['localPhotoPath'],
      'status': map['status'],
      'createdAt': map['createdAt'],
      'isSynced': map['isSynced'],
    });
  }

  // Pending Deletions CRUD
  Future<void> insertPendingDeletion(String currentUserId, String friendId) async {
    final db = await _dbHelper.database;
    await db.insert(
      'pending_deletions',
      {
        'id': '${currentUserId}_$friendId',
        'currentUserId': currentUserId,
        'friendId': friendId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingDeletions() async {
    final db = await _dbHelper.database;
    return await db.query('pending_deletions', orderBy: 'createdAt ASC');
  }

  Future<void> deletePendingDeletion(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pending_deletions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Pending Acceptances CRUD
  Future<void> insertPendingAcceptance(
    String currentUserId,
    Map<String, dynamic> requestData,
  ) async {
    final db = await _dbHelper.database;
    final fromUserId = requestData['from'] as String;
    await db.insert(
      'pending_acceptances',
      {
        'id': '${currentUserId}_$fromUserId',
        'currentUserId': currentUserId,
        'requestData': requestData.toString(), // Simple serialization
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingAcceptances() async {
    final db = await _dbHelper.database;
    return await db.query('pending_acceptances', orderBy: 'createdAt ASC');
  }

  Future<void> deletePendingAcceptance(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pending_acceptances',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
