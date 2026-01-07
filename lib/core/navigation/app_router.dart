import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../views/home_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/chat/presentation/pages/private_chat_page.dart';
import '../../features/event/presentation/pages/event_detail_page.dart';
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
import '../../features/event/presentation/pages/my_events_page.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/chat/domain/entities/message_entity.dart';
import '../../features/user/domain/entities/user_entity.dart';

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

        // Redirect to complete profile if needed
        // BUT: Allow certain routes even if profile incomplete
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
          isHomeRoute, // Allow home route even if profile incomplete
        ];
        final isAllowedRoute = allowedIncompleteRoutes.any((allowed) => allowed);
        
        if (isAuthenticated && needsProfileCompletion && !isCompleteProfileRoute && !isAuthRoute && !isAllowedRoute) {
          if (kDebugMode) {
            debugPrint('🟡 [ROUTER] Redirect: Profile incomplete → /complete-profile');
          }
          return '/complete-profile';
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
        routes: _getRoutes(),
      );
    } else {
      // AuthViewModel null ise refreshListenable olmadan router oluştur
      // (Bu durumda redirect logic çalışır ama otomatik refresh olmaz)
      return GoRouter(
        initialLocation: '/',
        debugLogDiagnostics: kDebugMode, // Sadece debug modda log bas
        redirect: redirectLogic,
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
        builder: (context, state) {
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          return CompleteProfilePage(
            onComplete: (name, bio, photoUrl) async {
              try {
                await authViewModel.completeProfile(
                  displayName: name,
                  bio: bio,
                  photoUrl: photoUrl,
                );
              } catch (e) {
                // Error handling is done in ViewModel
              }
            },
          );
        },
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

      GoRoute(
        path: '/events/my',
        name: 'my-events',
        builder: (context, state) => const MyEventsPage(),
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
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel?>(
      builder: (context, authViewModel, _) {
        if (authViewModel == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authViewModel.user != null) {
          if (authViewModel.needsProfileCompletion) {
            return CompleteProfilePage(
              onComplete: (name, bio, photoUrl) async {
                try {
                  await authViewModel.completeProfile(
                    displayName: name,
                    bio: bio,
                    photoUrl: photoUrl,
                  );
                } catch (e) {
                  // Error handling is done in ViewModel
                }
              },
            );
          }
          return const HomePage();
        }
        return const AuthPage();
      },
    );
  }
}

