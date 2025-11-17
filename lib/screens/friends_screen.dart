import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:quedamos/screens/add_friend_screen.dart';
import 'package:quedamos/screens/main_screen.dart';
import 'package:quedamos/services/friends_service.dart';
import '../widgets/friend_list.dart';
import '../widgets/friend_request_list.dart';

class FriendsScreen extends StatefulWidget {
  final String userID;
  const FriendsScreen({super.key, required this.userID});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  String selectedSegment = 'Amigos';
  final FriendsService _friendsService = FriendsService();

  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  Future<void> _deleteFriend(String friendId) async {
    try {
      await _friendsService.deleteFriend(widget.userID, friendId);
    } catch (e) {
      debugPrint("Error al eliminar amigo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar amigo.')),
        );
      }
    }
  }

  void _refreshPaging() {
    _pagingController.refresh();
  }
  // @override
  // void initState() {
  //   super.initState();
  //   FriendsService.syncPendingChanges(widget.userID);
  // }
  
  @override
  void dispose() {
    _pagingController.dispose();
    _friendsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          "Mis amigos",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final mainState =
              context.findAncestorStateOfType<MainScreenState>();
          mainState?.navigateTo(AddFriendsScreen(userID: widget.userID));
        },
        icon: const Icon(Icons.add),
        label: const Text("Nuevo amigo"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: selectedSegment == 'Amigos'
            ? _friendsService.getFriends(widget.userID)
            : _friendsService.getFriendRequests(widget.userID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: "Amigos",
                            label: Text("Amigos",
                                style: Theme.of(context).textTheme.bodyMedium)),
                        ButtonSegment(
                            value: "Solicitudes",
                            label: Text("Solicitudes",
                                style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                      selected: <String>{selectedSegment},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          selectedSegment = newSelection.first;
                          _refreshPaging();
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        selectedBackgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        selectedForegroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      selectedSegment == 'Amigos'
                        ? "Todavía no tienes amigos."
                        : "No tienes solicitudes pendientes.",
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: "Amigos",
                          label: Text("Amigos",
                              style: Theme.of(context).textTheme.bodyMedium)),
                      ButtonSegment(
                          value: "Solicitudes",
                          label: Text("Solicitudes",
                              style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                    selected: <String>{selectedSegment},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        selectedSegment = newSelection.first;
                        _refreshPaging();
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                      selectedBackgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      selectedForegroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: selectedSegment == 'Amigos'
                      ? FriendList(
                          friends: items,
                          showIcons: false,
                          onDelete: _deleteFriend,
                        )
                      : FriendRequestList(
                          friends: items,
                          onAccept: (friendId) async {
                            try {
                              final request =
                                  items.firstWhere((r) => r['id'] == friendId);
                              await _friendsService.acceptFriendRequest(
                                  widget.userID, request);
                            } catch (e) {
                              debugPrint("Error al aceptar solicitud: $e");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Error al aceptar la solicitud.')),
                                );
                              }
                            }
                          },
                          onReject: (friendId) async {
                            try {
                              await _friendsService.rejectFriendRequest(
                                  widget.userID, friendId);
                            } catch (e) {
                              debugPrint("Error al rechazar solicitud: $e");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Error al rechazar la solicitud.')),
                                );
                              }
                            }
                          },
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
