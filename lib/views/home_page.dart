import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_list_view.dart';
import 'map_view.dart';
import 'profile_view.dart';
import 'create_event_page.dart';
import 'chat_list_page.dart';
import 'private_chat_page.dart';
import 'notifications_page.dart';
import '../services/notification_service.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../models/chat_model.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../core/utils/fab_position_helper.dart';
import '../l10n/app_localizations.dart';
import 'widgets/app_gradient_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  int _totalUnreadCount = 0;
  int _unreadNotificationCount = 0;

  static final List<Widget> _pages = <Widget>[
    EventListView(),
    ChatListPage(),
    MapView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _setupNotificationRouting();
    _loadUnreadCount();
    _loadUnreadNotificationCount();
    // Tam ekran için system UI'ı ayarla
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    // Status bar'ı şeffaf yap
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    // System UI ayarlarını sıfırla (opsiyonel)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _setupNotificationRouting() {
    _notificationService.onNotificationTapped = (chatId) {
      _navigateToChat(chatId);
    };
  }

  Future<void> _navigateToChat(String chatId) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    if (currentUser == null) return;

    try {
      // Clean Architecture: ChatViewModel üzerinden chat'i al
      final chat = await chatViewModel.getChatById(chatId);
      if (chat == null) return;

      if (chat.type == ChatType.private) {
        // Diğer kullanıcıyı bul
        final otherParticipant = chat.participants.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );

        if (otherParticipant.isEmpty) return;

        // Kullanıcı bilgilerini al (Clean Architecture: AuthViewModel kullan)
        final otherUser = await authViewModel.fetchUserProfile(otherParticipant);
        final otherUserName = otherUser?.displayName ?? 
                             chat.participantDetails[otherParticipant]?.name ?? 
                             'Unknown';

        // Sohbet sayfasına git
        if (mounted) {
          // Önce chat list sayfasına git
          setState(() {
            _selectedIndex = 1;
          });
          
          // Sonra sohbet sayfasına navigate et
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrivateChatPage(
                currentUserId: currentUser.uid,
                currentUserName: currentUser.displayName ?? 'User',
                otherUserId: otherParticipant,
                otherUserName: otherUserName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ModernSnackbar.showError(context, '${l10n?.error ?? "Error"}: $e');
      }
    }
  }

  void _loadUnreadCount() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts = data['unreadCounts'] as Map<String, dynamic>? ?? {};
        total += unreadCounts[currentUser.uid] as int? ?? 0;
      }
      if (mounted) {
        setState(() {
          _totalUnreadCount = total;
        });
      }
    });
  }

  void _loadUnreadNotificationCount() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = snapshot.docs.length;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AppGradientContainer(
      gradientColors: AppTheme.gradientPrimary,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SafeArea(
              top: false,
              bottom: false,
              child: _pages[_selectedIndex],
            ),
            // Bildirimler Butonu (Sadece ana sayfada)
            if (_selectedIndex == 0)
              Positioned(
                bottom: FABPositionHelper.getFABBottomPosition(context, isTopButton: false),
                right: AppTheme.spacingLg,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(28),
                  color: AppColorConfig.secondaryColor,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Badge(
                        label: _unreadNotificationCount > 0
                            ? Text(
                                _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                                style: const TextStyle(fontSize: 10),
                              )
                            : null,
                        isLabelVisible: _unreadNotificationCount > 0,
                        backgroundColor: AppColorConfig.errorColor,
                        child: const Icon(Icons.notifications_rounded, size: 24, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            // Etkinlik Oluştur Butonu (Sadece ana sayfada)
            if (_selectedIndex == 0)
              Positioned(
                bottom: FABPositionHelper.getFABBottomPosition(context, isTopButton: true),
                right: AppTheme.spacingLg,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(28),
                  color: AppColorConfig.primaryColor,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateEventPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.fromLTRB(
            AppTheme.spacingMd, // Sol
            AppTheme.spacingSm, // Üst
            AppTheme.spacingMd, // Sağ
            MediaQuery.of(context).padding.bottom + AppTheme.spacingXs, // Alt (4px)
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorConfig.primaryColor.withValues(alpha: 0.95),
                AppColorConfig.secondaryColor.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            boxShadow: [
              BoxShadow(
                color: AppColorConfig.primaryColor.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColorConfig.primaryColor.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXxl,
                vertical: AppTheme.spacingMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarIcon(
                    icon: Icons.home_rounded,
                    label: l10n.home,
                    selected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _NavBarIcon(
                        icon: Icons.chat_rounded,
                        label: l10n.chat,
                        selected: _selectedIndex == 1,
                        onTap: () => _onItemTapped(1),
                      ),
                      if (_totalUnreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorConfig.errorColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              _totalUnreadCount > 99 ? '99+' : _totalUnreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  _NavBarIcon(
                    icon: Icons.map_rounded,
                    label: l10n.map,
                    selected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  _NavBarIcon(
                    icon: Icons.person_rounded,
                    label: l10n.profile,
                    selected: _selectedIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  
  const _NavBarIcon({
    required this.icon, 
    required this.label,
    required this.selected, 
    required this.onTap
  });

  @override
  State<_NavBarIcon> createState() => _NavBarIconState();
}

class _NavBarIconState extends State<_NavBarIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_NavBarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 64,
              height: 56,
              decoration: BoxDecoration(
                color: widget.selected 
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: widget.selected
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.selected 
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                      color: widget.selected 
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 