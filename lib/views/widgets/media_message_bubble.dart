import 'package:flutter/material.dart';
import 'dart:ui';
import '../../features/chat/domain/entities/message_entity.dart';
import '../../core/theme/app_color_config.dart';
import '../../core/theme/app_theme.dart';
import 'message_reactions.dart';
import 'modern_loading_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Unified media message bubble widget
/// Handles both image and video messages with consistent styling
class MediaMessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final String currentUserId;
  final String currentUserName;
  final String Function(MessageEntity) getDisplayName;
  final String Function(DateTime) formatMessageTime;
  final VoidCallback onLongPress;
  final Function(String) onReactionTap;
  final bool isVideo;

  const MediaMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.currentUserName,
    required this.getDisplayName,
    required this.formatMessageTime,
    required this.onLongPress,
    required this.onReactionTap,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final mediaUrl = isVideo ? message.videoUrl : message.imageUrl;

    if (mediaUrl == null || mediaUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.grey[300],
              backgroundImage: message.senderPhotoUrl != null 
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(
                      getDisplayName(message).isNotEmpty 
                          ? getDisplayName(message)[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : Colors.black87,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Text(
                    getDisplayName(message),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark
                          ? theme.colorScheme.primary
                          : Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                GestureDetector(
                  onTap: () {
                    // Full screen media viewer açılabilir
                  },
                  onLongPress: onLongPress,
                  child: isDark
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.0,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: isVideo
                                    ? _VideoPlayerWidget(videoUrl: mediaUrl)
                                    : _ImageWidget(imageUrl: mediaUrl, theme: theme),
                              ),
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isVideo
                              ? _VideoPlayerWidget(videoUrl: mediaUrl)
                              : _ImageWidget(imageUrl: mediaUrl, theme: theme),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                MessageReactions(
                  reactions: message.reactions,
                  currentUserId: currentUserId,
                  onReactionTap: onReactionTap,
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? theme.colorScheme.primaryContainer
                  : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
              child: Text(
                currentUserName.isNotEmpty 
                    ? currentUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? theme.colorScheme.onPrimaryContainer
                      : AppColorConfig.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Internal image widget
class _ImageWidget extends StatelessWidget {
  final String imageUrl;
  final ThemeData theme;

  const _ImageWidget({
    required this.imageUrl,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 200,
        height: 200,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: ModernLoadingWidget(size: 32, showMessage: false),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 200,
        height: 200,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.error, color: theme.colorScheme.error),
      ),
    );
  }
}

/// Internal video player widget
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }
  
  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      // Video initialize hatası - sessizce devam et
      if (mounted) {
        setState(() => _initialized = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
        setState(() {});
      },
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

