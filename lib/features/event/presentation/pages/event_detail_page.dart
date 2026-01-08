import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/event_entity.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../views/widgets/app_gradient_container.dart';
import '../../../../views/widgets/app_card.dart';
import '../../../../views/widgets/modern_loading_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/event_comments_section.dart';
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
    final userName = authViewModel.user?.displayName ?? l10n.user;
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
              AppCard(
                borderRadius: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(l10n.participantsLabel, style: theme.textTheme.titleMedium),
                          if (isOwner) ...[
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.settings, size: 20),
                              tooltip: l10n.participantManagement,
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
                      const SizedBox(height: 8),
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
              ),
              AppCard(
                borderRadius: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.commentsChat, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (isOwner || isApproved || isParticipant)
                        EventCommentsSection(eventId: currentEvent.id, userId: userId, userName: userName)
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha((0.08 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.mustJoinToChat,
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
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
