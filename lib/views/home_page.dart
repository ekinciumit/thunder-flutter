import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_list_view.dart';
import 'map_view.dart';
import 'profile_view.dart';
import 'create_event_page.dart';
import 'chat_list_page.dart';
import 'private_chat_page.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/chat_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  int _totalUnreadCount = 0;

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
  }

  void _setupNotificationRouting() {
    _notificationService.onNotificationTapped = (chatId) {
      _navigateToChat(chatId);
    };
  }

  Future<void> _navigateToChat(String chatId) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    if (currentUser == null) return;

    try {
      // Chat dokümanını al
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data()!;
      final chat = ChatModel.fromMap(chatData, chatId);

      if (chat.type == ChatType.private) {
        // Diğer kullanıcıyı bul
        final otherParticipant = chat.participants.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );

        if (otherParticipant.isEmpty) return;

        // Kullanıcı bilgilerini al
        final otherUser = await _authService.fetchUserProfile(otherParticipant);
        final otherUserName = otherUser?.displayName ?? 
                             chat.participantDetails[otherParticipant]?.name ?? 
                             'Bilinmeyen';

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
                currentUserName: currentUser.displayName ?? 'Kullanıcı',
                otherUserId: otherParticipant,
                otherUserName: otherUserName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet açılamadı: $e')),
        );
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null, // Başlık kaldırıldı
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarIcon(
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                selected: _selectedIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _NavBarIcon(
                    icon: Icons.chat_rounded,
                    label: 'Sohbetler',
                    selected: _selectedIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  if (_totalUnreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
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
                label: 'Harita',
                selected: _selectedIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              _NavBarIcon(
                icon: Icons.person_rounded,
                label: 'Profil',
                selected: _selectedIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateEventPage()),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            )
          : null,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.selected 
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: widget.selected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.selected 
                      ? colorScheme.primary 
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                      color: widget.selected 
                        ? colorScheme.primary 
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
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