import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../l10n/app_localizations.dart';

/// Event comments section widget
class EventCommentsSection extends StatefulWidget {
  final String eventId;
  final String userId;
  final String userName;
  
  const EventCommentsSection({
    super.key,
    required this.eventId,
    required this.userId,
    required this.userName,
  });

  @override
  State<EventCommentsSection> createState() => _EventCommentsSectionState();
}

class _EventCommentsSectionState extends State<EventCommentsSection> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// DateTime'ı formatlar (Clean Architecture: UI sadece DateTime bilir)
  String _formatTimestamp(DateTime? date) {
    if (date == null) return 'Şimdi';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    // Clean Architecture: ViewModel üzerinden comment ekle
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    try {
      await eventViewModel.addEventComment(widget.eventId, text, widget.userId, widget.userName);
      _commentController.clear();
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver (zaten ViewModel'de throw ediliyor)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurple.withAlpha(40)),
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Provider.of<EventViewModel>(context, listen: false)
                .getEventCommentsStream(widget.eventId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final comments = snapshot.data ?? [];
              final l10n = AppLocalizations.of(context)!;
              if (comments.isEmpty) {
                return Center(child: Text(l10n.noComments));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final data = comments[index];
                  final isSystemMessage = data['type'] == 'system';
                  
                  // Sistem mesajı için stil (diğer mesajlar gibi ama biraz farklı)
                  if (isSystemMessage) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.deepPurple.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 14,
                                        color: Colors.deepPurple,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          data['text'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.deepPurple[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (data['timestamp'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(data['timestamp']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
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
                  
                  // Normal mesaj için mevcut stil
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Text(data['userName'] != null && data['userName'].toString().isNotEmpty
                              ? data['userName'].toString()[0].toUpperCase()
                              : '?'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.deepPurple.withAlpha(30)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      data['userName'] ?? 'Kullanıcı',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    if (data['timestamp'] != null)
                                      Text(
                                        _formatTimestamp(data['timestamp'] as DateTime?),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(data['text'] ?? ''),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: l10n.writeComment
                    ),
                    minLines: 1,
                    maxLines: 3,
                  );
                }
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.deepPurple),
              onPressed: _sendComment,
            ),
          ],
        ),
      ],
    );
  }
}

