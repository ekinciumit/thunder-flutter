import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/modern_components.dart';

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
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n?.deleteMessageTitle ?? 'Delete Message'),
      content: Text(
        l10n?.deleteMessageConfirm ?? 
        'Are you sure you want to delete this message?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
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
                  'Mesaj silindi',
                );
              }
            } catch (e) {
              if (context.mounted) {
                ModernSnackbar.showError(
                  context,
                  'Hata: $e',
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Sil'),
        ),
      ],
    );
  }
}

