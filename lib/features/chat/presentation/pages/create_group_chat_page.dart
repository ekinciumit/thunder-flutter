import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../viewmodels/chat_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/user/domain/entities/user_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/navigation/app_navigation.dart';

/// Create Group Chat Page
/// 
/// Kullanıcıların grup sohbeti oluşturması için sayfa
class CreateGroupChatPage extends StatefulWidget {
  const CreateGroupChatPage({super.key});

  @override
  State<CreateGroupChatPage> createState() => _CreateGroupChatPageState();
}

class _CreateGroupChatPageState extends State<CreateGroupChatPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  File? _selectedImage;
  String? _uploadedPhotoUrl;
  bool _isUploading = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Fotoğraf seç (galeri veya kamera)
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedPhotoUrl = null; // Yeni fotoğraf seçildi, eski URL'i temizle
        });
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          AppLocalizations.of(context)!.filePickError(e.toString()),
        );
      }
    }
  }

  /// Fotoğrafı yükle ve URL'ini al
  Future<String?> _uploadPhoto() async {
    if (_selectedImage == null) return null;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    if (currentUser == null) return null;

    setState(() => _isUploading = true);

    try {
      final photoUrl = await authViewModel.uploadProfilePhoto(_selectedImage!.path);
      setState(() {
        _uploadedPhotoUrl = photoUrl;
        _isUploading = false;
      });
      return photoUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ModernSnackbar.showError(
          context,
          AppLocalizations.of(context)!.groupPhotoUploadError(e.toString()),
        );
      }
      return null;
    }
  }

  /// Grup sohbeti oluştur
  Future<void> _createGroupChat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserIds.isEmpty) {
      ModernSnackbar.showError(
        context,
        AppLocalizations.of(context)!.selectAtLeastOneParticipant,
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      final currentUser = authViewModel.user;

      if (currentUser == null) {
        ModernSnackbar.showError(
          context,
          AppLocalizations.of(context)!.userInfoNotFound,
        );
        return;
      }

      // Fotoğraf varsa yükle
      String? photoUrl = _uploadedPhotoUrl;
      if (_selectedImage != null && photoUrl == null) {
        photoUrl = await _uploadPhoto();
      }

      // Grup sohbeti oluştur
      final participants = [currentUser.uid, ..._selectedUserIds];
      final chat = await chatViewModel.createGroupChat(
        name: _nameController.text.trim(),
        createdBy: currentUser.uid,
        participants: participants,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        photoUrl: photoUrl,
      );

      if (chat != null && mounted) {
        ModernSnackbar.showSuccess(
          context,
          AppLocalizations.of(context)!.groupChatCreated,
        );
        // Sohbet sayfasına git
        context.pop();
        // Grup sohbetine yönlendir
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          AppNavigation.toChat(
            context: context,
            chatId: chat.id,
            currentUserId: currentUser.uid,
            currentUserName: currentUser.displayName ??
                AppLocalizations.of(context)!.user,
            otherUserId: '', // Grup sohbeti için boş
            otherUserName: chat.name,
          );
        }
      } else {
        if (mounted) {
          ModernSnackbar.showError(
            context,
            chatViewModel.error ?? AppLocalizations.of(context)!.groupChatCreateFailed,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          AppLocalizations.of(context)!.errorWithDetails(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.createGroupChat)),
        body: Center(child: Text(l10n.notLoggedIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createGroupChat),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _createGroupChat,
              child: Text(
                l10n.create,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ✅ Üst kısım: Form alanları (fotoğraf, grup adı, açıklama, katılımcı başlığı, arama)
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
            // ✅ Grup Fotoğrafı
            Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _selectedImage != null || _uploadedPhotoUrl != null
                              ? [Colors.transparent, Colors.transparent]
                              : [
                                  theme.colorScheme.primaryContainer,
                                  theme.colorScheme.secondaryContainer,
                                ],
                        ),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _uploadedPhotoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _uploadedPhotoUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => _buildDefaultAvatar(theme),
                              )
                            : _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : _buildDefaultAvatar(theme),
                      ),
                    ),
                    // ✅ Kamera ikonu overlay
                    if (_selectedImage == null && _uploadedPhotoUrl == null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_isUploading) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Center(
                child: Text(
                  l10n.uploadingPhoto,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingXl),
            // ✅ Grup Adı
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${l10n.groupName} *',
                hintText: l10n.groupNameExampleHint,
                prefixIcon: const Icon(Icons.group_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.groupNameRequired;
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            // ✅ Açıklama (Opsiyonel)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.groupDescriptionOptional,
                hintText: l10n.groupDescriptionShortHint,
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            // ✅ Katılımcı Seçimi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.selectParticipants,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.participantsSelectedCount(_selectedUserIds.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // ✅ Arama Kutusu
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchUsersShort,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
                ],
              ),
            ),
            // ✅ Tüm Kullanıcılar Listesi (Kendisi hariç) - Expanded ile kalan alanı kaplar
            Expanded(
              child: StreamBuilder<List<UserEntity>>(
                key: ValueKey(_searchQuery), // ✅ Arama sorgusu değiştiğinde yeniden build
                stream: authViewModel.getAllUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXl),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(
                      child: Text(
                        l10n.usersLoadFailed,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  final allUsers = snapshot.data!;
                  // Kendisi hariç tüm kullanıcıları göster ve arama yap
                  final availableUsers = allUsers.where((user) {
                    if (user.uid == currentUser.uid) return false;
                    
                    // Arama sorgusu varsa filtrele
                    if (_searchQuery.trim().isNotEmpty) {
                      final query = _searchQuery.trim().toLowerCase();
                      final displayName = (user.displayName ?? '').toLowerCase();
                      final username = (user.username ?? '').toLowerCase();
                      final email = user.email.toLowerCase();
                      
                      return displayName.contains(query) ||
                             username.contains(query) ||
                             email.contains(query);
                    }
                    
                    return true;
                  }).toList();

                  if (availableUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.trim().isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.people_outline_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              _searchQuery.trim().isNotEmpty
                                  ? l10n.noSearchResults
                                  : l10n.noOtherUsersYet,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.trim().isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacingSm),
                              Text(
                                l10n.tryDifferentSearchTerm,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      final isSelected = _selectedUserIds.contains(user.uid);
                      final isFollowing = currentUser.following.contains(user.uid);

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
                            if (isFollowing)
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
                                  l10n.following,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
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
                        trailing: Checkbox(
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
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(user.uid);
                            } else {
                              _selectedUserIds.add(user.uid);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.group_rounded,
        size: 50,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
