import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../features/event/presentation/pages/event_list_view.dart';
import 'map_view.dart';
import '../features/user/presentation/pages/profile_view.dart';
import '../features/chat/presentation/pages/chat_list_page.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../features/chat/domain/entities/chat_entity.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../core/utils/fab_position_helper.dart';
import '../l10n/app_localizations.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/custom_bottom_navigation_bar.dart';
import '../core/navigation/app_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  int _totalUnreadCount = 0;
  int _unreadNotificationCount = 0;
  StreamSubscription<List<ChatEntity>>? _chatsStreamSubscription;
  StreamSubscription<int>? _notificationsStreamSubscription;

  // Pages'i build metodunda oluştur ki theme değişikliklerini dinlesin
  List<Widget> get _pages => <Widget>[
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
    // Status bar ayarları build'de brightness'a göre ayarlanacak
  }

  @override
  void dispose() {
    _chatsStreamSubscription?.cancel();
    _notificationsStreamSubscription?.cancel();
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
          AppNavigation.toChat(
            context: context,
            currentUserId: currentUser.uid,
            currentUserName: currentUser.displayName ?? 'User',
            otherUserId: otherParticipant,
            otherUserName: otherUserName,
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
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    if (currentUser == null) return;

    _chatsStreamSubscription?.cancel();
    // Clean Architecture: ChatViewModel üzerinden chats stream
    _chatsStreamSubscription = chatViewModel.getUserChats(currentUser.uid).listen((chats) {
      int total = 0;
      for (var chat in chats) {
        final unreadCounts = chat.unreadCounts;
        total += unreadCounts[currentUser.uid] ?? 0;
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

    _notificationsStreamSubscription?.cancel();
    // Clean Architecture: UserService üzerinden notification count stream
    final userService = _userService;
    _notificationsStreamSubscription = userService.getUnreadNotificationCountStream(currentUser.uid).listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    if (kDebugMode) {
      debugPrint('🔵 [HOMEPAGE] Navigation tapped: index=$index, currentIndex=$_selectedIndex');
      debugPrint('🔵 [HOMEPAGE] Pages count: ${_pages.length}');
      if (index < _pages.length) {
        debugPrint('🔵 [HOMEPAGE] Page widget type: ${_pages[index].runtimeType}');
      }
    }
    setState(() {
      _selectedIndex = index;
    });
    if (kDebugMode) {
      debugPrint('🔵 [HOMEPAGE] Navigation updated: newIndex=$_selectedIndex');
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    // Status bar'ı brightness'a göre ayarla
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
    
    return AppGradientContainer(
      backgroundImagePath: 'assets/backgrounds/background_2.png',
      backgroundOpacity: 0.7,
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
                      AppNavigation.toNotifications(context);
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_rounded, 
                            size: 26, 
                            color: brightness == Brightness.dark 
                                ? theme.colorScheme.onPrimary 
                                : Colors.white,
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorConfig.errorColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColorConfig.secondaryColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColorConfig.errorColor.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _unreadNotificationCount > 99 
                                      ? '99+' 
                                      : '$_unreadNotificationCount',
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
                      try {
                        if (!mounted) return;
                        AppNavigation.toCreateEvent(context);
                      } catch (e) {
                        if (mounted) {
                          final l10n = AppLocalizations.of(context);
                          ModernSnackbar.showError(
                            context,
                            l10n?.error ?? 'Navigation error: $e',
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(Icons.add_rounded, size: 24, color: brightness == Brightness.dark ? theme.colorScheme.onPrimary : Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
          unreadChatCount: _totalUnreadCount > 0 ? _totalUnreadCount : null,
          items: [
            NavigationItem(
              icon: Icons.home_rounded,
              label: l10n.home,
            ),
            NavigationItem(
              icon: Icons.chat_rounded,
              label: l10n.chat,
            ),
            NavigationItem(
              icon: Icons.map_rounded,
              label: l10n.map,
            ),
            NavigationItem(
              icon: Icons.person_rounded,
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
