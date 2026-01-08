import 'package:flutter/material.dart';
import '../../domain/entities/event_entity.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_service.dart';
import '../../../../views/widgets/modern_loading_widget.dart';

/// Dialog for canceling an event
class EventCancelDialog {
  static void show(
    BuildContext context, {
    required EventEntity event,
    required EventViewModel eventViewModel,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reasonController = TextEditingController();
    bool isValid = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.1),
                          Colors.red.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cancel_outlined,
                            size: 48,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Etkinliği İptal Et',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bu etkinliği iptal etmek istediğinizden emin misiniz? Tüm katılımcılara bildirim gönderilecektir.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'İptal Sebebi *',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: reasonController,
                          onChanged: (value) {
                            setDialogState(() {
                              isValid = value.trim().isNotEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Örn: Hava durumu, kişisel nedenler...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest,
                            prefixIcon: const Icon(Icons.edit_note, color: Colors.orange),
                            suffixIcon: reasonController.text.length > 180
                                ? Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange[700],
                                    size: 20,
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          maxLines: 3,
                          maxLength: 200,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: isValid
                                ? () async {
                                    final navigator = Navigator.of(dialogContext);
                                    final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
                                    final userService = UserService();

                                    // Loading göster
                                    showDialog(
                                      context: dialogContext,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(
                                        child: ModernLoadingWidget(
                                          size: 48,
                                          showMessage: true,
                                          message: 'İptal ediliyor...',
                                        ),
                                      ),
                                    );

                                    try {
                                      // Event'i iptal et
                                      await eventViewModel.cancelEvent(
                                        event.id,
                                        reasonController.text.trim(),
                                      );

                                      // Tüm katılımcılara bildirim gönder
                                      final allParticipants = {
                                        ...event.participants,
                                        ...event.approvedParticipants,
                                      }.toList();

                                      if (allParticipants.isNotEmpty) {
                                        await userService.notifyEventCancelled(
                                          participantIds: allParticipants,
                                          eventId: event.id,
                                          eventTitle: event.title,
                                          reason: reasonController.text.trim(),
                                        );
                                      }

                                      if (!dialogContext.mounted) return;

                                      // Loading dialog'u kapat
                                      if (navigator.canPop()) {
                                        navigator.pop();
                                      }
                                      // Cancel dialog'u kapat
                                      if (navigator.canPop()) {
                                        navigator.pop();
                                      }

                                      if (dialogContext.mounted && scaffoldMessenger.mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Etkinlik iptal edildi. Tüm katılımcılara bildirim gönderildi.',
                                            ),
                                            backgroundColor: Colors.orange,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (!dialogContext.mounted) return;

                                      // Loading dialog'u kapat
                                      if (navigator.canPop()) {
                                        navigator.pop();
                                      }

                                      if (dialogContext.mounted && scaffoldMessenger.mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Hata: $e'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'İptal Et',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

