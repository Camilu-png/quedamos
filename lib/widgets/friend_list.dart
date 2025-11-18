import 'dart:io';
import 'package:flutter/material.dart';

class FriendList extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final bool showIcons;
  final void Function(String friendId)? onDelete;
  final void Function(String friendId)? onAddFriend;

  const FriendList({
    super.key,
    required this.friends,
    this.showIcons = true,
    this.onDelete,
    this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];

        Widget friendCard = InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            color: Theme.of(context).colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend["name"] ?? '', 
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold
                              )),
                        ],
                      ),
                    ),
                  ),

                  if (showIcons)
                    Padding(
                      padding: const EdgeInsets.only(right: 15.0),
                      child: Center(
                        child: _AddFriendButton(
                          onTap: () {
                            if (onAddFriend != null && friend["id"] != null) {
                              onAddFriend!(friend["id"]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Se le ha enviado una solicitud a ${friend["name"]}.'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        if (!showIcons) {
          friendCard = Dismissible(
            key: Key(friend["id"]),
            direction: DismissDirection.endToStart,
            dismissThresholds: const {
              DismissDirection.endToStart: 0.4,
            },
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    title: Text(
                      'Eliminar amigo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    content: Text(
                      '¿Estás seguro de que deseas eliminar a ${friend["name"]} de tus amigos?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          'Cancelar',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          'Eliminar',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 28,
              ),
            ),
            onDismissed: (_) async {
              if (onDelete != null && friend["id"] != null) {
                onDelete!(friend["id"]);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${friend["name"]} fue eliminado.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: friendCard,
          );
        }

        return friendCard;
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
        errorBuilder: (ctx, error, stackTrace) => _buildPlaceholder(ctx, friend),
      );
    }
    
    // Si no hay imagen local pero hay photoUrl, intentar cargar de red
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) => _buildPlaceholder(ctx, friend),
      );
    }
    
    // Si no hay ninguna imagen, mostrar placeholder
    return _buildPlaceholder(context, friend);
  }

  Widget _buildPlaceholder(BuildContext context, Map<String, dynamic> friend) {
    return Container(
      color: (friend["color"] as Color?)?.withValues(alpha: 0.7) ??
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      child: Center(
        child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary, size: 36),
      ),
    );
  }
}

class _AddFriendButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _AddFriendButton({super.key, this.onTap});

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
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _pressed = false);
        });
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _pressed 
            ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7)
            : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.person_add_alt_1_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
