import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/user/domain/entities/user_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../viewmodels/chat_viewmodel.dart';

/// Bottom sheet for adding members to an existing group chat.
class AddGroupMembersSheet extends StatefulWidget {
  final String chatId;
  final Set<String> existingParticipantIds;

  const AddGroupMembersSheet({
    super.key,
    required this.chatId,
    required this.existingParticipantIds,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String chatId,
    required Set<String> existingParticipantIds,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddGroupMembersSheet(
          chatId: chatId,
          existingParticipantIds: existingParticipantIds,
        ),
      ),
    );
  }

  @override
  State<AddGroupMembersSheet> createState() => _AddGroupMembersSheetState();
}

class _AddGroupMembersSheetState extends State<AddGroupMembersSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  bool _isAdding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addMembers() async {
    if (_selectedUserIds.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);

    setState(() => _isAdding = true);

    await chatViewModel.addGroupParticipants(
      chatId: widget.chatId,
      userIds: _selectedUserIds.toList(),
    );

    if (!mounted) return;

    setState(() => _isAdding = false);

    if (chatViewModel.error != null) {
      ModernSnackbar.showError(context, chatViewModel.error!);
      return;
    }

    ModernSnackbar.showSuccess(context, l10n.membersAdded);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTheme.spacingMd),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.addMembers,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    l10n.selectMembersToAdd,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchUserPlaceholder,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<UserEntity>>(
                stream: authViewModel.getAllUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text(l10n.error));
                  }

                  final allUsers = snapshot.data ?? [];
                  final availableUsers = allUsers.where((user) {
                    if (currentUser != null && user.uid == currentUser.uid) {
                      return false;
                    }
                    if (widget.existingParticipantIds.contains(user.uid)) {
                      return false;
                    }

                    if (_searchQuery.trim().isEmpty) return true;

                    final query = _searchQuery.trim().toLowerCase();
                    return (user.displayName ?? '').toLowerCase().contains(query)
                        || (user.username ?? '').toLowerCase().contains(query)
                        || user.email.toLowerCase().contains(query);
                  }).toList();

                  if (availableUsers.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noUsersFound,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      final isSelected = _selectedUserIds.contains(user.uid);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUserIds.add(user.uid);
                            } else {
                              _selectedUserIds.remove(user.uid);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                          backgroundColor: AppColorConfig.primaryColor,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? Text(
                                  (user.displayName ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(user.displayName ?? l10n.unnamed),
                        subtitle: user.username != null ? Text('@${user.username}') : null,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: FilledButton(
                onPressed: _isAdding || _selectedUserIds.isEmpty ? null : _addMembers,
                child: _isAdding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('${l10n.addMembers} (${_selectedUserIds.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
