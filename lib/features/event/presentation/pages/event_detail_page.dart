import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/event_entity.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../core/widgets/app_gradient_container.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/modern_loading_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/participant_chips.dart';
import '../widgets/participant_management_panel.dart';
import '../widgets/event_edit_dialog.dart';
import '../widgets/event_cancel_dialog.dart';
import '../widgets/event_delete_dialog.dart';
import '../widgets/event_header.dart';
import '../widgets/event_meta_card.dart';
import '../widgets/participants_preview.dart';

class EventDetailPage extends StatefulWidget {
  final EventEntity? event; // Optional for route-based navigation
  final String? eventId; // Optional for direct event passing
  
  const EventDetailPage({
    super.key,
    this.event,
    this.eventId,
  }) : assert(event != null || eventId != null, 'Either event or eventId must be provided');

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  EventEntity? event;

  @override
  void initState() {
    super.initState();
    event = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final eventViewModel = Provider.of<EventViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userId = authViewModel.user?.uid ?? '';
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Get eventId from either event or eventId parameter
    final targetEventId = widget.eventId ?? event?.id;
    if (targetEventId == null) {
      return AppGradientContainer(
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.error)),
          body: Center(child: Text(l10n.noData)),
        ),
      );
    }

    // Event'i real-time dinle (Clean Architecture: ViewModel üzerinden)
    // ViewModel Entity döndürüyor, UI Model kullanıyor - dönüşüm yapıyoruz
    return StreamBuilder<EventEntity?>(
      stream: eventViewModel.getEventStream(targetEventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppGradientContainer(
            child: Scaffold(
              appBar: AppBar(title: Text(l10n.loading)),
              body: Center(child: ModernLoadingWidget(message: l10n.loading)),
            ),
          );
        }

        // Event silinmişse kontrol et (Clean Architecture: EventEntity? dönüyor)
        final currentEvent = snapshot.data;
          if (currentEvent == null) {
          // Event silinmiş, güvenli bir şekilde geri dön
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              if (mounted && ScaffoldMessenger.of(context).mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.eventDeleted),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          });
          return AppGradientContainer(
            child: Scaffold(
              appBar: AppBar(title: Text(l10n.eventDeleted)),
              body: Center(child: ModernLoadingWidget(message: l10n.loading)),
            ),
          );
        }
        
        final isParticipant = currentEvent.participants.contains(userId);
        final isFull = (currentEvent.approvedParticipants.length + currentEvent.participants.length) >= currentEvent.quota;
        final isOwner = currentEvent.createdBy == userId;
        final isApproved = currentEvent.approvedParticipants.contains(userId);
        final hasPendingRequest = currentEvent.pendingRequests.contains(userId);

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(currentEvent.title),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (isOwner) ...[
              // Katılma istekleri bildirimi
              if (currentEvent.pendingRequests.isNotEmpty)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      tooltip: 'Katılma İstekleri Var',
                      onPressed: null, // Sadece görsel bildirim için
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          currentEvent.pendingRequests.length > 9 
                              ? '9+' 
                              : currentEvent.pendingRequests.length.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              if (!currentEvent.isCancelled) ...[
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: 'Etkinliği İptal Et',
                  onPressed: () => EventCancelDialog.show(
                      context,
                      event: currentEvent,
                      eventViewModel: eventViewModel,
                    ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Etkinliği Düzenle',
                  onPressed: () => EventEditDialog.show(
                      context,
                      event: currentEvent,
                      eventViewModel: eventViewModel,
                    ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Etkinliği Sil',
                  onPressed: () => EventDeleteDialog.show(
                      context,
                      event: currentEvent,
                      eventViewModel: eventViewModel,
                    ),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Etkinliği Sil',
                  onPressed: () => EventDeleteDialog.show(
                      context,
                      event: currentEvent,
                      eventViewModel: eventViewModel,
                    ),
                ),
              ],
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // İptal edilmiş event uyarısı
              if (currentEvent.isCancelled) ...[
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.orange[700], size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Etkinlik İptal Edildi',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (currentEvent.cancellationReason != null && currentEvent.cancellationReason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Sebep: ${currentEvent.cancellationReason}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                      if (currentEvent.cancelledAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'İptal Tarihi: ${currentEvent.cancelledAt!.day}.${currentEvent.cancelledAt!.month}.${currentEvent.cancelledAt!.year} ${currentEvent.cancelledAt!.hour.toString().padLeft(2, '0')}:${currentEvent.cancelledAt!.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              // Event header - cover photo, title, category, date
              EventHeader(event: currentEvent, theme: theme),
              const SizedBox(height: 16),
              // Event meta information - location, description, quota, participation button
              EventMetaCard(
                event: currentEvent,
                isOwner: isOwner,
                isFull: isFull,
                isParticipant: isParticipant,
                isApproved: isApproved,
                hasPendingRequest: hasPendingRequest,
                userId: userId,
                eventViewModel: eventViewModel,
                l10n: l10n,
                theme: theme,
              ),
              // ✅ Başlık çerçevenin kenarına yakın - Card border'ının tam üstünde
              AppCard(
                borderRadius: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Başlık - Card'ın üst kenarına yakın (minimal top padding)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), // ✅ Minimal top padding
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            color: theme.colorScheme.primary,
                            size: 20, // ✅ Daha küçük (barida hotel icon ile aynı)
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.participantsLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15, // ✅ barida hotel ile aynı boyut
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ✅ Katılımcı sayısı - inline (badge yerine)
                          Text(
                            '${currentEvent.approvedParticipants.length + currentEvent.participants.length}/${currentEvent.quota}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15, // ✅ Aynı boyut
                            ),
                          ),
                          if (isOwner) ...[
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.settings_rounded,
                                size: 20, // ✅ Daha küçük
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              tooltip: l10n.participantManagement,
                              padding: EdgeInsets.zero, // ✅ Daha kompakt
                              constraints: const BoxConstraints(), // ✅ Daha kompakt
                              onPressed: () {
                                ParticipantManagementPanel.show(
                                  context,
                                  event: currentEvent,
                                  eventViewModel: eventViewModel,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    // ✅ İçerik - Normal padding
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // ✅ Normal padding (üst padding azaltıldı)
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ParticipantChips(
                            participantUids: <String>{
                              ...currentEvent.participants,
                              ...currentEvent.approvedParticipants
                            }.toList(), // Duplicate'leri kaldır
                            event: currentEvent,
                            isOwner: isOwner,
                          ),
                          // Pending join requests preview
                          ParticipantsPreview(
                            event: currentEvent,
                            isOwner: isOwner,
                            eventViewModel: eventViewModel,
                            l10n: l10n,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ Modern Comments/Chat Section - "Grup Sohbetine Git" Butonu
              AppCard(
                borderRadius: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Başlık - Card'ın üst kenarına yakın (minimal top padding)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), // ✅ Minimal top padding
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 20, // ✅ Participants icon ile aynı boyut
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.commentsChat,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15, // ✅ Participants ile aynı boyut
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✅ İçerik - "Grup Sohbetine Git" Butonu
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // ✅ Normal padding
                      child: isOwner || isApproved || isParticipant
                          ? SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  context.push(
                                    '/event/${currentEvent.id}/chat?title=${Uri.encodeComponent(currentEvent.title)}',
                                  );
                                },
                                icon: const Icon(Icons.group_rounded, size: 20),
                                label: Text(l10n.goToGroupChat),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingLg,
                                    vertical: AppTheme.spacingMd,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  Flexible(
                                    child: Text(
                                      l10n.mustJoinToChat,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
