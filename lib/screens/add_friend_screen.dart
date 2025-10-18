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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Nuevo Amigo",
          style: titleText,
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
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

              final allUsers = allUsersSnapshot.data ?? [];
              final currentFriends = friendsSnapshot.data ?? [];

              final friendIds = currentFriends.map((f) => f["id"]).toSet();

              final filteredUsers = allUsers.where((user) {
                final userId = user["id"];
                final userName = (user["name"] ?? "").toLowerCase();
                return userId != widget.userID && 
                    !friendIds.contains(userId) &&
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
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide:
                                BorderSide(color: primaryDark, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide:
                                BorderSide(color: primaryDark, width: 1),
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
                          final friendData = filteredUsers
                              .firstWhere((f) => f['id'] == friendId);
                          await _friendsService.addFriend(widget.userID, friendData); 
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
