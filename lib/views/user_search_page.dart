import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'user_profile_page.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<UserModel>> _userStream() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthViewModel>(context, listen: false).user?.uid ?? '';
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  color: theme.colorScheme.onSurface,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(AppTheme.alphaLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.withAlpha(20),
                  Colors.blue.withAlpha(15),
                  Colors.amber.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.deepPurple.withAlpha(40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ModernInputField(
              controller: _searchController,
              hint: 'Kullanıcı ara (isim, e-posta)',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.error, theme.colorScheme.errorContainer],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      ),
                    )
                  : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: ModernLoadingWidget(message: 'Aranıyor...'));
                }
                final users = snapshot.data ?? [];
                final filtered = users.where((user) {
                  final query = _searchQuery.toLowerCase();
                  return (user.displayName ?? '').toLowerCase().contains(query) ||
                         (user.email).toLowerCase().contains(query);
                }).toList();
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.person_search,
                    title: 'Kriterlere uygun kullanıcı bulunamadı',
                    message: 'Farklı arama terimleri deneyin',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (contextIgnored, indexIgnored) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 4,
                      shadowColor: Colors.deepPurple.withAlpha(40),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        splashColor: Colors.deepPurple.withAlpha(40),
                        highlightColor: Colors.deepPurple.withAlpha(20),
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (routeContext, primaryAnimation, secondaryAnimation) => UserProfilePage(user: user, currentUserId: currentUserId),
                              transitionsBuilder: (routeContext, animation, secondaryAnimation, child) => FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.deepPurple.withAlpha(10),
                                Colors.blue.withAlpha(8),
                                Colors.amber.withAlpha(5),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.deepPurple.withAlpha(30),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withAlpha(40),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 28,
                                          backgroundImage: NetworkImage(user.photoUrl!),
                                        )
                                      : CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.deepPurple.withAlpha(30),
                                          child: Icon(
                                            Icons.person,
                                            size: 32,
                                            color: Colors.deepPurple.shade600,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName ?? 'İsimsiz',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.deepPurple.shade400,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 