import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../../domain/entities/message_entity.dart';
import '../chat_message_options_sheet.dart';
import '../chat_message_edit_dialog.dart';
import '../chat_message_delete_dialog.dart';
import '../reaction_picker.dart';
import '../../../../../core/widgets/modern_components.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/navigation/app_navigation.dart';

/// Helper class for message actions (options, edit, delete, reactions)
class ChatMessageActionsHelper {
  /// Show message options sheet
  static void showMessageOptions({
    required BuildContext context,
    required MessageEntity message,
    required String currentUserId,
    required VoidCallback onReact,
    required VoidCallback onForward,
    required VoidCallback onCopy,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    ChatMessageOptionsSheet.show(
      context: context,
      message: message,
      currentUserId: currentUserId,
      onReact: onReact,
      onForward: onForward,
      onCopy: onCopy,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  /// Edit message
  static void editMessage({
    required BuildContext context,
    required MessageEntity message,
    required ChatViewModel chatViewModel,
  }) {
    ChatMessageEditDialog.show(
      context: context,
      initialText: message.text ?? '',
      onSave: (String newText) async {
        await chatViewModel.editMessage(message.id, newText);
      },
    );
  }

  /// Delete message
  static void deleteMessage({
    required BuildContext context,
    required MessageEntity message,
    required String currentUserId,
    required ChatViewModel chatViewModel,
  }) {
    ChatMessageDeleteDialog.show(
      context: context,
      onDelete: () async {
        await chatViewModel.deleteMessage(message.id, currentUserId);
      },
    );
  }

  /// Handle reaction tap (add/remove reaction)
  static Future<void> handleReactionTap({
    required BuildContext context,
    required MessageEntity message,
    required String currentUserId,
    required ChatViewModel chatViewModel,
  }) async {
    try {
      final userReactions = message.reactions[currentUserId] ?? [];

      // Show reaction picker
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => ReactionPicker(
          onReactionSelected: (emoji) async {
            Navigator.pop(context);
            
            if (userReactions.contains(emoji)) {
              // Remove reaction
              await chatViewModel.removeReaction(message.id, currentUserId, emoji);
            } else {
              // Add reaction
              await chatViewModel.addReaction(message.id, currentUserId, emoji);
            }
          },
          onClose: () => Navigator.pop(context),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.reactionError}: $e')),
      );
    }
  }

  /// Copy message text
  static void copyMessage({
    required BuildContext context,
    required String? text,
  }) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ModernSnackbar.showSuccess(
        context,
        AppLocalizations.of(context)?.messageCopied ?? 'Message copied',
      );
    }
  }

  /// Forward message
  static void forwardMessage({
    required BuildContext context,
    required MessageEntity message,
  }) {
    AppNavigation.toMessageForward(context: context, message: message);
  }
}

