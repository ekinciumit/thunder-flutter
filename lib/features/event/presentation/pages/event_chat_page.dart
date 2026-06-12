import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/event_comments_section.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

/// Event Chat Page
/// 
/// Event yorumları ve sohbeti için ayrı bir sayfa
class EventChatPage extends StatelessWidget {
  final String eventId;
  final String? eventTitle;
  
  const EventChatPage({
    super.key,
    required this.eventId,
    this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    final currentUser = authViewModel.user;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.commentsChat)),
        body: Center(child: Text(l10n.notLoggedIn)),
      );
    }
    
    final userId = currentUser.uid;
    final userName = currentUser.displayName ?? l10n.user;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.commentsChat,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (eventTitle != null)
              Text(
                eventTitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder(
        stream: eventViewModel.getEventStream(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Etkinlik bulunamadı',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
          
          final event = snapshot.data!;
          final isOwner = event.createdBy == userId;
          final isApproved = event.approvedParticipants.contains(userId);
          final isParticipant = event.participants.contains(userId);
          
          // ✅ Katılımcı değilse uyarı göster
          if (!isOwner && !isApproved && !isParticipant) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      l10n.mustJoinToChat,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'Sohbeti görmek için etkinliğe katılmalısınız.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          
          // ✅ Katılımcıysa sohbet göster (tam ekran modu)
          return SafeArea(
            child: EventCommentsSection(
              eventId: eventId,
              userId: userId,
              userName: userName,
              isFullScreen: true, // ✅ Tam ekran modu
            ),
          );
        },
      ),
    );
  }
}
