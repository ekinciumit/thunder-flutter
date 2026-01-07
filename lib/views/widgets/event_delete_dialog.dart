import 'package:flutter/material.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../l10n/app_localizations.dart';
import 'modern_loading_widget.dart';

/// Dialog for deleting an event
class EventDeleteDialog {
  static void show(
    BuildContext context, {
    required EventEntity event,
    required EventViewModel eventViewModel,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
        ),
        title: Text(
          l10n.deleteEvent,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.deleteEventConfirm,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deleteEventWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Loading göster
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: ModernLoadingWidget(
                    size: 48,
                    showMessage: true,
                    message: 'Siliniyor...',
                  ),
                ),
              );

              try {
                // Event'i sil (Clean Architecture: ViewModel üzerinden, comments otomatik silinir)
                await eventViewModel.deleteEvent(event.id);

                if (!context.mounted) return;

                // Loading dialog'u kapat (eğer açıksa)
                if (navigator.canPop()) {
                  navigator.pop();
                }
                // Confirm dialog'u kapat (eğer açıksa)
                if (navigator.canPop()) {
                  navigator.pop();
                }
                // Event detail sayfasından çık (eğer açıksa)
                if (navigator.canPop()) {
                  navigator.pop();
                }

                if (context.mounted && scaffoldMessenger.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.eventDeleted),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;

                // Loading dialog'u kapat (eğer açıksa)
                if (navigator.canPop()) {
                  navigator.pop();
                }
                // Confirm dialog'u kapat (eğer açıksa)
                if (navigator.canPop()) {
                  navigator.pop();
                }

                if (context.mounted && scaffoldMessenger.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

