import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase'e test verileri eklemek için service
/// Uygulama içinden çalıştırılabilir
class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase'e test verileri ekle
  /// Returns: Başarı mesajı veya hata mesajı
  Future<String> seedData() async {
    try {
      // Mevcut kullanıcıları kontrol et
      final usersSnapshot = await _firestore.collection('users').limit(10).get();
      final existingUsers = usersSnapshot.docs.map((doc) => doc.id).toList();
      
      if (existingUsers.isEmpty) {
        return '⚠️ Hiç kullanıcı bulunamadı. Önce uygulamada kayıt olun!';
      }

      if (existingUsers.length < 2) {
        return '⚠️ En az 2 kullanıcı gerekiyor. Şu an ${existingUsers.length} kullanıcı var.';
      }

      final results = <String>[];
      
      // Etkinlikler oluştur
      final events = await _createEvents(existingUsers);
      results.add('✅ ${events.length} etkinlik oluşturuldu');
      
      // Sohbetler oluştur
      final chats = await _createChats(existingUsers);
      results.add('✅ ${chats.length} sohbet oluşturuldu');
      
      // Mesajlar oluştur
      final messageCount = await _createMessages(chats, existingUsers);
      results.add('✅ $messageCount mesaj oluşturuldu');
      
      return '✅ Test verileri başarıyla eklendi!\n\n${results.join('\n')}';
    } catch (e) {
      return '❌ Hata: $e';
    }
  }

  /// Mantıklı etkinlikler oluştur
  Future<List<String>> _createEvents(List<String> users) async {
    if (users.isEmpty) return [];

    final now = DateTime.now();
    final events = [
      {
        'title': 'Flutter Meetup İstanbul',
        'description': 'Flutter geliştiricileri için networking ve teknik paylaşımlar. Yeni özellikler, best practices ve proje örnekleri konuşulacak.',
        'location': const GeoPoint(41.0082, 28.9784), // İstanbul
        'address': 'Kadıköy, İstanbul',
        'datetime': now.add(const Duration(days: 7)),
        'quota': 50,
        'category': 'Teknoloji',
        'createdBy': users[0],
        'participants': users.length > 1 ? [users[1]] : [],
      },
      {
        'title': 'Koşu Etkinliği - Bebek Sahili',
        'description': 'Sabah koşusu için bir araya geliyoruz. Her seviyeden koşucuya açık. Bebek sahilinde 5km parkur.',
        'location': const GeoPoint(41.0820, 29.0430), // Bebek
        'address': 'Bebek Sahili, İstanbul',
        'datetime': now.add(const Duration(days: 3)),
        'quota': 30,
        'category': 'Spor',
        'createdBy': users.length > 1 ? users[1] : users[0],
        'participants': [],
      },
      {
        'title': 'Kitap Kulübü - Dijital Minimalizm',
        'description': 'Cal Newport\'un "Digital Minimalism" kitabını tartışıyoruz. Teknoloji ve yaşam dengesi üzerine sohbet.',
        'location': const GeoPoint(41.0255, 28.9744), // Beşiktaş
        'address': 'Beşiktaş Kütüphanesi, İstanbul',
        'datetime': now.add(const Duration(days: 14)),
        'quota': 20,
        'category': 'Kültür',
        'createdBy': users.length > 2 ? users[2 % users.length] : users[0],
        'participants': users.length > 1 ? [users[0]] : [],
      },
      {
        'title': 'Yoga ve Meditasyon Seansı',
        'description': 'Hafta sonu yoga seansı. Tüm seviyeler için uygun. Mat getirmeyi unutmayın!',
        'location': const GeoPoint(41.0369, 28.9850), // Nişantaşı
        'address': 'Nişantaşı Parkı, İstanbul',
        'datetime': now.add(const Duration(days: 5)),
        'quota': 25,
        'category': 'Sağlık',
        'createdBy': users[0],
        'participants': users.length > 1 ? [users[1 % users.length], users.length > 2 ? users[2 % users.length] : users[0]] : [],
      },
      {
        'title': 'Startup Networking Gecesi',
        'description': 'Girişimciler, yatırımcılar ve teknoloji meraklıları için networking etkinliği. Pitch sunumları ve sohbet.',
        'location': const GeoPoint(41.0082, 28.9784), // İstanbul
        'address': 'Silicon Valley Hub, İstanbul',
        'datetime': now.add(const Duration(days: 10)),
        'quota': 100,
        'category': 'İş',
        'createdBy': users.length > 1 ? users[1] : users[0],
        'participants': [],
      },
    ];

    final eventIds = <String>[];

    for (final eventData in events) {
      final docRef = _firestore.collection('events').doc();
      await docRef.set({
        'title': eventData['title'],
        'description': eventData['description'],
        'location': eventData['location'],
        'address': eventData['address'],
        'datetime': Timestamp.fromDate(eventData['datetime'] as DateTime),
        'quota': eventData['quota'],
        'category': eventData['category'],
        'createdBy': eventData['createdBy'],
        'participants': eventData['participants'],
        'pendingRequests': [],
        'approvedParticipants': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      eventIds.add(docRef.id);
    }

    return eventIds;
  }

  /// Mantıklı sohbetler oluştur
  Future<List<String>> _createChats(List<String> users) async {
    if (users.length < 2) return [];

    final chats = <String>[];

    // Özel sohbetler
    if (users.length >= 2) {
      final sorted = [users[0], users[1]]..sort();
      final chatId1 = '${sorted[0]}_${sorted[1]}';
      
      final chat1 = await _firestore.collection('chats').doc(chatId1).get();
      if (!chat1.exists) {
        await _firestore.collection('chats').doc(chatId1).set({
          'name': 'Private Chat',
          'type': 'private',
          'participants': [users[0], users[1]],
          'participantDetails': {},
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCounts': {},
          'lastSeen': {},
          'typingStatus': {},
          'admins': [],
          'moderators': [],
          'isArchived': false,
          'isMuted': false,
        });
        chats.add(chatId1);
      }
    }

    // Grup sohbetleri
    if (users.length >= 3) {
      final groupChatId = _firestore.collection('chats').doc().id;
      await _firestore.collection('chats').doc(groupChatId).set({
        'name': 'Flutter Geliştiricileri',
        'description': 'Flutter ve Dart hakkında sohbetler',
        'type': 'group',
        'participants': users.take(3).toList(),
        'createdBy': users[0],
        'createdAt': FieldValue.serverTimestamp(),
        'admins': [users[0]],
        'moderators': [],
        'unreadCounts': {},
        'lastSeen': {},
        'typingStatus': {},
        'isArchived': false,
        'isMuted': false,
      });
      chats.add(groupChatId);

      if (users.length >= 4) {
        final groupChatId2 = _firestore.collection('chats').doc().id;
        await _firestore.collection('chats').doc(groupChatId2).set({
          'name': 'Etkinlik Planlama',
          'description': 'Yaklaşan etkinlikler hakkında konuşmalar',
          'type': 'group',
          'participants': users.take(4).toList(),
          'createdBy': users[1],
          'createdAt': FieldValue.serverTimestamp(),
          'admins': [users[1]],
          'moderators': [],
          'unreadCounts': {},
          'lastSeen': {},
          'typingStatus': {},
          'isArchived': false,
          'isMuted': false,
        });
        chats.add(groupChatId2);
      }
    }

    return chats;
  }

  /// Mantıklı mesajlar oluştur
  Future<int> _createMessages(List<String> chatIds, List<String> users) async {
    if (chatIds.isEmpty || users.length < 2) return 0;

    final messages = [
      'Merhaba! Nasılsın?',
      'İyi gidiyor, teşekkürler. Sen nasılsın?',
      'Ben de iyiyim. Bugün Flutter meetup\'ına geliyor musun?',
      'Evet, kesinlikle! Saat kaçta başlıyor?',
      '19:00\'da başlıyor. Kadıköy\'de buluşalım mı?',
      'Harika! O zaman görüşürüz 🎉',
      'Etkinlik çok güzel geçti. Bir sonrakine de gelir misin?',
      'Tabii ki! Bir sonraki etkinliği sen organize edebilirsin.',
      'Tamam, ben düşüneyim. İyi geceler!',
      'İyi geceler! 🌙',
    ];

    int messageCount = 0;

    for (final chatId in chatIds) {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) continue;

      final chatData = chatDoc.data()!;
      final participants = (chatData['participants'] as List).cast<String>();
      if (participants.isEmpty) continue;

      // Her sohbete 5-10 mesaj ekle
      final messageCountForChat = 5 + (chatId.hashCode % 6).abs();

      for (int i = 0; i < messageCountForChat && i < messages.length; i++) {
        final senderId = participants[i % participants.length];
        final messageId = _firestore.collection('messages').doc().id;
        final timestamp = DateTime.now().subtract(Duration(minutes: messageCountForChat - i));

        await _firestore.collection('messages').doc(messageId).set({
          'chatId': chatId,
          'senderId': senderId,
          'senderName': 'Kullanıcı ${participants.indexOf(senderId) + 1}',
          'text': messages[i % messages.length],
          'type': 'text',
          'status': 'sent',
          'timestamp': Timestamp.fromDate(timestamp),
          'reactions': {},
          'isEdited': false,
          'isDeleted': false,
          'isPinned': false,
        });

        messageCount++;

        // Chat'in lastMessage'ını güncelle
        if (i == messageCountForChat - 1) {
          await _firestore.collection('chats').doc(chatId).update({
            'lastMessageAt': Timestamp.fromDate(timestamp),
            'lastMessage': {
              'text': messages[i % messages.length],
              'senderId': senderId,
              'senderName': 'Kullanıcı ${participants.indexOf(senderId) + 1}',
              'timestamp': Timestamp.fromDate(timestamp),
            },
          });
        }
      }
    }

    return messageCount;
  }
}

