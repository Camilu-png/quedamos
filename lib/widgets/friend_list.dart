import 'package:flutter/material.dart';

class FriendList extends StatelessWidget {
  final List<Map<String, String>> friends;

  const FriendList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(friend["photo"]!),
            ),
            title: Text(
              friend["name"]!,
              style:  TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
