import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../domain/entities/chat_entity.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/user/domain/entities/user_entity.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/add_group_members_sheet.dart';

/// Group Chat Info Page
/// 
/// Grup sohbeti bilgileri, katılımcılar vs.
class GroupChatInfoPage extends StatefulWidget {
  final String chatId;
  
  const GroupChatInfoPage({
    super.key,
    required this.chatId,
  });

  @override
  State<GroupChatInfoPage> createState() => _GroupChatInfoPageState();
}

class _GroupChatInfoPageState extends State<GroupChatInfoPage> {
  ChatViewModel? _chatViewModel;
  Stream<ChatEntity?>? _chatStream;
  ChatEntity? _initialChat;
  List<UserEntity> _participantUsers = [];
  bool _loadingParticipants = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadParticipants());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatViewModel ??= Provider.of<ChatViewModel>(context, listen: false);
    _chatStream ??= _chatViewModel!.getChatStream(widget.chatId);
    _initialChat ??= _chatViewModel!.getCachedChat(widget.chatId);
  }

  Future<void> _loadParticipants() async {
    if (!mounted) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final chat = chatViewModel.getCachedChat(widget.chatId)
        ?? await chatViewModel.getChatById(widget.chatId);

    if (!mounted || chat == null) {
      if (mounted) setState(() => _loadingParticipants = false);
      return;
    }

    final users = <UserEntity>[];
    for (final userId in chat.participants) {
      final fromDetails = chat.participantDetails[userId];
      if (fromDetails != null) {
        users.add(UserEntity(
          uid: fromDetails.userId,
          displayName: fromDetails.name,
          photoUrl: fromDetails.photoUrl,
          email: '',
        ));
        continue;
      }

      final profile = await authViewModel.fetchUserProfile(userId);
      if (profile != null) {
        users.add(profile);
      }
    }

    if (!mounted) return;
    setState(() {
      _participantUsers = users;
      _loadingParticipants = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.chat)),
        body: Center(child: Text(l10n.notLoggedIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupInfo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<ChatEntity?>(
        stream: _chatStream,
        initialData: _initialChat,
        builder: (context, snapshot) {
          final chat = snapshot.data;
          if (chat == null && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chat == null) {
            return Center(child: Text(l10n.groupChatNotFound));
          }
          final groupPhotoUrl = chat.photoUrl;
          final description = chat.description;
          final participants = chat.participants;

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              // ✅ Grup Fotoğrafı ve İsmi
              Center(
                child: Column(
                  children: [
                    // ✅ Grup Fotoğrafı - Düzenlenebilir (sadece yöneticiler)
                    StreamBuilder<ChatEntity?>(
                      stream: _chatStream,
                      initialData: chat,
                      builder: (context, snapshot) {
                        final currentChat = snapshot.data ?? chat;
                        final canEdit = currentChat.canEditGroup(currentUser.uid);
                        final currentPhotoUrl = currentChat.photoUrl ?? groupPhotoUrl;
                        
                        return GestureDetector(
                          onTap: canEdit ? () => _showEditPhotoDialog(context, currentChat, chatViewModel) : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: currentPhotoUrl != null && currentPhotoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(currentPhotoUrl)
                                    : null,
                                backgroundColor: currentPhotoUrl == null || currentPhotoUrl.isEmpty
                                    ? AppColorConfig.primaryColor
                                    : null,
                                child: currentPhotoUrl == null || currentPhotoUrl.isEmpty
                                    ? Icon(Icons.group_rounded, size: 60, color: Colors.white)
                                    : null,
                              ),
                              if (canEdit)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    // ✅ Grup Adı - Düzenlenebilir (sadece yöneticiler)
                    StreamBuilder<ChatEntity?>(
                      stream: _chatStream,
                      initialData: chat,
                      builder: (context, snapshot) {
                        final currentChat = snapshot.data ?? chat;
                        final canEdit = currentChat.canEditGroup(currentUser.uid);
                        
                        return GestureDetector(
                          onTap: canEdit ? () => _showEditGroupNameDialog(context, currentChat, chatViewModel) : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  currentChat.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (canEdit) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    // ✅ Açıklama - Düzenlenebilir (sadece yöneticiler)
                    StreamBuilder<ChatEntity?>(
                      stream: _chatStream,
                      initialData: chat,
                      builder: (context, snapshot) {
                        final currentChat = snapshot.data ?? chat;
                        final canEdit = currentChat.canEditGroup(currentUser.uid);
                        final currentDescription = currentChat.description ?? description;
                        
                        return GestureDetector(
                          onTap: canEdit ? () => _showEditDescriptionDialog(context, currentChat, chatViewModel) : null,
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    currentDescription ?? l10n.noDescription,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: currentDescription != null
                                          ? theme.colorScheme.onSurfaceVariant
                                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      fontStyle: currentDescription == null ? FontStyle.italic : FontStyle.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (canEdit) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
              
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.participantsCount(participants.length),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (chat.canManageMembers(currentUser.uid))
                    IconButton(
                      icon: const Icon(Icons.person_add_rounded),
                      tooltip: l10n.addMembers,
                      onPressed: () => _showAddMembersSheet(context, chat),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // ✅ Katılımcı Listesi
              if (_loadingParticipants)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingXl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_participantUsers.isEmpty)
                Center(
                  child: Text(
                    l10n.noParticipantsFound,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _participantUsers.length,
                    itemBuilder: (context, index) {
                      final user = _participantUsers[index];
                      final isCurrentUser = user.uid == currentUser.uid;
                      final isCreator = chat.createdBy == user.uid;
                      final isAdmin = chat.isAdmin(user.uid);
                      final canManageAdmins = chat.canManageAdmins(currentUser.uid);
                      final canManageMembers = chat.canManageMembers(currentUser.uid);
                      final showMemberMenu = !isCurrentUser
                          && !isCreator
                          && (canManageMembers || canManageAdmins);

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                          backgroundColor: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? AppColorConfig.primaryColor
                              : null,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? Text(
                                  (user.displayName ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(user.displayName ?? l10n.unnamed),
                            ),
                            if (isCreator)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Text(
                                  l10n.creator,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (isAdmin && !isCreator)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Text(
                                  l10n.admin,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onTertiaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (isCurrentUser)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Text(
                                  l10n.you,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: user.username != null
                            ? Text('@${user.username}')
                            : null,
                        trailing: showMemberMenu
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
                                  
                                  if (value == 'remove_member') {
                                    await _confirmRemoveMember(
                                      context,
                                      chat,
                                      user,
                                      chatViewModel,
                                    );
                                  } else if (value == 'make_admin') {
                                    await chatViewModel.addAdmin(
                                      chatId: widget.chatId,
                                      userId: user.uid,
                                    );
                                    if (context.mounted) {
                                      ModernSnackbar.showSuccess(context, l10n.adminPromoted(user.displayName ?? l10n.unnamed));
                                    }
                                  } else if (value == 'remove_admin') {
                                    await chatViewModel.removeAdmin(
                                      chatId: widget.chatId,
                                      userId: user.uid,
                                    );
                                    if (context.mounted) {
                                      ModernSnackbar.showSuccess(context, l10n.adminDemoted(user.displayName ?? l10n.unnamed));
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (canManageMembers)
                                    PopupMenuItem(
                                      value: 'remove_member',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_remove_outlined, size: 20, color: theme.colorScheme.error),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.removeMember,
                                            style: TextStyle(color: theme.colorScheme.error),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (canManageAdmins)
                                    if (isAdmin)
                                      PopupMenuItem(
                                        value: 'remove_admin',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.admin_panel_settings_outlined, size: 20),
                                            const SizedBox(width: 8),
                                            Text(l10n.demoteAdmin),
                                          ],
                                        ),
                                      )
                                    else
                                      PopupMenuItem(
                                        value: 'make_admin',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.admin_panel_settings, size: 20),
                                            const SizedBox(width: 8),
                                            Text(l10n.promoteAdmin),
                                          ],
                                        ),
                                      ),
                                ],
                              )
                            : null,
                        onTap: () {
                          if (!isCurrentUser) {
                            context.push('/user/${user.uid}');
                          }
                        },
                      );
                    },
                  ),
              if (!chat.isCreator(currentUser.uid)) ...[
                const SizedBox(height: AppTheme.spacingXl),
                OutlinedButton.icon(
                  onPressed: () => _confirmLeaveGroup(context, chat),
                  icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                  label: Text(
                    l10n.leaveGroup,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddMembersSheet(BuildContext context, ChatEntity chat) async {
    final added = await AddGroupMembersSheet.show(
      context,
      chatId: widget.chatId,
      existingParticipantIds: chat.participants.toSet(),
    );

    if (added == true && mounted) {
      setState(() {
        _loadingParticipants = true;
        _participantUsers = [];
      });
      await _loadParticipants();
    }
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    ChatEntity chat,
    UserEntity user,
    ChatViewModel chatViewModel,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final displayName = user.displayName ?? l10n.unnamed;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeMember),
        content: Text(l10n.removeMemberConfirm(displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await chatViewModel.removeGroupParticipant(
      chatId: widget.chatId,
      userId: user.uid,
    );

    if (!mounted) return;

    if (chatViewModel.error != null) {
      ModernSnackbar.showError(context, chatViewModel.error!);
      return;
    }

    ModernSnackbar.showSuccess(context, l10n.memberRemoved);
    setState(() {
      _loadingParticipants = true;
      _participantUsers = [];
    });
    await _loadParticipants();
  }

  Future<void> _confirmLeaveGroup(BuildContext context, ChatEntity chat) async {
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final currentUser = authViewModel.user;

    if (currentUser == null) return;

    if (chat.isCreator(currentUser.uid)) {
      ModernSnackbar.showError(context, l10n.creatorCannotLeave);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.leaveGroup),
        content: Text(l10n.leaveGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.leaveGroup),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await chatViewModel.removeGroupParticipant(
      chatId: widget.chatId,
      userId: currentUser.uid,
    );

    if (!mounted) return;

    if (chatViewModel.error != null) {
      ModernSnackbar.showError(context, chatViewModel.error!);
      return;
    }

    ModernSnackbar.showSuccess(context, l10n.leftGroup);
    if (context.mounted) {
      context.go('/chats');
    }
  }

  /// Grup fotoğrafını düzenle
  Future<void> _showEditPhotoDialog(
    BuildContext context,
    ChatEntity chat,
    ChatViewModel chatViewModel,
  ) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Fotoğraf kaynağı seç
    final source = await ModernDialog.showImageSource(
      context: context,
      title: l10n.selectPhoto,
    );
    
    if (source == null || !mounted) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    
    if (pickedFile == null || !mounted) return;
    
    // Kırpma işlemi
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n.cropPhoto,
          toolbarColor: theme.colorScheme.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: l10n.cropPhoto,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
      ],
    );
    
    if (croppedFile == null || !mounted) return;
    
    // Fotoğrafı yükle
    try {
      final photoUrl = await authViewModel.uploadProfilePhoto(croppedFile.path);
      
      if (photoUrl != null && mounted) {
        // Grup bilgilerini güncelle
        await chatViewModel.updateGroupInfo(
          chatId: widget.chatId,
          photoUrl: photoUrl,
        );
        
        if (!mounted) return;
        try {
          // ignore: use_build_context_synchronously
          ModernSnackbar.showSuccess(context, l10n.groupPhotoUpdated);
        } catch (_) {
          // Context artık geçerli değil, sessizce geç
        }
      }
    } catch (e) {
      if (!mounted) return;
      try {
        // ignore: use_build_context_synchronously
        ModernSnackbar.showError(context, l10n.groupPhotoUploadError(e.toString()));
      } catch (_) {
        // Context artık geçerli değil, sessizce geç
      }
    }
  }

  /// Grup adını düzenle
  Future<void> _showEditGroupNameDialog(
    BuildContext context,
    ChatEntity chat,
    ChatViewModel chatViewModel,
  ) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    
    // Controller'ı dialog dışında oluştur
    final nameController = TextEditingController(text: chat.name);
    
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.editGroupName),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.groupName,
                hintText: l10n.groupNameHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              autofocus: true,
              maxLength: 50,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.of(dialogContext).pop(newName);
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      );
      
      if (result != null && result.isNotEmpty && mounted) {
        try {
          await chatViewModel.updateGroupInfo(
            chatId: widget.chatId,
            name: result,
          );
          
          if (!mounted) return;
          try {
            // ignore: use_build_context_synchronously
            ModernSnackbar.showSuccess(context, l10n.groupNameUpdated);
          } catch (_) {
            // Context artık geçerli değil, sessizce geç
          }
        } catch (e) {
          if (!mounted) return;
          try {
            // ignore: use_build_context_synchronously
            ModernSnackbar.showError(context, l10n.groupNameUpdateError(e.toString()));
          } catch (_) {
            // Context artık geçerli değil, sessizce geç
          }
        }
      }
    } finally {
      // Controller'ı her durumda dispose et
      nameController.dispose();
    }
  }

  /// Grup açıklamasını düzenle
  Future<void> _showEditDescriptionDialog(
    BuildContext context,
    ChatEntity chat,
    ChatViewModel chatViewModel,
  ) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    
    // Controller'ı dialog dışında oluştur
    final descriptionController = TextEditingController(text: chat.description ?? '');
    
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.editDescription),
            content: TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.eventDescription,
                hintText: l10n.descriptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              autofocus: true,
              maxLines: 3,
              maxLength: 200,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final description = descriptionController.text.trim();
                  Navigator.of(dialogContext).pop(description);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      );
      
      if (result != null && mounted) {
        try {
          await chatViewModel.updateGroupInfo(
            chatId: widget.chatId,
            description: result.isEmpty ? null : result,
          );
          
          if (!mounted) return;
          try {
            // ignore: use_build_context_synchronously
            ModernSnackbar.showSuccess(context, l10n.descriptionUpdated);
          } catch (_) {
            // Context artık geçerli değil, sessizce geç
          }
        } catch (e) {
          if (!mounted) return;
          try {
            // ignore: use_build_context_synchronously
            ModernSnackbar.showError(context, l10n.descriptionUpdateError(e.toString()));
          } catch (_) {
            // Context artık geçerli değil, sessizce geç
          }
        }
      }
    } finally {
      // Controller'ı her durumda dispose et
      descriptionController.dispose();
    }
  }
}
