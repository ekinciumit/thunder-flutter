import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Mute Duration Enum
enum MuteDuration {
  unlimited, // Süresiz
  hours8,    // 8 saat
  hours24,   // 24 saat
  month1,    // 1 ay
  months6,   // 6 ay
  year1,     // 1 yıl
}

/// Mute Chat Dialog
/// 
/// Sohbeti sessize alma seçenekleri için dialog
class MuteChatDialog extends StatelessWidget {
  final bool isCurrentlyMuted;
  
  const MuteChatDialog({
    super.key,
    this.isCurrentlyMuted = false,
  });

  static Future<MuteDuration?> show({
    required BuildContext context,
    bool isCurrentlyMuted = false,
  }) {
    return showDialog<MuteDuration>(
      context: context,
      builder: (context) => MuteChatDialog(isCurrentlyMuted: isCurrentlyMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        isCurrentlyMuted ? 'Sessize Alma Süresini Değiştir' : 'Sohbeti Sessize Al',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentlyMuted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: Text(
                'Sohbet şu anda sessize alınmış. Süreyi değiştirmek için bir seçenek seçin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          _buildMuteOption(
            context: context,
            theme: theme,
            duration: MuteDuration.unlimited,
            title: 'Süresiz',
            icon: Icons.notifications_off_rounded,
          ),
          const Divider(height: 1),
          _buildMuteOption(
            context: context,
            theme: theme,
            duration: MuteDuration.hours8,
            title: '8 Saat',
            icon: Icons.access_time_rounded,
          ),
          const Divider(height: 1),
          _buildMuteOption(
            context: context,
            theme: theme,
            duration: MuteDuration.hours24,
            title: '24 Saat',
            icon: Icons.schedule_rounded,
          ),
          const Divider(height: 1),
          _buildMuteOption(
            context: context,
            theme: theme,
            duration: MuteDuration.month1,
            title: '1 Ay',
            icon: Icons.calendar_month_rounded,
          ),
          const Divider(height: 1),
          _buildMuteOption(
            context: context,
            theme: theme,
            duration: MuteDuration.months6,
            title: '6 Ay',
            icon: Icons.calendar_today_rounded,
          ),
          const Divider(height: 1),
          _buildMuteOption(
            context: context,
            theme: theme,
            duration: MuteDuration.year1,
            title: '1 Yıl',
            icon: Icons.event_rounded,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildMuteOption({
    required BuildContext context,
    required ThemeData theme,
    required MuteDuration duration,
    required String title,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => Navigator.of(context).pop(duration),
    );
  }

  /// Mute duration'ı DateTime'a çevir
  static DateTime? getMuteUntil(MuteDuration duration) {
    final now = DateTime.now();
    switch (duration) {
      case MuteDuration.unlimited:
        return null; // Süresiz
      case MuteDuration.hours8:
        return now.add(const Duration(hours: 8));
      case MuteDuration.hours24:
        return now.add(const Duration(hours: 24));
      case MuteDuration.month1:
        return now.add(const Duration(days: 30));
      case MuteDuration.months6:
        return now.add(const Duration(days: 180));
      case MuteDuration.year1:
        return now.add(const Duration(days: 365));
    }
  }
}
