import 'package:flutter/material.dart';
import 'package:quedamos/screens/add_friend_screen.dart';
import 'package:quedamos/screens/main_screen.dart';
import 'package:quedamos/text_styles.dart';
import '../widgets/friend_list.dart';
import '../app_colors.dart';

final List<Map<String, dynamic>> friends = [
  {"name": "Alice", "color": Colors.pink},
  {"name": "Bob", "color": Colors.purple},
  {"name": "Charlie", "color": Colors.green},
  {"name": "Diana", "color": Colors.blue},
  {"name": "Eve", "color": Colors.red},
  {"name": "Frank", "color": Colors.orange},
  {"name": "Grace", "color": Colors.yellow},
  {"name": "Hank", "color": Colors.brown},
  {"name": "Ivy", "color": Colors.cyan},
  {"name": "Jack", "color": Colors.lime},
];

class FriendsScreen extends StatefulWidget {
  final String userID;
  const FriendsScreen({super.key, required this.userID});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    print("UID del usuario -> ${widget.userID}");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Amigos", style: titleText),
        centerTitle: true,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 45,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final mainState = context.findAncestorStateOfType<MainScreenState>();
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
              child: FriendList(friends: friends, showIcons: false),
            ),
          ],
        ),
      ),
    );
  }
}