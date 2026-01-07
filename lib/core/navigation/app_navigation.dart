import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/chat/domain/entities/message_entity.dart';
import '../../views/create_event_page.dart';

/// Centralized navigation helper class
/// Use this instead of Navigator.push directly
class AppNavigation {
  /// Navigate to home page
  static void toHome(BuildContext context) {
    context.go('/home');
  }

  /// Navigate to auth page
  static void toAuth(BuildContext context) {
    context.go('/auth');
  }

  /// Navigate to complete profile page
  static void toCompleteProfile(BuildContext context) {
    context.go('/complete-profile');
  }

  /// Navigate to chat page
  static void toChat({
    required BuildContext context,
    String? chatId,
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
  }) {
    final uri = Uri(
      path: '/chat',
      queryParameters: {
        if (chatId != null) 'chatId': chatId,
        'currentUserId': currentUserId,
        'currentUserName': currentUserName,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      },
    );
    context.push(uri.toString());
  }

  /// Navigate to event detail page
  static void toEventDetail({
    required BuildContext context,
    String? eventId,
    EventEntity? event,
  }) {
    if (eventId != null) {
      context.push('/event/$eventId');
    } else if (event != null) {
      // EventEntity için codec yok, bu yüzden eventId kullan
      // Bu uyarıyı önlemek için eventId kullanıyoruz
      context.push('/event/${event.id}');
    }
  }

  /// Navigate to create event page
  static void toCreateEvent(BuildContext context) {
    try {
      if (!context.mounted) {
        return;
      }
      context.push('/event/create');
    } catch (e) {
      if (context.mounted) {
        // Fallback: Try using Navigator if go_router fails
        try {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateEventPage(),
            ),
          );
        } catch (e2) {
          // Fallback navigation failed
        }
      }
    }
  }

  /// Navigate to my events page
  static void toMyEvents(BuildContext context) {
    context.push('/events/my');
  }

  /// Navigate to user profile page
  static void toUserProfile({
    required BuildContext context,
    required String userId,
  }) {
    if (kDebugMode) {
      debugPrint('🔵 [NAV] Navigating to user profile: userId=$userId');
    }
    try {
      if (!context.mounted) {
        if (kDebugMode) {
          debugPrint('❌ [NAV] Context not mounted, cannot navigate');
        }
        return;
      }
      final route = '/user/$userId';
      if (kDebugMode) {
        debugPrint('🔵 [NAV] Pushing route: $route');
      }
      context.push(route);
      if (kDebugMode) {
        debugPrint('✅ [NAV] Navigation pushed successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [NAV] Navigation error: $e');
        debugPrint('❌ [NAV] Stack trace: $stackTrace');
      }
    }
  }

  /// Navigate to followers page
  static void toFollowers({
    required BuildContext context,
    required String userId,
  }) {
    context.push('/user/$userId/followers');
  }

  /// Navigate to following page
  static void toFollowing({
    required BuildContext context,
    required String userId,
  }) {
    context.push('/user/$userId/following');
  }

  /// Navigate to settings page
  static void toSettings(BuildContext context) {
    context.push('/settings');
  }

  /// Navigate to blocked users page
  static void toBlockedUsers(BuildContext context) {
    context.push('/settings/blocked');
  }

  /// Navigate to edit profile page
  static void toEditProfile(BuildContext context) {
    context.push('/profile/edit');
  }

  /// Navigate to notifications page
  static void toNotifications(BuildContext context) {
    context.push('/notifications');
  }

  /// Navigate to message forward page
  static void toMessageForward({
    required BuildContext context,
    required MessageEntity message,
  }) {
    context.push('/message/forward', extra: message);
  }

  /// Navigate to message search page
  static void toMessageSearch({
    required BuildContext context,
    String? chatId,
    String? chatName,
  }) {
    final uri = Uri(
      path: '/message/search',
      queryParameters: {
        if (chatId != null) 'chatId': chatId,
        if (chatName != null) 'chatName': chatName,
      },
    );
    context.push(uri.toString());
  }

  /// Navigate to user search page
  static void toUserSearch(BuildContext context) {
    context.push('/search/users');
  }

  /// Go back
  static void back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

