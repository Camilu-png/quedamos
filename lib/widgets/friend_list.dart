import 'package:flutter/material.dart';
import 'package:quedamos/text_styles.dart';
import 'package:quedamos/app_colors.dart';

class FriendList extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final bool showIcons;

  const FriendList({
    super.key,
    required this.friends,
    this.showIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Acción al seleccionar un amigo
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar/Color
                  Container(
                    width: 80,
                    height: 70,
                    decoration: BoxDecoration(
                      color: (friend["color"] as Color).withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.perm_identity,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  // Información del amigo
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend["name"] ?? '',
                            style: subtitleText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botón agregar amigo con highlight
                  if (showIcons)
                    Padding(
                      padding: const EdgeInsets.only(right: 15.0),
                      child: Center(
                        child: _AddFriendButton(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddFriendButton extends StatefulWidget {
  const _AddFriendButton({super.key});

  @override
  State<_AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<_AddFriendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _pressed = true);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _pressed = false);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _pressed ? lightDark : primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.person_add_alt_1_outlined,
          size: 20,
          color: Colors.black,
        ),
      ),
    );
  }
}