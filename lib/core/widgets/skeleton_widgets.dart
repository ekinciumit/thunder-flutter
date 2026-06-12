import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading widget'ları
/// Veriler yüklenirken gösterilen placeholder animasyonları

class SkeletonConfig {
  static Color baseColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[800]! : Colors.grey[300]!;
  }

  static Color highlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[700]! : Colors.grey[100]!;
  }
}

/// Temel shimmer wrapper
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SkeletonConfig.baseColor(context),
      highlightColor: SkeletonConfig.highlightColor(context),
      child: child,
    );
  }
}

/// Yuvarlak skeleton (avatar için)
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Dikdörtgen skeleton (metin için)
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    // Negatif width'i önle
    final safeWidth = width > 0 ? width.toDouble() : 0.0;
    final safeHeight = height > 0 ? height.toDouble() : 0.0;
    
    return Container(
      width: safeWidth > 0 ? safeWidth : null,
      height: safeHeight > 0 ? safeHeight : null,
      constraints: safeWidth > 0 && safeHeight > 0
          ? BoxConstraints(
              minWidth: 0.0,
              maxWidth: safeWidth,
              minHeight: 0.0,
              maxHeight: safeHeight,
            )
          : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Chat listesi için skeleton item
class ChatListItemSkeleton extends StatelessWidget {
  const ChatListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonCircle(size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 16),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 200, height: 14),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 40, height: 12),
                const SizedBox(height: 8),
                SkeletonCircle(size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat listesi skeleton (birden fazla item)
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ChatListItemSkeleton(),
    );
  }
}

/// Bildirim listesi için skeleton item
class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonCircle(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 180, height: 14),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bildirim listesi skeleton
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;

  const NotificationListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const NotificationItemSkeleton(),
    );
  }
}

/// Etkinlik kartı için skeleton
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 200, height: 20),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonCircle(size: 16),
                      const SizedBox(width: 8),
                      SkeletonBox(width: 120, height: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SkeletonCircle(size: 16),
                      const SizedBox(width: 8),
                      SkeletonBox(width: 150, height: 14),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonCircle(size: 24),
                      const SizedBox(width: 4),
                      SkeletonCircle(size: 24),
                      const SizedBox(width: 4),
                      SkeletonCircle(size: 24),
                      const SizedBox(width: 8),
                      SkeletonBox(width: 80, height: 12),
                    ],
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

/// Etkinlik listesi skeleton
class EventListSkeleton extends StatelessWidget {
  final int itemCount;

  const EventListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const EventCardSkeleton(),
    );
  }
}

/// Kullanıcı listesi için skeleton item
class UserListItemSkeleton extends StatelessWidget {
  const UserListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SkeletonCircle(size: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 16),
                  const SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 14),
                ],
              ),
            ),
            SkeletonBox(width: 80, height: 32, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

/// Kullanıcı listesi skeleton
class UserListSkeleton extends StatelessWidget {
  final int itemCount;

  const UserListSkeleton({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const UserListItemSkeleton(),
    );
  }
}

/// Profil sayfası skeleton
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const SkeletonCircle(size: 100),
            const SizedBox(height: 16),
            SkeletonBox(width: 150, height: 24),
            const SizedBox(height: 8),
            SkeletonBox(width: 100, height: 16),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) => Column(
                children: [
                  SkeletonBox(width: 40, height: 20),
                  const SizedBox(height: 4),
                  SkeletonBox(width: 60, height: 14),
                ],
              )),
            ),
            const SizedBox(height: 24),
            SkeletonBox(width: double.infinity, height: 44, borderRadius: 22),
            const SizedBox(height: 32),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonBox(width: double.infinity, height: 80, borderRadius: 12),
            )),
          ],
        ),
      ),
    );
  }
}

/// Mesaj listesi skeleton
class MessageListSkeleton extends StatelessWidget {
  final int itemCount;

  const MessageListSkeleton({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final isMe = index % 3 != 0;
          return Padding(
            padding: EdgeInsets.only(
              left: isMe ? 80 : 16,
              right: isMe ? 16 : 80,
              top: 4,
              bottom: 4,
            ),
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: SkeletonBox(
                width: 150 + (index % 3) * 30,
                height: 40,
                borderRadius: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}

