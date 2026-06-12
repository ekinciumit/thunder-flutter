import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../features/user/data/mappers/user_mapper.dart';
import '../../../../features/user/domain/entities/user_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/widgets/modern_loading_widget.dart';

/// Widget that displays event participants as chips
class ParticipantChips extends StatelessWidget {
  final List<String> participantUids;
  final EventEntity? event; // Event bilgisi (owner kontrolü için)
  final bool isOwner; // Owner kontrolü
  
  const ParticipantChips({
    super.key,
    required this.participantUids,
    this.event,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentUserId = Provider.of<AuthViewModel>(context, listen: false).user?.uid ?? '';
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    if (participantUids.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.noParticipants,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 10, // ✅ Daha fazla spacing
      runSpacing: 10,
      children: participantUids.map((uid) {
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        return FutureBuilder<UserEntity?>(
          future: authViewModel.fetchUserProfile(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 32, 
                height: 32,
                child: ModernLoadingWidget(size: 32, showMessage: false),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Chip(
                label: Text(
                  snapshot.hasError ? l10n.error : uid.substring(0, 6),
                ),
              );
            }
            // Entity -> Model dönüşümü (UI katmanı hala Model kullanıyor)
            final userEntity = snapshot.data!;
            final user = UserMapper.toModel(userEntity);
            final displayName = user.displayName ?? l10n.user;
            final photoUrl = user.photoUrl ?? '';
            
            // Owner ise ve kendisi değilse remove butonu göster
            final canRemove = isOwner && 
                event != null && 
                uid != currentUserId && 
                uid != event!.createdBy;
            
            return GestureDetector(
              onTap: () {
                AppNavigation.toUserProfile(context: context, userId: user.uid);
              },
              child: Container(
                // ✅ Modern chip tasarımı: Daha büyük, daha güzel border, daha iyi padding
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20), // ✅ Pill-like
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Avatar
                    photoUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 18, // ✅ Daha büyük avatar
                            backgroundImage: NetworkImage(photoUrl),
                          )
                        : CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                    const SizedBox(width: 10),
                    // ✅ Name
                    Text(
                      displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ✅ Remove button (owner için)
                    if (canRemove) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          // Remove participant onay dialogu
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.removeParticipant),
                              content: Text(l10n.removeParticipantConfirm(displayName)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                  ),
                                  child: Text(l10n.remove),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true && event != null) {
                            await eventViewModel.removeParticipant(event!, uid);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$displayName ${l10n.participantRemoved}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

