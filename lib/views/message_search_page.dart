import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'private_chat_page.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/widgets/modern_components.dart';
import '../core/widgets/glass_container.dart';
import '../core/theme/app_theme.dart';

class MessageSearchPage extends StatefulWidget {
  final String? chatId; // null ise tüm sohbetlerde ara
  final String? chatName; // Sohbet adı (opsiyonel)

  const MessageSearchPage({
    super.key,
    this.chatId,
    this.chatName,
  });

  @override
  State<MessageSearchPage> createState() => _MessageSearchPageState();
}

class _MessageSearchPageState extends State<MessageSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<MessageModel> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final currentUser = authViewModel.user;
      
      if (currentUser == null) return;

      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      List<MessageModel> results;
      
      if (widget.chatId != null) {
        // Belirli bir sohbet içinde ara
        results = await chatViewModel.searchMessages(widget.chatId!, query);
      } else {
        // Tüm sohbetlerde ara
        results = await chatViewModel.searchAllMessages(currentUser.uid, query);
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ModernSnackbar.showError(
          context,
          'Arama hatası: $e',
        );
      }
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildSearchResult(MessageModel message, BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    final isMe = message.senderId == currentUser?.uid;
    final theme = Theme.of(context);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 12,
      padding: EdgeInsets.zero,
      glassAlpha: AppTheme.glassAlphaVeryLight,
      borderAlpha: AppTheme.glassAlphaMedium,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: message.senderPhotoUrl != null 
              ? NetworkImage(message.senderPhotoUrl!)
              : null,
          child: message.senderPhotoUrl == null
              ? Text(
                  message.senderName.isNotEmpty 
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          message.senderName,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.text ?? 'Medya mesajı',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        onTap: () {
          // Mesajın bulunduğu sohbete git
          Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => PrivateChatPage(
              currentUserId: currentUser?.uid ?? '',
              currentUserName: currentUser?.displayName ?? '',
              otherUserId: isMe 
                  ? message.chatId.split('_').firstWhere((id) => id != currentUser?.uid)
                  : message.senderId,
                otherUserName: isMe 
                    ? 'Bilinmeyen'
                    : message.senderName,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.chatName != null 
                ? '${widget.chatName} - Arama'
                : 'Mesaj Ara',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.colorScheme.onSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Arama çubuğu
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isDark 
                      ? theme.colorScheme.outline.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ModernInputField(
                controller: _searchController,
                hint: widget.chatId != null 
                      ? 'Bu sohbette ara...'
                      : 'Tüm mesajlarda ara...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                onChanged: (value) {
                  setState(() {});
                  // Debounce için timer kullanılabilir
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _performSearch(value);
                    }
                  });
                },
              ),
            ),
            
            // Arama sonuçları
            Expanded(
              child: _isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ModernLoadingWidget(
                            size: 32,
                            color: theme.colorScheme.primary,
                            showMessage: false,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aranıyor...',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : _currentQuery.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 80,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                widget.chatId != null 
                                    ? 'Bu sohbette mesaj ara'
                                    : 'Tüm sohbetlerde mesaj ara',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Arama yapmak için yukarıdaki kutuya yazın',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 80,
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Sonuç bulunamadı',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"$_currentQuery" için sonuç bulunamadı',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${_searchResults.length} sonuç bulundu',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      return _buildSearchResult(_searchResults[index], context);
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
