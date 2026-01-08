import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/modern_components.dart';

/// Chat message options bottom sheet
/// 
/// Shows options for a message: React, Forward, Copy, Edit, Delete
class ChatMessageOptionsSheet extends StatelessWidget {
  final MessageEntity message;
  final String currentUserId;
  final VoidCallback onReact;
  final VoidCallback onForward;
  final VoidCallback onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatMessageOptionsSheet({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onReact,
    required this.onForward,
    required this.onCopy,
    this.onEdit,
    this.onDelete,
  });

  static void show({
    required BuildContext context,
    required MessageEntity message,
    required String currentUserId,
    required VoidCallback onReact,
    required VoidCallback onForward,
    required VoidCallback onCopy,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    GlassModalBottomSheet.show(
      context: context,
      padding: EdgeInsets.zero,
      child: ChatMessageOptionsSheet(
        message: message,
        currentUserId: currentUserId,
        onReact: onReact,
        onForward: onForward,
        onCopy: onCopy,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // React
        ListTile(
          leading: const Icon(
            Icons.emoji_emotions,
            color: Colors.orange,
          ),
          title: Text(
            l10n?.react ?? 'React',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            onReact();
          },
        ),
        // Forward
        ListTile(
          leading: const Icon(
            Icons.forward,
            color: Colors.deepPurple,
          ),
          title: Text(
            l10n?.forward ?? 'Forward',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            onForward();
          },
        ),
        // Copy
        ListTile(
          leading: const Icon(
            Icons.copy,
            color: Colors.blue,
          ),
          title: Text(
            l10n?.copy ?? 'Copy',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            onCopy();
          },
        ),
        // Edit & Delete (only for own messages)
        if (message.senderId == currentUserId) ...[
          if (onEdit != null)
            ListTile(
              leading: const Icon(
                Icons.edit,
                color: Colors.orange,
              ),
              title: Text(
                l10n?.edit ?? 'Edit',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onEdit!();
              },
            ),
          if (onDelete != null)
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: Text(
                l10n?.delete ?? 'Delete',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete!();
              },
            ),
        ],
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }
}

