import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../data/local/friends_local_datasource.dart';
import '../data/remote/friends_remote_datasource.dart';
import '../services/image_cache_service.dart';
import '../services/sync_service.dart';

class FriendsRepository {
  final FriendsLocalDataSource _localDataSource;
  final FriendsRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;
  final ImageCacheService _imageCacheService;
  final SyncService _syncService;

  StreamSubscription? _friendsSubscription;
  StreamSubscription? _requestsSubscription;
  
  // Stream controllers for manual updates
  final _friendsStreamController = StreamController<List<Friend>>.broadcast();
  final _requestsStreamController = StreamController<List<FriendRequest>>.broadcast();

  FriendsRepository({
    FriendsLocalDataSource? localDataSource,
    FriendsRemoteDataSource? remoteDataSource,
    Connectivity? connectivity,
    ImageCacheService? imageCacheService,
    SyncService? syncService,
  })  : _localDataSource = localDataSource ?? FriendsLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? FriendsRemoteDataSource(),
        _connectivity = connectivity ?? Connectivity(),
        _imageCacheService = imageCacheService ?? ImageCacheService(),
        _syncService = syncService ?? SyncService();

  // Expose remote data source for service layer
  FriendsRemoteDataSource get remoteDataSource => _remoteDataSource;

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  // Friends operations
  Stream<List<Friend>> getFriendsStream(String userId) async* {
    // Emit local data first
    final localFriends = await _localDataSource.getAllFriends();
    yield localFriends;

    // Check connectivity
    final isOnline = await _isOnline();
    if (!isOnline) return;

    // Sync pending operations before listening to remote changes
    try {
      final currentUserData = await _remoteDataSource.getUserData(userId);
      if (currentUserData != null) {
        await _syncService.syncPendingOperations(userId, currentUserData);
      }
    } catch (e) {
      // Continue even if sync fails
    }

    // Listen to remote changes and sync
    _friendsSubscription?.cancel();
    _friendsSubscription = _remoteDataSource.getFriendsStream(userId).listen(
      (remoteFriends) async {
        await _localDataSource.deleteAllFriends();
        await _localDataSource.insertFriends(remoteFriends);
        
        // Download images for friends without localPhotoPath
        for (var friend in remoteFriends) {
          if (friend.photoUrl != null && friend.localPhotoPath == null) {
            final localPath = await _imageCacheService.cacheImage(
              friend.photoUrl!,
              friend.id,
            );
            if (localPath != null) {
              final updatedFriend = friend.copyWith(localPhotoPath: localPath);
              await _localDataSource.updateFriend(updatedFriend);
            }
          }
        }
        
        // Cleanup orphaned images
        final activeUserIds = remoteFriends.map((f) => f.id).toList();
        await _imageCacheService.cleanupOrphanedImages(activeUserIds);
      },
    );

    // Stream remote data
    yield* _remoteDataSource.getFriendsStream(userId);
  }

  Future<List<Friend>> getFriends(String userId) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        // Sync pending deletions first before fetching remote friends
        final currentUserData = await _remoteDataSource.getUserData(userId);
        if (currentUserData != null) {
          await _syncService.syncPendingOperations(userId, currentUserData);
        }
        
        final remoteFriends = await _remoteDataSource.getFriends(userId);
        await _localDataSource.deleteAllFriends();
        await _localDataSource.insertFriends(remoteFriends);
        
        // Download images for friends without localPhotoPath
        for (var friend in remoteFriends) {
          if (friend.photoUrl != null && friend.localPhotoPath == null) {
            final localPath = await _imageCacheService.cacheImage(
              friend.photoUrl!,
              friend.id,
            );
            if (localPath != null) {
              final updatedFriend = friend.copyWith(localPhotoPath: localPath);
              await _localDataSource.updateFriend(updatedFriend);
            }
          }
        }
        
        // Cleanup orphaned images
        final activeUserIds = remoteFriends.map((f) => f.id).toList();
        await _imageCacheService.cleanupOrphanedImages(activeUserIds);
        
        return remoteFriends;
      } catch (e) {
        // Fallback to local on error
        return await _localDataSource.getAllFriends();
      }
    }

    return await _localDataSource.getAllFriends();
  }

  Future<void> addFriend(
    String currentUserId,
    Map<String, dynamic> friendData,
    Map<String, dynamic> currentUserData,
  ) async {
    final friend = Friend(
      id: friendData['id'] as String,
      name: friendData['name'] as String,
      email: friendData['email'] as String,
      photoUrl: friendData['photoUrl'] as String?,
      addedAt: DateTime.now(),
      isSynced: false,
    );

    // Save locally first
    await _localDataSource.insertFriend(friend);

    // Download image if available
    if (friend.photoUrl != null) {
      final localPath = await _imageCacheService.cacheImage(
        friend.photoUrl!,
        friend.id,
      );
      if (localPath != null) {
        final updatedFriend = friend.copyWith(localPhotoPath: localPath);
        await _localDataSource.updateFriend(updatedFriend);
      }
    }

    // Sync to remote if online
    final isOnline = await _isOnline();
    if (isOnline) {
      try {
        await _remoteDataSource.addFriend(
          currentUserId,
          friend.copyWith(isSynced: true),
          currentUserData,
        );
        await _localDataSource.updateFriend(friend.copyWith(isSynced: true));
      } catch (e) {
        // Will sync later
      }
    }
  }

  Future<void> deleteFriend(String currentUserId, String friendId) async {
    // Delete locally first
    await _localDataSource.deleteFriend(friendId);

    // Delete image from cache
    await _imageCacheService.deleteImage(friendId);

    // Sync to remote if online
    final isOnline = await _isOnline();
    if (isOnline) {
      try {
        await _remoteDataSource.deleteFriend(currentUserId, friendId);
      } catch (e) {
        // If sync fails, save as pending deletion
        await _localDataSource.insertPendingDeletion(currentUserId, friendId);
      }
    } else {
      // If offline, save as pending deletion
      await _localDataSource.insertPendingDeletion(currentUserId, friendId);
    }
  }

  // Friend Requests operations
  Stream<List<FriendRequest>> getFriendRequestsStream(String userId) async* {
    // Emit local data first
    final localRequests = await _localDataSource.getAllFriendRequests();
    yield localRequests;

    // Check connectivity
    final isOnline = await _isOnline();
    
    // Listen to remote changes and sync if online
    if (isOnline) {
      _requestsSubscription?.cancel();
      _requestsSubscription = _remoteDataSource.getFriendRequestsStream(userId).listen(
        (remoteRequests) async {
          await _localDataSource.deleteAllFriendRequests();
          await _localDataSource.insertFriendRequests(remoteRequests);
          
          // Download images for friend requests without localPhotoPath
          for (var request in remoteRequests) {
            if (request.photoUrl != null && request.localPhotoPath == null) {
              final localPath = await _imageCacheService.cacheImage(
                request.photoUrl!,
                request.id,
              );
              if (localPath != null) {
                final updatedRequest = request.copyWith(localPhotoPath: localPath);
                await _localDataSource.updateFriendRequest(updatedRequest);
              }
            }
          }
          
          _requestsStreamController.add(remoteRequests);
        },
      );
    }
    
    // Always listen to manual updates from StreamController (works both online and offline)
    await for (final requests in _requestsStreamController.stream) {
      yield requests;
    }
  }

  Future<List<FriendRequest>> getPendingFriendRequests(String userId) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        final remoteRequests = await _remoteDataSource.getPendingFriendRequests(userId);
        await _localDataSource.deleteAllFriendRequests();
        await _localDataSource.insertFriendRequests(remoteRequests);
        return remoteRequests;
      } catch (e) {
        return await _localDataSource.getPendingFriendRequests();
      }
    }

    return await _localDataSource.getPendingFriendRequests();
  }

  Future<void> sendFriendRequest(
    String fromUserId,
    Map<String, dynamic> toUserData,
    Map<String, dynamic> fromUserData,
  ) async {
    final request = FriendRequest(
      id: toUserData['id'] as String,
      from: fromUserId,
      to: toUserData['id'] as String,
      name: toUserData['name'] as String,
      email: toUserData['email'] as String,
      photoUrl: toUserData['photoUrl'] as String?,
      status: FriendRequestStatus.sent,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    // Save locally first
    await _localDataSource.insertFriendRequest(request);

    // Sync to remote if online
    final isOnline = await _isOnline();
    if (isOnline) {
      try {
        await _remoteDataSource.sendFriendRequest(
          fromUserId,
          toUserData,
          fromUserData,
        );
        await _localDataSource.updateFriendRequest(request.copyWith(isSynced: true));
      } catch (e) {
        // Will sync later
      }
    }
    
    // Emit updated friend requests list
    final updatedRequests = await _localDataSource.getAllFriendRequests();
    _requestsStreamController.add(updatedRequests);
  }

  Future<void> acceptFriendRequest(
    String currentUserId,
    Map<String, dynamic> requestData,
    Map<String, dynamic> currentUserData,
  ) async {
    // Build FriendRequest safely from requestData
    // Handle both Firestore format and local service format
    final createdAt = requestData['createdAt'];
    final DateTime requestCreatedAt;
    if (createdAt is DateTime) {
      requestCreatedAt = createdAt;
    } else if (createdAt != null) {
      requestCreatedAt = (createdAt as dynamic).toDate();
    } else {
      requestCreatedAt = DateTime.now();
    }

    final request = FriendRequest(
      id: requestData['id'] as String,
      from: requestData['from'] as String,
      to: requestData['to'] as String,
      name: requestData['name'] as String,
      email: requestData['email'] as String,
      photoUrl: requestData['photoUrl'] as String?,
      localPhotoPath: requestData['localPhotoPath'] as String?,
      status: FriendRequestStatus.fromJson(requestData['status'] as String),
      createdAt: requestCreatedAt,
      isSynced: true,
    );

    // Delete request locally (use 'from' as the ID)
    await _localDataSource.deleteFriendRequest(request.from);

    // Add friend locally - use localPhotoPath from request if available
    final friend = Friend(
      id: request.from,
      name: request.name,
      email: request.email,
      photoUrl: request.photoUrl,
      localPhotoPath: request.localPhotoPath,
      addedAt: DateTime.now(),
      isSynced: false,
    );
    await _localDataSource.insertFriend(friend);

    // Download image if available and not already cached
    if (friend.photoUrl != null && request.localPhotoPath == null) {
      final localPath = await _imageCacheService.cacheImage(
        friend.photoUrl!,
        friend.id,
      );
      if (localPath != null) {
        final updatedFriend = friend.copyWith(localPhotoPath: localPath);
        await _localDataSource.updateFriend(updatedFriend);
      }
    }

    // Sync to remote if online
    final isOnline = await _isOnline();
    if (isOnline) {
      try {
        await _remoteDataSource.acceptFriendRequest(
          currentUserId,
          request,
          currentUserData,
        );
        await _localDataSource.updateFriend(friend.copyWith(isSynced: true));
      } catch (e) {
        // If sync fails, save as pending acceptance
        await _localDataSource.insertPendingAcceptance(currentUserId, requestData);
      }
    } else {
      // If offline, save as pending acceptance
      await _localDataSource.insertPendingAcceptance(currentUserId, requestData);
    }
    
    // Emit updated friend requests list
    final updatedRequests = await _localDataSource.getAllFriendRequests();
    _requestsStreamController.add(updatedRequests);
    
    // Emit updated friends list
    final updatedFriends = await _localDataSource.getAllFriends();
    _friendsStreamController.add(updatedFriends);
  }

  Future<void> rejectFriendRequest(String currentUserId, String fromUserId) async {
    // Delete locally first
    await _localDataSource.deleteFriendRequest(fromUserId);

    // Sync to remote if online
    final isOnline = await _isOnline();
    if (isOnline) {
      try {
        await _remoteDataSource.rejectFriendRequest(currentUserId, fromUserId);
      } catch (e) {
        // Already deleted locally
      }
    }
    
    // Emit updated friend requests list
    final updatedRequests = await _localDataSource.getAllFriendRequests();
    _requestsStreamController.add(updatedRequests);
  }

  // Sync operations
  Future<void> syncPendingChanges(String userId, Map<String, dynamic> currentUserData) async {
    final isOnline = await _isOnline();
    if (!isOnline) return;

    // Use SyncService to sync pending operations
    await _syncService.syncPendingOperations(userId, currentUserData);
  }

  // Users operations (delegated to remote)
  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _remoteDataSource.getAllUsersStream();
  }

  void dispose() {
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _friendsStreamController.close();
    _requestsStreamController.close();
  }
}
