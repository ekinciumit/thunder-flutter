import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/event/presentation/viewmodels/event_viewmodel.dart';
import 'event_detail_page.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_color_config.dart';
import '../core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final eventViewModel = Provider.of<EventViewModel>(context);
    final currentUser = authViewModel.user;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Etkinliklerim')),
        body: const Center(child: Text('Kullanıcı bilgisi bulunamadı')),
      );
    }

    return AppGradientContainer(
      gradientColors: AppTheme.gradientPrimary,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: null,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  MediaQuery.of(context).padding.top + AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                ),
                child: Row(
                  children: [
                    Text(
                      'Etkinliklerim',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Events List
              Expanded(
                child: StreamBuilder<List<EventModel>>(
                  stream: eventViewModel.getUserEventsStream(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: ModernLoadingWidget(
                          message: 'Etkinlikler yükleniyor...',
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return ErrorStateWidget(
                        message: 'Etkinlikler yüklenirken bir hata oluştu',
                        error: snapshot.error.toString(),
                        onRetry: () => setState(() {}),
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                      );
                    }

                    final events = snapshot.data ?? [];

                    if (events.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.event_note_rounded,
                        title: 'Henüz etkinlik oluşturmadınız',
                        message: 'Yeni bir etkinlik oluşturarak başlayın!',
                        actionLabel: 'Etkinlik Oluştur',
                        onAction: () {
                          Navigator.of(context).pop();
                        },
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                      );
                    }

                    return Container(
                      color: Colors.transparent,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm,
                        ),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventCard(event, eventViewModel, theme);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event, EventViewModel eventViewModel, ThemeData theme) {
    final hasPendingRequests = event.pendingRequests.isNotEmpty;
    final isPast = event.datetime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kapak fotoğrafı
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl),
              ),
              child: Stack(
                children: [
                  if (event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: event.coverPhotoUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: AppColorConfig.primaryColor,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                            AppColorConfig.secondaryColor.withAlpha(AppTheme.alphaVeryLight),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.event,
                        size: 64,
                        color: AppColorConfig.primaryColor,
                      ),
                    ),
                  // Overlay
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(AppTheme.alphaMedium),
                        ],
                      ),
                    ),
                  ),
                  // Badge'ler
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        if (hasPendingRequests)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm,
                              vertical: AppTheme.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorConfig.warningColor,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              boxShadow: [
                                AppTheme.shadowSoft(
                                  color: Colors.black.withAlpha(AppTheme.alphaMedium),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_add, size: 14, color: Colors.white),
                                const SizedBox(width: AppTheme.spacingXs),
                                Text(
                                  '${event.pendingRequests.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: AppTheme.spacingSm),
                        if (isPast)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm,
                              vertical: AppTheme.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[700]!.withAlpha(AppTheme.alphaAlmostOpaque),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: const Text(
                              'Geçmiş',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Tarih ve kategori
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: AppTheme.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaAlmostOpaque),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Text(
                            event.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '${event.datetime.day}.${event.datetime.month}.${event.datetime.year} - ${event.datetime.hour.toString().padLeft(2, '0')}:${event.datetime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColorConfig.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: Text(
                          event.address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: AppColorConfig.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        '${event.approvedParticipants.length + event.participants.length}/${event.quota}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (hasPendingRequests)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: AppTheme.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorConfig.warningColor.withAlpha(AppTheme.alphaVeryLight),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: AppColorConfig.warningColor.withAlpha(AppTheme.alphaMedium),
                            ),
                          ),
                          child: Text(
                            '${event.pendingRequests.length} bekleyen istek',
                            style: TextStyle(
                              color: AppColorConfig.warningColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailPage(event: event),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Görüntüle'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showManageDialog(event, eventViewModel),
                          icon: const Icon(Icons.settings),
                          label: const Text('Yönet'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColorConfig.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                          ),
                        ),
                      ),
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

  void _showManageDialog(EventModel event, EventViewModel eventViewModel) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusRound),
        ),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusRound),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacingMd),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Katılma İstekleri
            if (event.pendingRequests.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl,
                  vertical: AppTheme.spacingMd,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: AppColorConfig.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'Katılma İstekleri (${event.pendingRequests.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: event.pendingRequests.length,
                  itemBuilder: (context, index) {
                    final userId = event.pendingRequests[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return ListTile(
                            title: Text('Kullanıcı: ${userId.substring(0, 8)}...'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    await eventViewModel.approveJoinRequest(event, userId);
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    ModernSnackbar.showSuccess(
                                      context,
                                      'İstek onaylandı',
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    await eventViewModel.rejectJoinRequest(event, userId);
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    ModernSnackbar.showInfo(
                                      context,
                                      'İstek reddedildi',
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final displayName = userData['displayName'] ?? 'Kullanıcı';
                        final photoUrl = userData['photoUrl'];
                        final email = userData['email'] ?? '';

                        return ListTile(
                          leading: photoUrl != null && photoUrl.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(photoUrl),
                                )
                              : CircleAvatar(
                                  child: Text(displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?'),
                                ),
                          title: Text(displayName),
                          subtitle: Text(email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                tooltip: 'Kabul Et',
                                onPressed: () async {
                                  await eventViewModel.approveJoinRequest(event, userId);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ModernSnackbar.showSuccess(
                                    context,
                                    'İstek onaylandı',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                tooltip: 'Reddet',
                                onPressed: () async {
                                  await eventViewModel.rejectJoinRequest(event, userId);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ModernSnackbar.showInfo(
                                    context,
                                    'İstek reddedildi',
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            // Düzenle ve Sil butonları
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDialog(event, eventViewModel);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Etkinliği Düzenle'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColorConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteDialog(event, eventViewModel);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Etkinliği Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorConfig.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        side: BorderSide(color: AppColorConfig.errorColor),
                      ),
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

  void _showEditDialog(EventModel event, EventViewModel eventViewModel) {
    // EventDetailPage'deki düzenleme dialog'unu kullanabiliriz
    // Veya burada basit bir dialog gösterebiliriz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(event: event),
      ),
    ).then((_) {
      // Sayfa geri döndüğünde refresh yapılabilir
      setState(() {});
    });
  }

  void _showDeleteDialog(EventModel event, EventViewModel eventViewModel) {
    ModernDialog.showConfirmation(
      context: context,
      title: 'Etkinliği Sil',
      message: '"${event.title}" etkinliğini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      confirmText: 'Sil',
      cancelText: 'İptal',
      confirmColor: AppColorConfig.errorColor,
    ).then((confirmed) async {
      if (confirmed == true) {
        await eventViewModel.deleteEvent(event.id);
        if (!context.mounted) return;
        ModernSnackbar.showSuccess(
          context,
          'Etkinlik silindi',
        );
      }
    });
  }
}

