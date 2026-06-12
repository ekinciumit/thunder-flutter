import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/user/domain/entities/user_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';

/// Modern Event Comments Section Widget
/// 
/// Karanlık moda uyumlu, modern chat UI/UX tasarımı
class EventCommentsSection extends StatefulWidget {
  final String eventId;
  final String userId;
  final String userName;
  final bool isFullScreen; // ✅ Tam ekran modu için
  
  const EventCommentsSection({
    super.key,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.isFullScreen = false, // ✅ Varsayılan olarak false (event detail'de kısıtlı)
  });

  @override
  State<EventCommentsSection> createState() => _EventCommentsSectionState();
}

class _EventCommentsSectionState extends State<EventCommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  
  // ✅ User photo URL cache: userId -> photoUrl
  final Map<String, String?> _userPhotoCache = {};

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// DateTime'ı modern formatla (Clean Architecture: UI sadece DateTime bilir)
  String _formatTimestamp(DateTime? date) {
    if (date == null) return 'Şimdi';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  /// Scroll'u en alta kaydır (yeni mesaj geldiğinde)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendComment() async {
    if (!_formKey.currentState!.validate()) return;
    
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;
    
    setState(() => _isSending = true);
    
    // Clean Architecture: ViewModel üzerinden comment ekle
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    try {
      await eventViewModel.addEventComment(widget.eventId, text, widget.userId, widget.userName);
      _commentController.clear();
      // Scroll'u en alta kaydır
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.commentSendFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// Kullanıcı avatar widget'ı oluştur
  Widget _buildUserAvatar(String? userId, String userName, ThemeData theme) {
    // ✅ User photo URL'ini cache'den al
    final photoUrl = userId != null ? _userPhotoCache[userId] : null;
    
    // Avatar için renk oluştur (userName'den tutarlı renk)
    final avatarColor = _getAvatarColor(userName);

    return CircleAvatar(
      radius: 18,
      backgroundColor: photoUrl == null ? avatarColor : Colors.transparent,
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl)
          : null,
      child: photoUrl == null || photoUrl.isEmpty
          ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  /// UserName'den avatar rengi oluştur (tutarlı renk için)
  Color _getAvatarColor(String userName) {
    if (userName.isEmpty) return AppColorConfig.primaryColor;
    final hashCode = userName.hashCode;
    final colors = [
      AppColorConfig.primaryColor,
      AppColorConfig.secondaryColor,
      Colors.deepPurple,
      Colors.purple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.pink,
    ];
    return colors[hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // ✅ User photo URL'lerini stream'den al ve cache'le
    return StreamBuilder<List<UserEntity>>(
      stream: authViewModel.getAllUsersStream(),
      builder: (context, usersSnapshot) {
        // ✅ User photo cache'ini güncelle
        if (usersSnapshot.hasData) {
          final users = usersSnapshot.data!;
          for (var user in users) {
            if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
              _userPhotoCache[user.uid] = user.photoUrl;
            }
          }
        }

        return widget.isFullScreen
        ? Column(
            children: [
              // ✅ Tam ekran modunda Expanded kullan
              Expanded(
                child: _buildChatMessages(theme, isDark, l10n),
              ),
              // ✅ Input bar her zaman altta
              Padding(
                padding: EdgeInsets.all(
                  widget.isFullScreen ? AppTheme.spacingLg : 0,
                ),
                child: _buildInputBar(theme, isDark, l10n),
              ),
            ],
          )
        : Column(
            children: [
              // ✅ Kısıtlı mod (event detail'de)
              _buildChatMessages(theme, isDark, l10n),
              const SizedBox(height: AppTheme.spacingMd),
              _buildInputBar(theme, isDark, l10n),
            ],
          );
      },
    );
  }
  
  Widget _buildChatMessages(ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Container(
      constraints: widget.isFullScreen ? null : const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: widget.isFullScreen
            ? Colors.transparent // ✅ Tam ekran modunda arka plan şeffaf
            : (isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
        borderRadius: widget.isFullScreen
            ? BorderRadius.zero // ✅ Tam ekran modunda border radius yok
            : BorderRadius.circular(AppTheme.radiusXl),
        border: widget.isFullScreen
            ? null // ✅ Tam ekran modunda border yok
            : Border.all(
                color: isDark
                    ? theme.colorScheme.outline.withValues(alpha: 0.2)
                    : theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1.0,
              ),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<EventViewModel>(context, listen: false)
            .getEventCommentsStream(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          }

          final comments = snapshot.data ?? [];
          
          if (comments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      l10n.noComments,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Yeni mesaj geldiğinde scroll'u güncelle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(
              widget.isFullScreen ? AppTheme.spacingLg : AppTheme.spacingMd,
            ),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final data = comments[index];
              final isSystemMessage = data['type'] == 'system';
              
              // ✅ Sistem Mesajı Tasarımı
              if (isSystemMessage) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.deepPurple.withValues(alpha: 0.3)
                              : Colors.deepPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: isDark ? Colors.deepPurple[300] : Colors.deepPurple[700],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.deepPurple.withValues(alpha: 0.15)
                                : Colors.deepPurple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(
                              color: Colors.deepPurple.withValues(alpha: 0.2),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['text'] ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.deepPurple[200]
                                      : Colors.deepPurple[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (data['timestamp'] != null) ...[
                                const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(data['timestamp'] as DateTime?),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Kullanıcı Mesajı Tasarımı
              final userName = data['userName'] ?? 'Kullanıcı';
              final userId = data['userId'] as String?;
              final isCurrentUser = userId == widget.userId; // ✅ Kullanıcının kendi mesajı mı?
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isCurrentUser) ...[
                      // ✅ Diğer kullanıcılar: Avatar sol tarafta
                      _buildUserAvatar(userId, userName, theme),
                      const SizedBox(width: AppTheme.spacingMd),
                    ],
                    // ✅ Mesaj Bubble
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // ✅ Kullanıcı Adı ve Timestamp
                          Padding(
                            padding: EdgeInsets.only(
                              left: isCurrentUser ? 0 : 4,
                              right: isCurrentUser ? 4 : 0,
                              bottom: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isCurrentUser) ...[
                                  Text(
                                    userName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                ],
                                if (data['timestamp'] != null)
                                  Text(
                                    _formatTimestamp(data['timestamp'] as DateTime?),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: AppTheme.spacingSm),
                                  Text(
                                    userName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // ✅ Mesaj İçeriği Bubble
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              // ✅ Kullanıcının kendi mesajı: Primary color gradient
                              // ✅ Diğer kullanıcılar: Normal surface color
                              color: isCurrentUser
                                  ? (isDark
                                      ? AppColorConfig.primaryColor.withValues(alpha: 0.3)
                                      : AppColorConfig.primaryColor.withValues(alpha: 0.2))
                                  : (isDark
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : theme.colorScheme.surface),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(AppTheme.radiusLg),
                                topRight: const Radius.circular(AppTheme.radiusLg),
                                bottomLeft: Radius.circular(isCurrentUser ? AppTheme.radiusLg : AppTheme.radiusSm),
                                bottomRight: Radius.circular(isCurrentUser ? AppTheme.radiusSm : AppTheme.radiusLg),
                              ),
                              border: Border.all(
                                color: isCurrentUser
                                    ? AppColorConfig.primaryColor.withValues(alpha: 0.4)
                                    : (isDark
                                        ? theme.colorScheme.outline.withValues(alpha: 0.2)
                                        : theme.colorScheme.outline.withValues(alpha: 0.1)),
                                width: 1.0,
                              ),
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isCurrentUser
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentUser) ...[
                      // ✅ Kullanıcının kendi mesajı: Avatar sağ tarafta
                      const SizedBox(width: AppTheme.spacingMd),
                      _buildUserAvatar(userId, userName, theme),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildInputBar(ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.outline.withValues(alpha: 0.2)
                      : theme.colorScheme.outline.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: l10n.writeComment,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingMd,
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
                enabled: !_isSending,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // ✅ Send Button - Modern tasarım
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColorConfig.primaryColor,
                  AppColorConfig.secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColorConfig.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSending ? null : _sendComment,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: Center(
                  child: _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
