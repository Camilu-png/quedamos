import '../data/local/friends_local_datasource.dart';
import '../data/remote/friends_remote_datasource.dart';

/// Service for synchronizing pending offline operations with the remote server
class SyncService {
  final FriendsLocalDataSource _localDataSource;
  final FriendsRemoteDataSource _remoteDataSource;

  SyncService({
    FriendsLocalDataSource? localDataSource,
    FriendsRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? FriendsLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? FriendsRemoteDataSource();

  /// Synchronizes all pending operations (friends and friend requests) with the remote server
  /// 
  /// This method:
  /// - Gets all unsynced friends and attempts to sync them
  /// - Gets all unsynced friend requests and attempts to sync them
  /// - Updates the isSynced flag to true after successful sync
  /// - Continues with next item if one fails (no retry logic)
  Future<void> syncPendingOperations(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    // Sync pending acceptances first (before deletions)
    final pendingAcceptances = await _localDataSource.getPendingAcceptances();
    for (var acceptance in pendingAcceptances) {
      try {
        final currentUserId = acceptance['currentUserId'] as String;
        // Note: requestData is stored as string, we need to parse it properly
        // For now, we'll get the friend from local DB and sync it
        final fromUserId = acceptance['id'].toString().split('_')[1];
        
        // Get the friend from local database
        final friend = await _localDataSource.getFriendById(fromUserId);
        if (friend != null) {
          // Sync the friend to remote
          await _remoteDataSource.addFriend(currentUserId, friend, userData);
          await _localDataSource.updateFriend(friend.copyWith(isSynced: true));
          
          // Reject the friend request on the server
          try {
            await _remoteDataSource.rejectFriendRequest(currentUserId, fromUserId);
          } catch (e) {
            // Request might already be processed
          }
        }
        
        await _localDataSource.deletePendingAcceptance(acceptance['id'] as String);
        print('[👾 sync services] Synced acceptance ${acceptance['id']}');
      } catch (e) {
        // Continue with next acceptance - will retry on next sync
        print('[👾 sync services] Failed to sync acceptance ${acceptance['id']}: $e');
      }
    }

    // Sync pending deletions
    final pendingDeletions = await _localDataSource.getPendingDeletions();
    for (var deletion in pendingDeletions) {
      try {
        final currentUserId = deletion['currentUserId'] as String;
        final friendId = deletion['friendId'] as String;
        
        // Delete friend relationship
        await _remoteDataSource.deleteFriend(currentUserId, friendId);
        
        // Also reject any pending friend request from this user
        // This handles the case where a request was accepted offline then deleted
        try {
          await _remoteDataSource.rejectFriendRequest(currentUserId, friendId);
        } catch (e) {
          // Request might not exist, that's ok
        }
        
        await _localDataSource.deletePendingDeletion(deletion['id'] as String);
        print('[👾 sync services] Synced deletion ${deletion['id']}');
      } catch (e) {
        // Continue with next deletion - will retry on next sync
        print('[👾 sync services] Failed to sync deletion ${deletion['id']}: $e');
      }
    }

    // Sync unsynced friends
    final unsyncedFriends = await _localDataSource.getUnsyncedFriends();
    for (var friend in unsyncedFriends) {
      try {
        await _remoteDataSource.addFriend(userId, friend, userData);
        await _localDataSource.updateFriend(friend.copyWith(isSynced: true));
      } catch (e) {
        // Continue with next friend - will retry on next sync
        print('[👾 sync services] Failed to sync friend ${friend.id}: $e');
      }
    }

    // Sync unsynced friend requests
    final unsyncedRequests = await _localDataSource.getUnsyncedFriendRequests();
    for (var request in unsyncedRequests) {
      try {
        // Get the target user data to send the request
        final toUserData = await _remoteDataSource.getUserData(request.to);
        if (toUserData != null) {
          await _remoteDataSource.sendFriendRequest(
            request.from,
            toUserData,
            userData,
          );
          await _localDataSource.updateFriendRequest(
            request.copyWith(isSynced: true),
          );
        }
      } catch (e) {
        // Continue with next request - will retry on next sync
        print('[👾 sync services] Failed to sync friend request ${request.id}: $e');
      }
    }
  }

  /// Checks if there are any pending operations that need to be synchronized
  /// 
  /// Returns true if there are unsynced friends, friend requests, pending deletions, or pending acceptances
  Future<bool> hasPendingOperations() async {
    final unsyncedFriends = await _localDataSource.getUnsyncedFriends();
    final unsyncedRequests = await _localDataSource.getUnsyncedFriendRequests();
    final pendingDeletions = await _localDataSource.getPendingDeletions();
    final pendingAcceptances = await _localDataSource.getPendingAcceptances();
    
    return unsyncedFriends.isNotEmpty || 
           unsyncedRequests.isNotEmpty || 
           pendingDeletions.isNotEmpty ||
           pendingAcceptances.isNotEmpty;
  }
}
