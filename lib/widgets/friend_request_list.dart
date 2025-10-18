import 'package:flutter/material.dart';
import 'package:quedamos/text_styles.dart';
import 'package:quedamos/app_colors.dart';

class _TextButtonAction extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _TextButtonAction({
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  State<_TextButtonAction> createState() => _TextButtonActionState();
}

class _TextButtonActionState extends State<_TextButtonAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _pressed = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _pressed = false);
        });
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.6)
              : widget.color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class FriendRequestList extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final void Function(String friendId)? onAccept;
  final void Function(String friendId)? onReject;

  const FriendRequestList({
    super.key,
    required this.friends,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Foto del usuario
                Container(
                  width: 80,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: friend["photoUrl"] != null
                        ? Image.network(
                            friend["photoUrl"],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _defaultAvatar(friend),
                          )
                        : _defaultAvatar(friend),
                  ),
                ),

                // Nombre del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friend["name"] ?? '', style: subtitleText),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _TextButtonAction(
                              text: "Aceptar",
                              color: Colors.greenAccent.shade400,
                              onTap: () {
                                  if (onAccept != null) {
                                    onAccept!(friend["id"]);
                                  }
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${friend["name"]} ahora es tu amigo 🎉'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: secondary,
                                    ),
                                  );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TextButtonAction(
                              text: "Rechazar",
                              color: Colors.redAccent.shade200,
                              onTap: () {
                                if (onReject != null) {
                                  onReject!(friend["id"]);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Solicitud de ${friend["name"]} rechazada ❌'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),],
            ),
          ),
        );
      },
    );
  }

  Widget _defaultAvatar(Map<String, dynamic> friend) {
    return Container(
      color: (friend["color"] as Color?)?.withOpacity(0.7) ??
          primaryDark.withOpacity(0.7),
      child: const Center(
        child: Icon(Icons.perm_identity, color: Colors.white, size: 36),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _pressed = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _pressed = false);
        });
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withOpacity(0.6) : widget.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icon, size: 20, color: Colors.white),
      ),
    );
  }
}
