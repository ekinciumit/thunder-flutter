import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import 'private_chat_page.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;
  final String currentUserId;
  const UserProfilePage({super.key, required this.user, required this.currentUserId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isFollowing = false;
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    isFollowing = widget.user.followers.contains(widget.currentUserId);
    followersCount = widget.user.followers.length;
    followingCount = widget.user.following.length;
  }

  Future<void> _toggleFollow() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(widget.currentUserId);
    setState(() {
      isFollowing = !isFollowing;
      followersCount += isFollowing ? 1 : -1;
    });
    if (isFollowing) {
      await userRef.update({
        'followers': FieldValue.arrayUnion([widget.currentUserId])
      });
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([widget.user.uid])
      });
    } else {
      await userRef.update({
        'followers': FieldValue.arrayRemove([widget.currentUserId])
      });
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([widget.user.uid])
      });
    }
  }

  Stream<List<EventModel>> _userEventsStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: widget.user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return EventModel.fromMap(data, doc.id);
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.displayName ?? 'Kullanıcı Profili')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
                  ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(widget.user.photoUrl!))
                  : const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
            ),
            const SizedBox(height: 16),
            Text(widget.user.displayName ?? 'İsimsiz', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(widget.user.bio!, style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('$followersCount', style: theme.textTheme.titleMedium),
                    const Text('Takipçi'),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text('$followingCount', style: theme.textTheme.titleMedium),
                    const Text('Takip'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.user.uid != widget.currentUserId)
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(isFollowing ? 'Takibi Bırak' : 'Takip Et'),
              ),
            if (widget.user.uid != widget.currentUserId && isFollowing)
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Sohbet Başlat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PrivateChatPage(
                        currentUserId: widget.currentUserId,
                        currentUserName: widget.user.displayName ?? 'Kullanıcı',
                        otherUserId: widget.user.uid,
                        otherUserName: widget.user.displayName ?? 'Kullanıcı',
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Etkinlikler', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<EventModel>>(
              stream: _userEventsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const Text('Bu kullanıcıya ait etkinlik bulunamadı.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(event.title),
                        subtitle: Text(event.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text('${event.datetime.day}.${event.datetime.month}.${event.datetime.year}'),
                        onTap: () {
                          // TODO: Etkinlik detayına git
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 