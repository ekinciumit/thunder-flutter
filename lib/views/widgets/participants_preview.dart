import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/user/data/mappers/user_mapper.dart';
import '../../features/user/domain/entities/user_entity.dart';
import '../../l10n/app_localizations.dart';

/// Participants preview widget - displays pending join requests section
class ParticipantsPreview extends StatelessWidget {
  final EventEntity event;
  final bool isOwner;
  final EventViewModel eventViewModel;
  final AppLocalizations l10n;
  final ThemeData theme;

  const ParticipantsPreview({
    super.key,
    required this.event,
    required this.isOwner,
    required this.eventViewModel,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Sadece owner ise ve pending requests varsa göster
    if (!isOwner || event.pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          key: const ValueKey('pending_requests_section'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.person_add, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                '${l10n.joinRequests} (${event.pendingRequests.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: event.pendingRequests.map((uid) {
            final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
            return FutureBuilder<UserEntity?>(
              future: authViewModel.fetchUserProfile(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return ListTile(title: Text('Kullanıcı: $uid'));
                }
                final userEntity = snapshot.data!;
                final user = UserMapper.toModel(userEntity);
                final displayName = user.displayName ?? 'Kullanıcı';
                final photoUrl = user.photoUrl ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: photoUrl.isNotEmpty
                        ? CircleAvatar(backgroundImage: NetworkImage(photoUrl))
                        : CircleAvatar(child: Text(displayName[0].toUpperCase())),
                    title: Text(displayName),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: l10n.accept,
                          onPressed: () async {
                            final eventEntity = event;
                            await eventViewModel.approveJoinRequest(eventEntity, uid);
                            if (!context.mounted) return;
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: l10n.reject,
                          onPressed: () async {
                            final eventEntity = event;
                            await eventViewModel.rejectJoinRequest(eventEntity, uid);
                            if (!context.mounted) return;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

