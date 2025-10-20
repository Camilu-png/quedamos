import 'package:flutter/material.dart';
import 'package:quedamos/services/friends_service.dart';
import '../widgets/friend_list.dart';
import 'package:quedamos/text_styles.dart';
import '../app_colors.dart';

class AddFriendsScreen extends StatefulWidget {
  final String userID;
  const AddFriendsScreen({super.key, required this.userID});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            "Nuevo Amigo",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            )
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
          elevation: 0,
        ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendsService.getAllUsers(),
        builder: (context, allUsersSnapshot) {
          if (allUsersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _friendsService.getFriends(widget.userID),
            builder: (context, friendsSnapshot) {
              if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _friendsService.getAllFriendRequests(widget.userID),
                builder: (context, requestsSnapshot) {
                  if (requestsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allUsers = allUsersSnapshot.data ?? [];
                  final currentFriends = friendsSnapshot.data ?? [];
                  final friendRequests = requestsSnapshot.data ?? [];

                  // IDs de amigos actuales
                  final friendIds = currentFriends.map((f) => f["id"]).toSet();

                  // IDs de usuarios con solicitudes pendientes (enviadas o recibidas)
                  final requestedIds = friendRequests.map((r) {
                    final from = r["from"];
                    final to = r["to"];
                    return from == widget.userID ? to : from;
                  }).toSet();

                  final filteredUsers = allUsers.where((user) {
                    final userId = user["id"];
                    final userName = (user["name"] ?? "").toLowerCase();
                    return userId != widget.userID &&
                        !friendIds.contains(userId) &&
                        !requestedIds.contains(userId) &&
                        userName.contains(searchQuery.toLowerCase());
                  }).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 45,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            style: helpText,
                            decoration: const InputDecoration(
                              hintText: 'Buscar amigo...',
                              prefixIcon: Icon(Icons.search, color: primaryDark),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: primaryDark, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: primaryDark, width: 1),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 600,
                          child: FriendList(
                            friends: filteredUsers,
                            showIcons: true,
                            onAddFriend: (friendId) async {
                              final friendData = filteredUsers.firstWhere((f) => f['id'] == friendId);
                              await _friendsService.sendFriendRequest(widget.userID, friendData);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
