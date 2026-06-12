import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/event_entity.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/user/data/mappers/user_mapper.dart';
import '../../../../features/user/domain/entities/user_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/navigation/app_navigation.dart';

/// Bottom sheet panel for managing event participants
class ParticipantManagementPanel {
  static void show(
    BuildContext context, {
    required EventEntity event,
    required EventViewModel eventViewModel,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.people, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.participantManagement,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.approvedParticipants.length + event.participants.length}/${event.quota} katılımcı',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Onaylanmış katılımcılar
                    if (event.approvedParticipants.isNotEmpty || event.participants.isNotEmpty) ...[
                      Text(
                        'Katılımcılar (${event.approvedParticipants.length + event.participants.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildParticipantList(
                        context,
                        {...event.participants, ...event.approvedParticipants}.toList(),
                        event,
                        eventViewModel,
                        l10n,
                        theme,
                        isOwner: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Bekleyen istekler
                    if (event.pendingRequests.isNotEmpty) ...[
                      Text(
                        'Bekleyen İstekler (${event.pendingRequests.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...event.pendingRequests.map((uid) => _buildPendingRequestCard(
                        context,
                        uid,
                        event,
                        eventViewModel,
                        l10n,
                        theme,
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Katılımcı listesi widget'ı
  static List<Widget> _buildParticipantList(
    BuildContext context,
    List<String> participantUids,
    EventEntity event,
    EventViewModel eventViewModel,
    AppLocalizations l10n,
    ThemeData theme, {
    required bool isOwner,
  }) {
    final currentUserId = Provider.of<AuthViewModel>(context, listen: false).user?.uid ?? '';
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return participantUids.map((uid) {
      return FutureBuilder<UserEntity?>(
        future: authViewModel.fetchUserProfile(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }

          // Entity -> Model dönüşümü (UI katmanı hala Model kullanıyor)
          final userEntity = snapshot.data!;
          final user = UserMapper.toModel(userEntity);
          final displayName = user.displayName ?? l10n.user;
          final photoUrl = user.photoUrl ?? '';
          final email = user.email;
          final isEventOwner = uid == event.createdBy;
          final canRemove = isOwner && uid != currentUserId && !isEventOwner;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty ? Text(displayName[0].toUpperCase()) : null,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isEventOwner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Owner',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(email),
              trailing: canRemove
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: l10n.remove,
                      onPressed: () async {
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

                        if (confirm == true) {
                          final eventEntity = event;
                          await eventViewModel.removeParticipant(eventEntity, uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$displayName ${l10n.participantRemoved}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.of(context).pop(); // Close management panel
                          }
                        }
                      },
                    )
                  : null,
              onTap: () {
                AppNavigation.toUserProfile(context: context, userId: user.uid);
              },
            ),
          );
        },
      );
    }).toList();
  }

  /// Bekleyen istek kartı
  static Widget _buildPendingRequestCard(
    BuildContext context,
    String uid,
    EventEntity event,
    EventViewModel eventViewModel,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return FutureBuilder<UserEntity?>(
      future: authViewModel.fetchUserProfile(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        // Entity -> Model dönüşümü (UI katmanı hala Model kullanıyor)
        final userEntity = snapshot.data!;
        final user = UserMapper.toModel(userEntity);
        final displayName = user.displayName ?? l10n.user;
        final photoUrl = user.photoUrl ?? '';
        final email = user.email;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.orange.withValues(alpha: 0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty ? Text(displayName[0].toUpperCase()) : null,
            ),
            title: Text(
              displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: l10n.accept,
                  onPressed: () async {
                    final eventEntity = event;
                    await eventViewModel.approveJoinRequest(eventEntity, uid);
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close management panel
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: l10n.reject,
                  onPressed: () async {
                    final eventEntity = event;
                    await eventViewModel.rejectJoinRequest(eventEntity, uid);
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close management panel
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              AppNavigation.toUserProfile(context: context, userId: user.uid);
            },
          ),
        );
      },
    );
  }
}

