import 'package:flutter/material.dart';
import '../../core/navigation/app_navigation.dart';

/// Chat AppBar widget
/// Displays user info and search action
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String otherUserId;
  final String otherUserName;
  final String? chatId;
  final VoidCallback onUserProfileTap;

  const ChatAppBar({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.chatId,
    required this.onUserProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: onUserProfileTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
              child: Text(
                otherUserName.isNotEmpty 
                    ? otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(otherUserName),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            AppNavigation.toMessageSearch(
              context: context,
              chatId: chatId,
              chatName: otherUserName,
            );
          },
        ),
      ],
    );
  }
}

