import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:quedamos/app_colors.dart';
import 'package:quedamos/screens/add_friend_screen.dart';
import 'package:quedamos/screens/main_screen.dart';
import 'package:quedamos/services/friends_service.dart';
import 'package:quedamos/text_styles.dart';
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

    //PAGING CONTROLLER
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  Future<void> _deleteFriend(String friendId) async {
    try {
      await _friendsService.deleteFriend(widget.userID, friendId);
    } catch (e) {
      debugPrint("Error al eliminar amigo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar amigo'),
        ),
      );
    }
  }

    void _refreshPaging() {
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    print("👾 UID del usuario -> ${widget.userID}");
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            "Mis Amigos",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            )
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
          elevation: 0,
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
                height: 45,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final mainState =
                        context.findAncestorStateOfType<MainScreenState>();
                    mainState?.navigateTo(AddFriendsScreen(userID: widget.userID));
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
              // SEGMENTED BUTTON
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Amigos',
                      label: Text('Amigos', style: helpText),
                    ),
                    ButtonSegment(
                      value: 'Solicitudes',
                      label: Text('Solicitudes', style: helpText),
                    ),
                  ],
                  selected: <String>{selectedSegment},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedSegment = newSelection.first;
                      _refreshPaging();
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                    selectedBackgroundColor: primaryLight,
                    foregroundColor: primaryDark,
                    selectedForegroundColor: primaryDark,
                    side: const BorderSide(color: primaryDark, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                selectedSegment == 'Amigos'
                    ? "Todavía no tienes amigos 😢"
                    : "No tienes solicitudes pendientes 😊",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
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
                  mainState?.navigateTo(AddFriendsScreen(userID: widget.userID));
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
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Amigos',
                    label: Text('Amigos', style: helpText),
                  ),
                  ButtonSegment(
                    value: 'Solicitudes',
                    label: Text('Solicitudes', style: helpText),
                  ),
                ],
                selected: <String>{selectedSegment},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    selectedSegment = newSelection.first;
                    _refreshPaging();
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: primaryLight,
                  foregroundColor: primaryDark,
                  selectedForegroundColor: primaryDark,
                  side: const BorderSide(color: primaryDark, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 600,
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
                        final request = items.firstWhere((r) => r['id'] == friendId);
                        await _friendsService.acceptFriendRequest(widget.userID, request);
                      } catch (e) {
                        debugPrint("Error al aceptar solicitud: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al aceptar la solicitud'),
                          ),
                        );
                      }
                    },
                    onReject: (friendId) async {
                      try {
                        await _friendsService.rejectFriendRequest(widget.userID, friendId);
                      } catch (e) {
                        debugPrint("Error al rechazar solicitud: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al rechazar la solicitud'),
                          ),
                        );
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
