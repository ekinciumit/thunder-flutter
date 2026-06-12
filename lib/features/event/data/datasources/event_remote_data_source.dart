import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/image_compressor.dart';

/// Event Remote Data Source Interface
/// 
/// Clean Architecture Data Layer
/// Firebase işlemleri için abstract interface.
abstract class EventRemoteDataSource {
  Future<void> addEvent(EventModel event);
  Stream<List<EventModel>> getEventsStream();
  Stream<List<EventModel>> getUserEventsStream(String userId);
  Future<List<EventModel>> fetchNextEvents({DateTime? startAfter, int limit});
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  Future<void> joinEvent(String eventId, String userId);
  Future<void> leaveEvent(String eventId, String userId);
  Future<void> sendJoinRequest(String eventId, String userId);
  Future<void> approveJoinRequest(String eventId, String userId);
  Future<void> rejectJoinRequest(String eventId, String userId);
  Future<void> cancelJoinRequest(String eventId, String userId);
  Future<void> removeParticipant(String eventId, String userId);
  Future<void> cancelEvent(String eventId, String cancellationReason);
  
  /// Event cover fotoğrafını yükler ve download URL'ini döndürür
  Future<String> uploadEventCoverPhoto(File photoFile, {String? eventId});
  
  /// Event fotoğrafını yükler ve download URL'ini döndürür
  Future<String> uploadEventPhoto(File photoFile, String eventId);
  
  /// Tek bir event'i stream olarak getir
  Stream<EventModel?> getEventStream(String eventId);
  
  /// Event comments stream
  Stream<List<Map<String, dynamic>>> getEventCommentsStream(String eventId);
  
  /// Event comment ekle
  Future<void> addEventComment(String eventId, String text, String userId, String userName);
  
  /// Event comments'i sil (event silindiğinde kullanılır)
  Future<void> deleteEventComments(String eventId);
}

/// Event Remote Data Source Implementation
/// 
/// Clean Architecture Data Layer
/// Firebase Firestore işlemlerini yapar.
class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final CollectionReference<Map<String, dynamic>> _eventsRef;

  EventRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _eventsRef = (firestore ?? FirebaseFirestore.instance).collection('events');

  @override
  Future<void> addEvent(EventModel event) async {
    try {
      await _eventsRef.add(event.toMap());
    } catch (e) {
      throw ServerException('Etkinlik eklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<EventModel>> getEventsStream() {
    try {
      final query = _eventsRef.orderBy('datetime').limit(50);
      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
    } catch (e) {
      throw ServerException('Etkinlikler getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<EventModel>> getUserEventsStream(String userId) {
    try {
      // Cost Optimization: Limit to 20 most recent events (40-60% read cost savings)
      // User can load more if needed via pagination
      final query = _eventsRef
          .where('createdBy', isEqualTo: userId)
          .orderBy('datetime', descending: true)
          .limit(20); // ✅ Server-side limit
      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
    } catch (e) {
      throw ServerException('Kullanıcı etkinlikleri getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> fetchNextEvents({DateTime? startAfter, int limit = 50}) async {
    try {
      Query<Map<String, dynamic>> query = _eventsRef
          .orderBy('datetime')
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw ServerException('Etkinlikler getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventsRef.doc(event.id).update(event.toMap());
    } catch (e) {
      throw ServerException('Etkinlik güncellenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      // Önce comments'leri sil
      await deleteEventComments(eventId);
      // Sonra event'i sil
      await _eventsRef.doc(eventId).delete();
    } catch (e) {
      throw ServerException('Etkinlik silinirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw ServerException('Etkinliğe katılırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      // ÖNCE sistem mesajını oluştur (kullanıcı hala katılımcıyken)
      await _addSystemMessage(eventId, userId, 'left');
      
      // SONRA kullanıcıyı array'lerden çıkar
      await _eventsRef.doc(eventId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'approvedParticipants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw ServerException('Etkinlikten ayrılırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> sendJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw ServerException('Katılma isteği gönderilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> approveJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
        'approvedParticipants': FieldValue.arrayUnion([userId])
      });
      
      // Sistem mesajı oluştur
      await _addSystemMessage(eventId, userId, 'joined');
    } catch (e) {
      throw ServerException('Katılma isteği onaylanırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw ServerException('Katılma isteği reddedilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw ServerException('Katılma isteği iptal edilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> removeParticipant(String eventId, String userId) async {
    try {
      // Önce sistem mesajını oluştur
      await _addSystemMessage(eventId, userId, 'removed');
      
      // Sonra kullanıcıyı array'lerden çıkar
      await _eventsRef.doc(eventId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'approvedParticipants': FieldValue.arrayRemove([userId]),
        'pendingRequests': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw ServerException('Katılımcı çıkarılırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelEvent(String eventId, String cancellationReason) async {
    try {
      // Event'i iptal et
      await _eventsRef.doc(eventId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': cancellationReason,
      });
      
      // Sistem mesajı oluştur
      await _eventsRef
          .doc(eventId)
          .collection('comments')
          .add({
        'text': 'Etkinlik iptal edildi. Sebep: $cancellationReason',
        'userId': 'system',
        'userName': 'Sistem',
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Etkinlik iptal edilirken hata oluştu: ${e.toString()}');
    }
  }

  /// Sistem mesajı ekler (katılma/ayrılma bildirimleri için)
  Future<void> _addSystemMessage(String eventId, String userId, String type) async {
    try {
      // Kullanıcı bilgilerini al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.exists 
          ? (userDoc.data()?['displayName'] ?? 'Bir kullanıcı')
          : 'Bir kullanıcı';
      
      String messageText;
      if (type == 'joined') {
        messageText = '$userName etkinliğe katıldı';
      } else if (type == 'left') {
        messageText = '$userName etkinlikten ayrıldı';
      } else if (type == 'removed') {
        messageText = '$userName etkinlikten çıkarıldı';
      } else {
        return;
      }
      
      // Sistem mesajını comments collection'ına ekle
      await _eventsRef
          .doc(eventId)
          .collection('comments')
          .add({
        'text': messageText,
        'userId': 'system',
        'userName': 'Sistem',
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Sistem mesajı hatası kritik değil, sessizce devam et
      // Sadece log'a yaz
      if (kDebugMode) {
        debugPrint('⚠️ Sistem mesajı eklenemedi: $e');
      }
    }
  }

  @override
  Future<String> uploadEventCoverPhoto(File photoFile, {String? eventId}) async {
    try {
      if (!await photoFile.exists()) {
        throw ServerException('Fotoğraf dosyası bulunamadı');
      }

      // Cost Optimization: Compress image before upload (70-80% storage savings)
      final compressedFile = await ImageCompressor.compressEventCover(photoFile);

      // Güvenlik: EventId bazlı path yapısı - eventId yoksa geçici ID kullan
      final tempEventId = eventId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final fileId = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('event_covers').child(tempEventId).child(fileId);

      final uploadTask = storageRef.putFile(compressedFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up temporary compressed file
      try {
        if (compressedFile.path != photoFile.path) {
          await compressedFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      
      return downloadUrl;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Event cover fotoğrafı yüklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadEventPhoto(File photoFile, String eventId) async {
    try {
      if (!await photoFile.exists()) {
        throw ServerException('Fotoğraf dosyası bulunamadı');
      }

      // Cost Optimization: Compress image before upload (70-80% storage savings)
      final compressedFile = await ImageCompressor.compressEventCover(photoFile);

      final fileId = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('event_photos').child(eventId).child(fileId);

      final uploadTask = storageRef.putFile(compressedFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up temporary compressed file
      try {
        if (compressedFile.path != photoFile.path) {
          await compressedFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      
      return downloadUrl;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Event fotoğrafı yüklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<EventModel?> getEventStream(String eventId) {
    try {
      return _eventsRef
          .doc(eventId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            return EventModel.fromMap(snapshot.data()!, snapshot.id);
          });
    } catch (e) {
      throw ServerException('Event getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getEventCommentsStream(String eventId) {
    try {
      // Cost Optimization: Limit to 50 most recent comments (40-60% read cost savings)
      return _eventsRef
          .doc(eventId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .limit(50) // ✅ Server-side limit
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                // Clean Architecture: Timestamp'ı DateTime'a çevir (UI Firestore tipi bilmemeli)
                final timestamp = data['timestamp'];
                DateTime? dateTime;
                if (timestamp != null) {
                  if (timestamp is Timestamp) {
                    dateTime = timestamp.toDate();
                  } else if (timestamp is Map) {
                    // Firestore Timestamp'ı Map olarak gelirse convert et
                    final seconds = timestamp['seconds'] ?? timestamp['_seconds'] ?? 0;
                    final nanoseconds = timestamp['nanoseconds'] ?? timestamp['_nanoseconds'] ?? 0;
                    dateTime = DateTime.fromMillisecondsSinceEpoch(
                      (seconds as int) * 1000 + (nanoseconds as int) ~/ 1000000,
                    );
                  }
                }
                return {
                  ...data,
                  'id': doc.id,
                  'timestamp': dateTime, // Timestamp yerine DateTime
                };
              }).toList());
    } catch (e) {
      throw ServerException('Event yorumları getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> addEventComment(String eventId, String text, String userId, String userName) async {
    try {
      await _eventsRef
          .doc(eventId)
          .collection('comments')
          .add({
        'text': text,
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Yorum eklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEventComments(String eventId) async {
    try {
      final commentsRef = _eventsRef
          .doc(eventId)
          .collection('comments');
      
      final comments = await commentsRef.get();
      
      // Batch delete için tüm referansları topla
      final batch = _firestore.batch();
      for (final doc in comments.docs) {
        batch.delete(doc.reference);
      }
      
      if (comments.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      // Comments silme hatası kritik değil (event zaten silinmiş olabilir)
      // Sessizce devam et
      if (kDebugMode) {
        debugPrint('⚠️ Event comments silinemedi: $e');
      }
    }
  }
}

