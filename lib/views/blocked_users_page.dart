import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_color_config.dart';
import '../core/widgets/modern_components.dart';
import '../services/user_service.dart';
import '../features/user/domain/entities/user_entity.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';

class BlockedUsersPage extends StatefulWidget {
  final String currentUserId;
  const BlockedUsersPage({super.key, required this.currentUserId});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final UserService _userService = UserService();
  List<UserEntity> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final blockedIds = await _userService.getBlockedUsers(widget.currentUserId);
      final users = <UserEntity>[];
      
      // Clean Architecture: AuthViewModel üzerinden user bilgilerini çek
      // Context'i async öncesi sakla
      if (!mounted) return;
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      for (final userId in blockedIds) {
        final userEntity = await authViewModel.fetchUserProfile(userId);
        if (userEntity != null) {
          users.add(userEntity);
        }
      }
      
      if (mounted) {
        setState(() { _blockedUsers = users; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unblockUser(UserEntity user) async {
    final l10n = AppLocalizations.of(context)!;
    await _userService.unblockUser(widget.currentUserId, user.uid);
    setState(() => _blockedUsers.removeWhere((u) => u.uid == user.uid));
    if (mounted) ModernSnackbar.showSuccess(context, l10n.unblocked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.blockedUsers),
        backgroundColor: AppColorConfig.primaryColor,
        foregroundColor: AppColorConfig.cardColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.block, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(l10n.noBlockedUsers),
                ]))
              : ListView.builder(
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, i) {
                    final user = _blockedUsers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl != null ? CachedNetworkImageProvider(user.photoUrl!) : null,
                        child: user.photoUrl == null ? Text((user.displayName ?? 'U')[0]) : null,
                      ),
                      title: Text(user.displayName ?? 'Unknown'),
                      trailing: TextButton(
                        onPressed: () => _unblockUser(user), 
                        child: Text(l10n.unblock),
                      ),
                    );
                  },
                ),
    );
  }
}
