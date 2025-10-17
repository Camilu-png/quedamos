import 'package:flutter/material.dart';
import 'package:quedamos/app_colors.dart';
import 'package:quedamos/screens/add_friend_screen.dart';
import 'package:quedamos/screens/main_screen.dart';
import 'package:quedamos/services/friends_service.dart';
import 'package:quedamos/text_styles.dart';
import '../widgets/friend_list.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final String _currentUserId = "uid_cristina"; // FirebaseAuth.instance.currentUser!.uid

  Future<void> _deleteFriend(String friendId) async {
    try {
      await _friendsService.deleteFriend(_currentUserId, friendId);
    } catch (e) {
      debugPrint("Error al eliminar amigo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar amigo'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Mis Amigos", style: titleText),
        centerTitle: true,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendsService.getFriends(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data ?? [];

          if (friends.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(

                children: [SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final mainState =
                          context.findAncestorStateOfType<MainScreenState>();
                      mainState?.navigateTo(const AddFriendsScreen());
                    },
                    icon: const Icon(Icons.add, size: 24, color: Colors.white),
                    label: Text(
                      "Nuevo amigo",
                      style: bodyPrimaryText.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                "Todavía no tienes amigos 😢",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              ],
              )
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final mainState =
                          context.findAncestorStateOfType<MainScreenState>();
                      mainState?.navigateTo(const AddFriendsScreen());
                    },
                    icon: const Icon(Icons.add, size: 24, color: Colors.white),
                    label: Text(
                      "Nuevo amigo",
                      style: bodyPrimaryText.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 600,
                  child: FriendList(
                    friends: friends,
                    showIcons: false,
                    onDelete: _deleteFriend,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
