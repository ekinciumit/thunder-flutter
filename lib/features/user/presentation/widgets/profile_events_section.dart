import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../features/event/domain/entities/event_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

/// Profile events section widget
/// Displays a list of user's events
class ProfileEventsSection extends StatelessWidget {
  final Stream<List<EventEntity>> eventsStream;
  final ThemeData theme;
  final AppLocalizations l10n;

  const ProfileEventsSection({
    super.key,
    required this.eventsStream,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventEntity>>(
      stream: eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingXl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: AppTheme.alphaMedium / 255.0,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  l10n.noData,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMd),
          itemBuilder: (context, index) {
            final event = events[index];
            return GestureDetector(
              onTap: () {
                AppNavigation.toEventDetail(context: context, event: event);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: theme.brightness == Brightness.dark ? 10 : 0,
                    sigmaY: theme.brightness == Brightness.dark ? 10 : 0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surface.withValues(alpha: 0.1)
                          : theme.colorScheme.surface.withValues(alpha: 0.9),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.outline.withValues(alpha: 0.2)
                            : theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1.0,
                      ),
                      boxShadow: theme.brightness == Brightness.dark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppTheme.radiusLg),
                            bottomRight: Radius.circular(AppTheme.radiusLg),
                          ),
                          child: event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: event.coverPhotoUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                  memCacheWidth: 600,
                                  memCacheHeight: 400,
                                  placeholder: (context, url) => Container(
                                    height: 200,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    height: 200,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.event_note_rounded,
                                      size: 48,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.event_note_rounded,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
