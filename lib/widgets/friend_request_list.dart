import 'dart:io';
import 'package:flutter/material.dart';

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
          elevation: 1,
          color: Theme.of(context).colorScheme.surface,
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
                    child: _buildFriendImage(context, friend),
                  ),
                ),

                // Nombre del usuario
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(friend["name"] ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold
                              )),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: () {
                                  if (onAccept != null) onAccept!(friend["id"]);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${friend["name"]} ahora es tu amigo 🎉.'),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.check_circle,
                                  size: 20,
                                ),
                                label: Text(
                                  "Aceptar",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.error,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                                onPressed: () {
                                  if (onReject != null) onReject!(friend["id"]);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Rechazaste a ${friend["name"]}.'),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.cancel,
                                  size: 20,
                                ),
                                label: Text(
                                  "Rechazar",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildFriendImage(BuildContext context, Map<String, dynamic> friend) {
    final localPhotoPath = friend["localPhotoPath"] as String?;
    final photoUrl = friend["photoUrl"] as String?;
    
    // Si existe localPhotoPath, usar imagen local
    if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
      final file = File(localPhotoPath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) => _defaultAvatar(ctx, friend),
      );
    }
    
    // Si no hay imagen local pero hay photoUrl, intentar cargar de red
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) => _defaultAvatar(ctx, friend),
      );
    }
    
    // Si no hay ninguna imagen, mostrar placeholder
    return _defaultAvatar(context, friend);
  }

  Widget _defaultAvatar(BuildContext context, Map<String, dynamic> friend) {
    return Container(
      color: (friend["color"] as Color?)?.withValues(alpha: 0.7) ??
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      child: Center(
        child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary, size: 36),
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
