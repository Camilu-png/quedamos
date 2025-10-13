import 'package:flutter/material.dart';
import '../widgets/friend_list.dart';
import '../widgets/custom_navbar.dart';
import 'package:quedamos/text_styles.dart';
import '../app_colors.dart';

final List<Map<String, dynamic>> friends = [
  {"name": "Alice", "color": Colors.blue},
  {"name": "Bob", "color": Colors.green},
  {"name": "Charlie", "color": Colors.red},
  {"name": "Diana", "color": Colors.purple},
  {"name": "Eve", "color": Colors.orange},
  {"name": "Frank", "color": Colors.teal},
  {"name": "Grace", "color": Colors.cyan},
  {"name": "Hank", "color": Colors.amber},
  {"name": "Ivy", "color": Colors.indigo},
  {"name": "Jack", "color": Colors.lime},
];

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nuevo Amigo",
          style: titleText,
        ),
        centerTitle: true,
      ),
      body: Padding(
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
            Expanded(
              child: FriendList(
                friends: friends
                    .where((friend) => friend["name"]!
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList(),
                showIcons: true,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          // TODO: Implementar la navegación entre pantallas
        },
      ),
    );
  }
}