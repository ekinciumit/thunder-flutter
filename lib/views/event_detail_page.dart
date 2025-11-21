import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/app_card.dart';
import 'widgets/app_gradient_container.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'user_profile_page.dart';
import '../models/user_model.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;
  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late EventModel event;
  bool isEditing = false;
  bool isUploading = false;
  File? newPhotoFile;
  String? uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    uploadedPhotoUrl = event.coverPhotoUrl;
  }

  Future<void> _pickPhoto() async {
    // Önce galeri veya kamera seçimi göster
    final source = await ModernDialog.showImageSource(
      context: context,
      title: 'Fotoğraf Seç',
    );
    
    if (source == null) return;
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      // Kırpma işlemi
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Kırp',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false, // Serbest kırpma
          ),
          IOSUiSettings(
            title: 'Fotoğrafı Kırp',
            aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          ),
        ],
      );
      
      if (croppedFile != null) {
        setState(() { isUploading = true; });
        newPhotoFile = File(croppedFile.path);
        final fileName = 'event_${event.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('event_photos').child(fileName);
        await ref.putFile(newPhotoFile!);
        uploadedPhotoUrl = await ref.getDownloadURL();
        setState(() { isUploading = false; });
      }
    }
  }

  void _showEditDialog(BuildContext context, EventViewModel eventViewModel, EventModel currentEvent) {
    final titleController = TextEditingController(text: currentEvent.title);
    final descController = TextEditingController(text: currentEvent.description);
    final addressController = TextEditingController(text: currentEvent.address);
    final quotaController = TextEditingController(text: currentEvent.quota.toString());
    DateTime tempDate = currentEvent.datetime;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Etkinliği Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    await _pickPhoto();
                    setState(() {});
                  },
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.deepPurple.withAlpha(40)),
                      color: Colors.deepPurple.withAlpha(10),
                    ),
                    child: isUploading
                        ? Center(child: ModernLoadingWidget(size: 32, message: 'Yükleniyor...', showMessage: false))
                        : (uploadedPhotoUrl != null && uploadedPhotoUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  uploadedPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.add_a_photo, size: 48, color: Colors.deepPurple),
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                ModernInputField(
                  controller: titleController,
                  label: 'Başlık',
                ),
                const SizedBox(height: 8),
                ModernInputField(
                  controller: descController,
                  label: 'Açıklama',
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                ModernInputField(
                  controller: addressController,
                  label: 'Adres',
                ),
                const SizedBox(height: 8),
                ModernInputField(
                  controller: quotaController,
                  label: 'Kota',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text('${tempDate.day}.${tempDate.month}.${tempDate.year} - ${tempDate.hour.toString().padLeft(2, '0')}:${tempDate.minute.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempDate,
                      firstDate: DateTime(DateTime.now().year - 1),
                      lastDate: DateTime(DateTime.now().year + 2),
                    );
                    if (picked != null) {
                      if (!context.mounted) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(tempDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          tempDate = DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                final navigator = Navigator.of(context);
                final updatedEvent = currentEvent.copyWith(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  address: addressController.text.trim(),
                  quota: int.tryParse(quotaController.text.trim()) ?? currentEvent.quota,
                  coverPhotoUrl: uploadedPhotoUrl,
                  datetime: tempDate,
                );
                await eventViewModel.updateEvent(updatedEvent);
                if (!mounted) return;
                navigator.pop();
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventViewModel = Provider.of<EventViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userId = authViewModel.user?.uid ?? '';
    final userName = authViewModel.user?.displayName ?? 'Kullanıcı';
    final theme = Theme.of(context);

    // Event'i real-time dinle
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(event.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppGradientContainer(
            child: Scaffold(
              appBar: AppBar(title: Text(event.title)),
              body: Center(child: ModernLoadingWidget(message: 'Yükleniyor...')),
            ),
          );
        }

        final eventData = snapshot.data!.data() as Map<String, dynamic>;
        final currentEvent = EventModel.fromMap(eventData, event.id);
        
        final isParticipant = currentEvent.participants.contains(userId);
        final isFull = (currentEvent.approvedParticipants.length + currentEvent.participants.length) >= currentEvent.quota;
        final isOwner = currentEvent.createdBy == userId;
        final isApproved = currentEvent.approvedParticipants.contains(userId);
        final hasPendingRequest = currentEvent.pendingRequests.contains(userId);

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(currentEvent.title),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (isOwner) ...[
              // Katılma istekleri bildirimi
              if (currentEvent.pendingRequests.isNotEmpty)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      tooltip: 'Katılma İstekleri Var',
                      onPressed: null, // Sadece görsel bildirim için
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          currentEvent.pendingRequests.length > 9 
                              ? '9+' 
                              : currentEvent.pendingRequests.length.toString(),
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
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Etkinliği Düzenle',
                onPressed: () => _showEditDialog(context, eventViewModel, currentEvent),
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kapak fotoğrafı ve overlay
              if (currentEvent.coverPhotoUrl != null && currentEvent.coverPhotoUrl!.isNotEmpty)
                Stack(
                  children: [
                    Image.network(
                      currentEvent.coverPhotoUrl!,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha((0.45 * 255).toInt()),
                            Colors.transparent,
                            Colors.black.withAlpha((0.25 * 255).toInt()),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  currentEvent.category,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.calendar_today, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${currentEvent.datetime.day}.${currentEvent.datetime.month}.${currentEvent.datetime.year} - ${currentEvent.datetime.hour.toString().padLeft(2, '0')}:${currentEvent.datetime.minute.toString().padLeft(2, '0')}',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentEvent.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 180,
                  color: theme.colorScheme.primary.withAlpha(30),
                  child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
                ),
              const SizedBox(height: 16),
              AppCard(
                borderRadius: 28,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            currentEvent.address,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentEvent.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.people, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${currentEvent.approvedParticipants.length + currentEvent.participants.length}/${currentEvent.quota}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        if (isFull)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha((0.15 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Kota Dolu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                          ),
                        const Spacer(),
                        _DistanceToEventWidget(eventLat: currentEvent.location.latitude, eventLng: currentEvent.location.longitude),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${currentEvent.location.latitude},${currentEvent.location.longitude}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Rota Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Katılma butonu mantığı
                    if (!isOwner)
                      if (isFull)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Kota Dolu',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else if (hasPendingRequest)
                      OutlinedButton.icon(
                        onPressed: () async {
                            await eventViewModel.cancelJoinRequest(currentEvent, userId);
                          if (!context.mounted) return;
                            ModernSnackbar.showSuccess(
                              context,
                              'Katılma isteği geri alındı',
                            );
                        },
                          icon: Icon(Icons.hourglass_empty, color: Colors.orange[700]),
                          label: Text(
                            'İstek Gönderildi (Geri Al)',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(alpha: 0.1),
                            foregroundColor: Colors.orange[700],
                            side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        )
                      else if (isApproved || isParticipant)
                      FilledButton.icon(
                        onPressed: () async {
                            await eventViewModel.leaveEvent(currentEvent, userId);
                          if (!context.mounted) return;
                            ModernSnackbar.showSuccess(
                              context,
                              'Etkinlikten ayrıldınız',
                            );
                        },
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Ayrıl'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () async {
                            await eventViewModel.sendJoinRequest(currentEvent, userId);
                            if (!context.mounted) return;
                            ModernSnackbar.showSuccess(
                              context,
                              'Katılma isteği gönderildi. Etkinlik sahibi onayladığında bildirim alacaksınız.',
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Katılma İsteği Gönder'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                      ),
                  ],
                ),
              ),
              AppCard(
                borderRadius: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Katılımcılar:', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _ParticipantChips(
                        participantUids: [
                          ...currentEvent.participants,
                          ...currentEvent.approvedParticipants
                        ].toSet().toList(), // Duplicate'leri kaldır
                      ),
                      // Katılma İstekleri bölümünü katılımcıların hemen altına ekle
                      if ((isOwner /*|| (currentEvent.moderators?.contains(userId) ?? false)*/) && currentEvent.pendingRequests.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          key: const ValueKey('pending_requests_section'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_add, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Katılma İstekleri (${currentEvent.pendingRequests.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: currentEvent.pendingRequests.map((uid) => FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return ListTile(title: Text('Kullanıcı: $uid'));
                              }
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              final displayName = data['displayName'] ?? 'Kullanıcı';
                              final photoUrl = data['photoUrl'] ?? '';
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: photoUrl.isNotEmpty
                                      ? CircleAvatar(backgroundImage: NetworkImage(photoUrl))
                                      : CircleAvatar(child: Text(displayName[0].toUpperCase())),
                                  title: Text(displayName),
                                  subtitle: Text(data['email'] ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        tooltip: 'Kabul Et',
                                        onPressed: () async {
                                          await eventViewModel.approveJoinRequest(currentEvent, uid);
                                          if (!context.mounted) return;
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        tooltip: 'Reddet',
                                        onPressed: () async {
                                          await eventViewModel.rejectJoinRequest(currentEvent, uid);
                                          if (!context.mounted) return;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )).toList(),
                        ),
                      ],
                      // TODO: event.moderators desteği ekle (ör: if (event.moderators?.contains(userId) ?? false))
                    ],
                  ),
                ),
              ),
              AppCard(
                borderRadius: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yorumlar / Sohbet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (isOwner || isApproved || isParticipant)
                        _CommentsSection(eventId: currentEvent.id, userId: userId, userName: userName)
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha((0.08 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Sohbeti görmek ve katılmak için etkinliğe katılmalısınız.',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _CommentsSection extends StatefulWidget {
  final String eventId;
  final String userId;
  final String userName;
  const _CommentsSection({required this.eventId, required this.userId, required this.userName});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
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
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('comments')
        .add({
      'text': text,
      'userId': widget.userId,
      'userName': widget.userName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _commentController.clear();
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventId)
                .collection('comments')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('Henüz yorum yok. İlk yorumu sen yaz!'));
              }
              // Mesajları timestamp'e göre sırala (zaten orderBy ile geliyor ama emin olmak için)
              final sortedDocs = List.from(docs);
              sortedDocs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return aTime.compareTo(bTime);
              });
              
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: sortedDocs.length,
                itemBuilder: (context, index) {
                  final data = sortedDocs[index].data() as Map<String, dynamic>;
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
                                      Text(
                                        data['text'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.deepPurple[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (data['timestamp'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(data['timestamp'] as Timestamp),
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
                              color: Colors.white,
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
                                        _formatTimestamp(data['timestamp'] as Timestamp),
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
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Yorum yaz...'
                ),
                minLines: 1,
                maxLines: 3,
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

// Mesafe gösterimi için widget
class _DistanceToEventWidget extends StatefulWidget {
  final double eventLat;
  final double eventLng;
  const _DistanceToEventWidget({required this.eventLat, required this.eventLng});

  @override
  State<_DistanceToEventWidget> createState() => _DistanceToEventWidgetState();
}

class _DistanceToEventWidgetState extends State<_DistanceToEventWidget> {
  double? distanceKm;
  @override
  void initState() {
    super.initState();
    _getDistance();
  }

  Future<void> _getDistance() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final d = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, widget.eventLat, widget.eventLng
      ) / 1000.0;
      setState(() { distanceKm = d; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (distanceKm == null) {
      return const Text('Mesafe hesaplanıyor...', style: TextStyle(color: Colors.blueGrey));
    }
    return Text('Etkinliğe uzaklık: ${distanceKm!.toStringAsFixed(2)} km', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600));
  }
}

class _ParticipantChips extends StatelessWidget {
  final List<String> participantUids;
  const _ParticipantChips({required this.participantUids});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthViewModel>(context, listen: false).user?.uid ?? '';
    if (participantUids.isEmpty) {
      return const Text('Katılımcı yok.');
    }
    return Wrap(
      spacing: 8,
      children: participantUids.map((uid) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 32, height: 32,
              child: ModernLoadingWidget(size: 32, showMessage: false),
            );
          }
          if (snapshot.hasError) {
            return Chip(label: Text('Hata'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Chip(label: Text(uid.substring(0, 6)));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final displayName = data['displayName'] ?? 'Kullanıcı';
          final photoUrl = data['photoUrl'] ?? '';
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(
                    user: UserModel.fromMap(data, uid),
                    currentUserId: currentUserId,
                  ),
                ),
              );
            },
            child: Chip(
              avatar: photoUrl.isNotEmpty
                  ? CircleAvatar(backgroundImage: NetworkImage(photoUrl))
                  : CircleAvatar(child: Text(displayName[0].toUpperCase())),
              label: Text(displayName, overflow: TextOverflow.ellipsis),
            ),
          );
        },
      )).toList(),
    );
  }
} 