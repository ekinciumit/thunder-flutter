import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/modern_components.dart';

/// Chat message delete confirmation dialog
/// 
/// Dialog for confirming message deletion
class ChatMessageDeleteDialog extends StatelessWidget {
  final VoidCallback onDelete;

  const ChatMessageDeleteDialog({
    super.key,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onDelete,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => ChatMessageDeleteDialog(
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.deleteMessageTitle),
      content: Text(l10n.deleteMessageConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            try {
              onDelete();
              if (context.mounted) {
                navigator.pop();
                ModernSnackbar.showSuccess(
                  context,
                  l10n.messageDeleted,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ModernSnackbar.showError(
                  context,
                  l10n.errorWithDetails(e.toString()),
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

