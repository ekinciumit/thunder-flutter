import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../core/theme/app_color_config.dart';

/// Modern glassmorphism event card widget
/// Used in event list views
class EventCard extends StatelessWidget {
  final EventEntity event;
  final double? distanceKm;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    this.distanceKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          // iOS 16 tarzı güçlü blur efekti
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              // iOS 16 glassmorphism - çok şeffaf, gerçekten camsı
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05) // Çok şeffaf beyaz (dark mode)
                  : Colors.white.withValues(alpha: 0.15), // Light mode için biraz daha opak
              borderRadius: BorderRadius.circular(22),
              // İnce, şeffaf border - iOS 16 tarzı
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15) // Çok şeffaf border
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.0, // Daha ince border
              ),
              // Subtle shadow - sadece derinlik için
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: event.coverPhotoUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: isDark
                                ? theme.colorScheme.surface.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.7),
                              strokeWidth: 2.5,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: isDark
                                ? theme.colorScheme.surface.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: isDark
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? theme.colorScheme.onSurface
                                        : Colors.white.withValues(alpha: 0.95),
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColorConfig.primaryColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColorConfig.primaryColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  event.category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? theme.colorScheme.onSurface
                                        : Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : Colors.white.withValues(alpha: 0.82),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${event.datetime.day}.${event.datetime.month}.${event.datetime.year} - ${event.datetime.hour.toString().padLeft(2, '0')}:${event.datetime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.white.withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.people_rounded,
                                size: 18,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${event.participants.length}/${event.quota}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : Colors.white.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.white.withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distanceKm != null) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColorConfig.primaryColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColorConfig.primaryColor.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${distanceKm!.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? theme.colorScheme.onSurface
                                          : Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

