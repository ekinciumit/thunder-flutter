import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/modern_components.dart';

/// Chat message edit dialog
/// 
/// Dialog for editing a message
class ChatMessageEditDialog extends StatelessWidget {
  final String initialText;
  final Function(String) onSave;

  const ChatMessageEditDialog({
    super.key,
    required this.initialText,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialText,
    required Function(String) onSave,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => ChatMessageEditDialog(
        initialText: initialText,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialText);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n?.editMessageTitle ?? 'Edit Message'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: l10n?.editMessageHint ?? 'Edit your message...',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n!.cancel),
        ),
        TextButton(
          onPressed: () async {
            if (controller.text.trim().isNotEmpty) {
              final navigator = Navigator.of(context);
              try {
                onSave(controller.text.trim());
                if (context.mounted) {
                  navigator.pop();
                  ModernSnackbar.showSuccess(
                    context,
                    l10n!.messageEdited,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ModernSnackbar.showError(
                    context,
                    l10n!.errorWithDetails(e.toString()),
                  );
                }
              }
            }
          },
          child: Text(l10n!.save),
        ),
      ],
    );
  }
}

