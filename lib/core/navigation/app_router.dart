import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../views/home_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/chat/presentation/pages/private_chat_page.dart';
import '../../features/chat/presentation/pages/create_group_chat_page.dart';
import '../../features/chat/presentation/pages/group_chat_page.dart';
import '../../features/chat/presentation/pages/group_chat_info_page.dart';
import '../../features/event/presentation/pages/event_detail_page.dart';
import '../../features/event/presentation/pages/event_chat_page.dart';
import '../../features/event/presentation/pages/create_event_page.dart';
import '../../features/user/presentation/pages/user_profile_page.dart';
import '../../views/settings_page.dart';
import '../../views/notifications_page.dart';
import '../../features/chat/presentation/pages/message_forward_page.dart';
import '../../features/chat/presentation/pages/message_search_page.dart';
import '../../features/auth/presentation/pages/edit_profile_page.dart';
import '../../features/user/presentation/pages/blocked_users_page.dart';
import '../../features/user/presentation/pages/followers_following_page.dart';
import '../../features/user/presentation/pages/user_search_page.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../views/dev_preview_page.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/chat/domain/entities/message_entity.dart';
import '../../features/user/domain/entities/user_entity.dart';
import '../../services/notification_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../l10n/app_localizations.dart';

/// App Router - Centralized navigation using go_router
class AppRouter {
  /// Router'ı oluştur (AuthViewModel'i dinlemek için)
  static GoRouter createRouter(AuthViewModel? authViewModel) {
    // Redirect fonksiyonunu optimize et - sadece gerçekten gerekli olduğunda log bas
    String? redirectLogic(BuildContext context, GoRouterState state) {
      try {
        final currentLocation = state.matchedLocation;
        
        // Auth guard: Check if user is authenticated
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        final isAuthenticated = authViewModel.user != null;
        final needsProfileCompletion = authViewModel.needsProfileCompletion;
        final isAuthRoute = currentLocation == '/auth';
        final isCompleteProfileRoute = currentLocation == '/complete-profile';
        final isEventCreateRoute = currentLocation == '/event/create';
        final isUserProfileRoute = currentLocation.startsWith('/user/');
        final isSettingsRoute = currentLocation.startsWith('/settings');
        final isProfileEditRoute = currentLocation == '/profile/edit';
        final isNotificationsRoute = currentLocation == '/notifications';
        final isChatRoute = currentLocation == '/chat';
        final isEventRoute = currentLocation.startsWith('/event');
        final isEventsRoute = currentLocation.startsWith('/events');
        final isMessageRoute = currentLocation.startsWith('/message');
        final isSearchRoute = currentLocation.startsWith('/search');
        final isHomeRoute = currentLocation == '/home' || currentLocation == '/';

        // Root route (/) - sadece gerçekten gerekli olduğunda redirect yap
        // HomePage içindeki navigation'ı etkilememek için root route'unda redirect yapma
        if (isHomeRoute && isAuthenticated && !needsProfileCompletion) {
          // Root route'unda ve authenticated ise, redirect yapma (HomePage zaten gösteriliyor)
          return null;
        }

        // Redirect to auth if not authenticated (except auth and splash routes)
        if (!isAuthenticated && !isAuthRoute && currentLocation != '/') {
          if (kDebugMode) {
            debugPrint('🟡 [ROUTER] Redirect: Not authenticated → /auth');
          }
          return '/auth';
        }

        // ✅ Redirect to complete profile if needed
        // Profil tamamlanmamışsa ve complete-profile route'unda değilsek redirect yap
        if (isAuthenticated && needsProfileCompletion && !isCompleteProfileRoute && !isAuthRoute) {
          // Allow certain routes even if profile incomplete (ama home route değil)
          final allowedIncompleteRoutes = [
            isEventCreateRoute,
            isUserProfileRoute, // Allow viewing profiles even if incomplete
            isSettingsRoute,
            isProfileEditRoute,
            isNotificationsRoute,
            isChatRoute,
            isEventRoute,
            isEventsRoute,
            isMessageRoute,
            isSearchRoute,
            // ❌ isHomeRoute'u kaldırdık - profil tamamlanmamışsa home'a gitmesin, complete-profile'a gitsin
          ];
          final isAllowedRoute = allowedIncompleteRoutes.any((allowed) => allowed);
          
          if (!isAllowedRoute) {
            if (kDebugMode) {
              debugPrint('🟡 [ROUTER] Redirect: Profile incomplete → /complete-profile');
            }
            return '/complete-profile';
          }
        }

        // Redirect to home if authenticated and profile complete (on auth route)
        if (isAuthenticated && !needsProfileCompletion && isAuthRoute) {
          if (kDebugMode) {
            debugPrint('🟡 [ROUTER] Redirect: Authenticated → /');
          }
          return '/';
        }

        return null; // No redirect needed
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ [ROUTER] Redirect error: $e');
          debugPrint('❌ [ROUTER] Stack trace: $stackTrace');
        }
        return null; // Don't block navigation on error
      }
    }

    // GoRouter refreshListenable null kabul etmez, bu yüzden null değilse ekle
    if (authViewModel != null) {
      return GoRouter(
        initialLocation: '/',
        debugLogDiagnostics: kDebugMode, // Sadece debug modda log bas
        // AuthViewModel değişikliklerini dinle (giriş/çıkış sonrası otomatik redirect)
        refreshListenable: authViewModel,
        redirect: redirectLogic,
        observers: [
          FirebaseAnalyticsObserver(analytics: CrashReportingService.analytics),
        ],
        routes: _getRoutes(),
      );
    } else {
      // AuthViewModel null ise refreshListenable olmadan router oluştur
      // (Bu durumda redirect logic çalışır ama otomatik refresh olmaz)
      return GoRouter(
        initialLocation: '/',
        debugLogDiagnostics: kDebugMode, // Sadece debug modda log bas
        redirect: redirectLogic,
        observers: [
          FirebaseAnalyticsObserver(analytics: CrashReportingService.analytics),
        ],
        routes: _getRoutes(),
      );
    }
  }
  
  /// Routes listesini döndürür (kod tekrarını önlemek için)
  static List<RouteBase> _getRoutes() {
    return [
      // Root - handles auth routing
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const RootPage(),
      ),

      // Auth
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPage(),
      ),

      // Complete Profile
      GoRoute(
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),

      // Home (with bottom navigation)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Chat Routes
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final currentUserId = state.uri.queryParameters['currentUserId'] ?? '';
          final currentUserName = state.uri.queryParameters['currentUserName'] ?? 'User';
          final otherUserId = state.uri.queryParameters['otherUserId'] ?? '';
          final otherUserName = state.uri.queryParameters['otherUserName'] ?? 'User';
          final chatId = state.uri.queryParameters['chatId'];

          return PrivateChatPage(
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            chatId: chatId,
          );
        },
      ),
      
      // Create Group Chat
      GoRoute(
        path: '/chat/create-group',
        name: 'create-group-chat',
        builder: (context, state) => const CreateGroupChatPage(),
      ),
      
      // Group Chat Page
      GoRoute(
        path: '/chat/:chatId/group',
        name: 'group-chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final groupName = state.uri.queryParameters['name'];
          final groupPhotoUrl = state.uri.queryParameters['photoUrl'];
          return GroupChatPage(
            chatId: chatId,
            groupName: groupName,
            groupPhotoUrl: groupPhotoUrl,
          );
        },
      ),
      
      // Group Chat Info Page
      GoRoute(
        path: '/chat/:chatId/info',
        name: 'group-chat-info',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return GroupChatInfoPage(chatId: chatId);
        },
      ),

      // Event Routes
      // ÖNEMLİ: Daha spesifik route'lar önce tanımlanmalı!
      // /event/create route'u /event/:eventId'den ÖNCE olmalı
      GoRoute(
        path: '/event/create',
        name: 'event-create',
        builder: (context, state) {
          try {
            return const CreateEventPage();
          } catch (e) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      
      // Event with direct event object (for backward compatibility)
      GoRoute(
        path: '/event',
        name: 'event-detail-direct',
        builder: (context, state) {
          final event = state.extra as EventEntity?;
          if (event == null) {
            return const Scaffold(
              body: Center(child: Text('Event not provided')),
            );
          }
          return EventDetailPage(event: event);
        },
      ),

      // Event detail with eventId parameter (en son, çünkü en genel)
      GoRoute(
        path: '/event/:eventId',
        name: 'event-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          // Event will be loaded by the page itself using the eventId
          return EventDetailPage(eventId: eventId);
        },
      ),
      
      // Event Chat Page
      GoRoute(
        path: '/event/:eventId/chat',
        name: 'event-chat',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventTitle = state.uri.queryParameters['title'];
          return EventChatPage(
            eventId: eventId,
            eventTitle: eventTitle,
          );
        },
      ),

      // User Routes
      GoRoute(
        path: '/user/:userId',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          final currentUserId = authViewModel.user?.uid ?? '';
          
          // Load user by userId - use FutureBuilder in the page itself
          return FutureBuilder<UserEntity?>(
            future: authViewModel.fetchUserProfile(userId),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                if (kDebugMode) {
                  debugPrint('🔵 [ROUTER] Loading user profile for userId: $userId');
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              // Error state
              if (snapshot.hasError) {
                if (kDebugMode) {
                  debugPrint('❌ [ROUTER] Error loading user profile: ${snapshot.error}');
                  debugPrint('❌ [ROUTER] Stack trace: ${snapshot.stackTrace}');
                }
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Data state
              final userEntity = snapshot.data;
              if (userEntity == null) {
                if (kDebugMode) {
                  debugPrint('⚠️ [ROUTER] User not found for userId: $userId');
                }
                return Scaffold(
                  appBar: AppBar(title: const Text('User not found')),
                  body: const Center(child: Text('User not found')),
                );
              }
              
              if (kDebugMode) {
                debugPrint('✅ [ROUTER] User profile loaded successfully: ${userEntity.uid}');
              }
              
              // UI direkt Entity kullanıyor (Clean Architecture)
              return UserProfilePage(user: userEntity, currentUserId: currentUserId);
            },
          );
        },
      ),

      GoRoute(
        path: '/user/:userId/followers',
        name: 'followers',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return FollowersFollowingPage(
            userId: userId,
            showFollowers: true, // true = followers, false = following
          );
        },
      ),

      GoRoute(
        path: '/user/:userId/following',
        name: 'following',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return FollowersFollowingPage(
            userId: userId,
            showFollowers: false, // true = followers, false = following
          );
        },
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      GoRoute(
        path: '/settings/blocked',
        name: 'blocked-users',
        builder: (context, state) {
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          final currentUserId = authViewModel.user?.uid ?? '';
          return BlockedUsersPage(currentUserId: currentUserId);
        },
      ),

      // Profile Routes
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // Message Routes
      GoRoute(
        path: '/message/forward',
        name: 'message-forward',
        builder: (context, state) {
          final message = state.extra as MessageEntity?;
          if (message == null) {
            return const Scaffold(
              body: Center(child: Text('No message provided')),
            );
          }
          return MessageForwardPage(message: message);
        },
      ),

      // Dev Preview (sadece debug modunda)
      if (kDebugMode)
        GoRoute(
          path: '/dev-preview',
          name: 'dev-preview',
          builder: (context, state) {
            return const DevPreviewPage();
          },
        ),

      GoRoute(
        path: '/message/search',
        name: 'message-search',
        builder: (context, state) {
          final chatId = state.uri.queryParameters['chatId'];
          final chatName = state.uri.queryParameters['chatName'];
          return MessageSearchPage(
            chatId: chatId,
            chatName: chatName,
          );
        },
      ),

      // Search
      GoRoute(
        path: '/search/users',
        name: 'user-search',
        builder: (context, state) => const UserSearchPage(),
      ),
    ];
  }
  
  // Geriye dönük uyumluluk için static router (refreshListenable olmadan)
  // Bu sadece testler için kullanılabilir
  static final GoRouter router = createRouter(null);
}

/// RootPage widget for router
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  NotificationService? _notificationService;
  bool _servicesInitialized = false;

  @override
  void dispose() {
    _notificationService?.dispose();
    super.dispose();
  }

  /// Servisleri asenkron olarak başlatır (build metodunu bloklamaz)
  Future<void> _initializeServices(AuthViewModel authViewModel) async {
    if (_servicesInitialized) return;
    
    // Kullanıcı giriş yaptığında ve profil tamamlama gerekmediğinde servisleri başlat
    if (authViewModel.user != null && !authViewModel.needsProfileCompletion) {
      _servicesInitialized = true;
      
      // Bildirim servisini başlat (async, build'i bloklamaz)
      _notificationService = NotificationService();
      unawaited(_notificationService!.initialize(authViewModel));
      
      // Giriş sonrası etkinlik dinlemeyi başlat
      final eventVm = Provider.of<EventViewModel>(context, listen: false);
      eventVm.listenEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel?>(
      builder: (context, authViewModel, _) {
        // ViewModel henüz hazır değilse loading göster
        if (authViewModel == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // ViewModel hazır, servisleri başlat (async, build'i bloklamaz)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeServices(authViewModel);
        });
        
        if (authViewModel.user != null) {
          if (authViewModel.needsProfileCompletion) {
            // SignUp başarılı mesajını burada göster (sadece yeni kayıt olduysa)
            if (authViewModel.justSignedUp) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final l10n = AppLocalizations.of(context);
                if (l10n != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.signUpSuccess),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // Flag'i sıfırla (bir kere göster)
                  authViewModel.justSignedUp = false;
                }
              });
            }
            
            return const CompleteProfilePage();
          }
          return const HomePage();
        }
        return const AuthPage();
      },
    );
  }
}

