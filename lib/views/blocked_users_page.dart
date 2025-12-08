import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_color_config.dart';
import '../core/widgets/modern_components.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';

class BlockedUsersPage extends StatefulWidget {
  final String currentUserId;
  const BlockedUsersPage({super.key, required this.currentUserId});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final UserService _userService = UserService();
  List<UserModel> _blockedUsers = [];
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
      final users = <UserModel>[];
      for (final userId in blockedIds) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists) users.add(UserModel.fromMap(doc.data()!, doc.id));
      }
      setState(() { _blockedUsers = users; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockUser(UserModel user) async {
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
