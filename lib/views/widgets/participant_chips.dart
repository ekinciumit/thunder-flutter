import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../features/user/data/mappers/user_mapper.dart';
import '../../features/user/domain/entities/user_entity.dart';
import '../../l10n/app_localizations.dart';
import '../../core/navigation/app_navigation.dart';
import 'modern_loading_widget.dart';

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
      return Text(l10n.noParticipants);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
              child: Chip(
                avatar: photoUrl.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(photoUrl))
                    : CircleAvatar(child: Text(displayName[0].toUpperCase())),
                label: Text(displayName, overflow: TextOverflow.ellipsis),
                deleteIcon: canRemove
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () async {
                          // Remove participant onay dialogu
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.removeParticipant),
                              content: Text('$displayName etkinlikten çıkarılsın mı?'),
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
                      )
                    : null,
                onDeleted: null, // Chip'in kendi delete mekanizmasını kullanmıyoruz
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

