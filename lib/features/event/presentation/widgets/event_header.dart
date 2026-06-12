import 'package:flutter/material.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../features/chat/presentation/widgets/full_screen_media_viewer.dart';

/// Event header widget - displays cover photo, title, category, and date
class EventHeader extends StatelessWidget {
  final EventEntity event;
  final ThemeData theme;

  const EventHeader({
    super.key,
    required this.event,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => openFullScreenMedia(
          context,
          mediaUrl: event.coverPhotoUrl!,
          isVideo: false,
          title: event.title,
          heroTag: 'event_cover_${event.id}',
        ),
        child: Stack(
          children: [
            Hero(
              tag: 'event_cover_${event.id}',
              child: Image.network(
                event.coverPhotoUrl!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((0.45 * 255).toInt()),
                    Colors.transparent,
                    Colors.black.withAlpha((0.25 * 255).toInt()),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          event.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today, color: theme.colorScheme.onPrimary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${event.datetime.day}.${event.datetime.month}.${event.datetime.year} - ${event.datetime.hour.toString().padLeft(2, '0')}:${event.datetime.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 180,
        color: theme.colorScheme.primary.withAlpha(30),
        child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
      );
    }
  }
}

