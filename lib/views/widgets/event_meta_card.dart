import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../l10n/app_localizations.dart';
import 'distance_to_event_widget.dart';
import 'event_participation_button.dart';
import 'app_card.dart';

/// Event meta information card - displays location, description, quota, and participation button
class EventMetaCard extends StatelessWidget {
  final EventEntity event;
  final bool isOwner;
  final bool isFull;
  final bool isParticipant;
  final bool isApproved;
  final bool hasPendingRequest;
  final String userId;
  final EventViewModel eventViewModel;
  final AppLocalizations l10n;
  final ThemeData theme;

  const EventMetaCard({
    super.key,
    required this.event,
    required this.isOwner,
    required this.isFull,
    required this.isParticipant,
    required this.isApproved,
    required this.hasPendingRequest,
    required this.userId,
    required this.eventViewModel,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 28,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      enableGlassmorphism: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.address,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.description,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.people, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '${event.approvedParticipants.length + event.participants.length}/${event.quota}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l10n.quotaFull, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              DistanceToEventWidget(eventLat: event.location.latitude, eventLng: event.location.longitude),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${event.location.latitude},${event.location.longitude}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.directions),
            label: Text(l10n.createRoute),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 16),
          // Katılma durumu widget'ı - Temiz ve anlaşılır UX
          // İptal edilmiş event'lerde katılma butonu gösterilmez
          if (!isOwner && !event.isCancelled)
            EventParticipationButton(
              event: event,
              userId: userId,
              isFull: isFull,
              hasPendingRequest: hasPendingRequest,
              isParticipant: isApproved || isParticipant,
              eventViewModel: eventViewModel,
              l10n: l10n,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

