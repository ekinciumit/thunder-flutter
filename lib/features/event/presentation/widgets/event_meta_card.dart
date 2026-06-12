import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/event_entity.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/modern_components.dart';
import 'distance_to_event_widget.dart';
import 'participation_state.dart';
import '../../../../core/widgets/app_card.dart';

/// Event meta information card - displays location, description, quota, and participation button
class EventMetaCard extends StatelessWidget {
  final EventEntity event;
  final bool isOwner;
  final bool isFull;
  final bool isParticipant;
  final bool isApproved;
  final bool hasPendingRequest;
  final String userId;
  final EventViewModel eventViewModel;
  final AppLocalizations l10n;
  final ThemeData theme;

  const EventMetaCard({
    super.key,
    required this.event,
    required this.isOwner,
    required this.isFull,
    required this.isParticipant,
    required this.isApproved,
    required this.hasPendingRequest,
    required this.userId,
    required this.eventViewModel,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 28,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      enableGlassmorphism: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Location - Daha hoş görünüm (görseldeki gibi)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // ✅ Description ayrı satırda (varsa)
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          // ✅ Participants ve Distance - Daha düzenli
          Row(
            children: [
              Icon(
                Icons.people,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${event.approvedParticipants.length + event.participants.length}/${event.quota}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.quotaFull,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              const Spacer(),
              DistanceToEventWidget(
                eventLat: event.location.latitude,
                eventLng: event.location.longitude,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ✅ Modern tasarım: Yatay butonlar (Edit ve Search Users gibi)
          if (!isOwner && !event.isCancelled) ...[
            Row(
              children: [
                // Get Directions Button - Modern tasarım
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${event.location.latitude},${event.location.longitude}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(
                      Icons.directions,
                      size: 18,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.white,
                    ),
                    label: Text(
                      l10n.createRoute,
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                          : Colors.grey[800],
                      side: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.outline.withValues(alpha: 0.3)
                            : Colors.grey[600]!,
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      minimumSize: const Size(0, 44), // ✅ Aynı yükseklik için
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Pill-like (rounded)
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Katıl Button - Modern tasarım (eşit boyut)
                // ✅ Key ekle: Aynı event için aynı widget instance'ı kullanılsın (local state korunur)
                Expanded(
                  child: _ModernParticipationButton(
                    key: ValueKey('participation_${event.id}_$userId'),
                    event: event,
                    userId: userId,
                    isFull: isFull,
                    hasPendingRequest: hasPendingRequest,
                    isParticipant: isApproved || isParticipant,
                    eventViewModel: eventViewModel,
                    l10n: l10n,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Owner için sadece Get Directions butonu
            OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${event.location.latitude},${event.location.longitude}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icon(
                Icons.directions,
                size: 18,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
              ),
              label: Text(
                l10n.createRoute,
                style: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                    : Colors.grey[800],
                side: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.outline.withValues(alpha: 0.3)
                      : Colors.grey[600]!,
                  width: 1.0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // ✅ Aynı padding
                minimumSize: const Size(0, 44), // ✅ Aynı yükseklik
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Pill-like (rounded)
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Edit ve Search Users butonları gibi dark gray, rounded, thin border tasarımı
class _ModernParticipationButton extends StatefulWidget {
  final EventEntity event;
  final String userId;
  final bool isFull;
  final bool hasPendingRequest;
  final bool isParticipant;
  final EventViewModel eventViewModel;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _ModernParticipationButton({
    super.key, // ✅ Key parametresi eklendi (local state korunması için)
    required this.event,
    required this.userId,
    required this.isFull,
    required this.hasPendingRequest,
    required this.isParticipant,
    required this.eventViewModel,
    required this.l10n,
    required this.theme,
  });

  @override
  State<_ModernParticipationButton> createState() => _ModernParticipationButtonState();
}

class _ModernParticipationButtonState extends State<_ModernParticipationButton> {
  bool _isLoading = false;
  // ✅ Local state: Butona basıldıktan hemen sonra UI güncellemesi için
  // Geçmiş etkinliklerde Firestore stream güncellemesi gecikebilir, bu yüzden local state kritik
  bool? _localHasPendingRequest; // null = prop'tan al, true/false = override
  
  @override
  void initState() {
    super.initState();
    // ✅ InitState'te local state'i prop'tan initialize et (ilk render için)
    // Ama kullanıcı aksiyonundan sonra local state'i setState ile değiştirdiğimizde korunur
  }

  @override
  void didUpdateWidget(_ModernParticipationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ✅ Local state senkronizasyon mantığı (Geçmiş etkinlikler için güçlendirilmiş):
    // KRİTİK KURAL: Eğer local state varsa (true/false), sadece Firestore'dan KESIN bir güncelleme geldiğinde sıfırla
    // Geçmiş etkinliklerde Firestore stream güncellemesi gecikebilir veya gelmeyebilir
    
    // ✅ Senaryo 1: Event ID veya User ID değişti → Widget tamamen yeniden oluşturuldu, local state'i sıfırla
    if (oldWidget.event.id != widget.event.id || oldWidget.userId != widget.userId) {
      _localHasPendingRequest = null;
      return;
    }
    
    // ✅ Senaryo 2: Prop değişmedi → Local state'i MUTLAKA koru
    if (oldWidget.hasPendingRequest == widget.hasPendingRequest) {
      return; // Prop değişmedi, local state'i MUTLAKA koru
    }
    
    // ✅ Senaryo 3: Prop değişti, ama local state yok → Prop'a güven (normal durum)
    if (_localHasPendingRequest == null) {
      return; // Local state yok, prop'a güven (normal durum)
    }
    
    // ✅ Senaryo 4: Local state VAR ve prop değişti → Dikkatli senkronize et
    if (_localHasPendingRequest == true) {
      // Local state'te "true" tutuyoruz (isteği attık)
      if (widget.hasPendingRequest == true) {
        // ✅ Firestore güncellemesi geldi (prop true oldu) → Artık prop'a güvenebiliriz
        _localHasPendingRequest = null;
      }
      // ❌ Local true ama prop false → Firestore henüz güncellenmedi VEYA geçmiş etkinliklerde güncellenmeyebilir
      // KRİTİK: Local state'i MUTLAKA koru, sıfırlama! (implicit return)
    } else if (_localHasPendingRequest == false) {
      // Local state'te "false" tutuyoruz (isteği iptal ettik)
      if (widget.hasPendingRequest == false) {
        // ✅ Firestore güncellemesi geldi (prop false oldu) → İptal işlemi tamamlandı
        _localHasPendingRequest = null;
      }
      // ❌ Local false ama prop true → Bu durum normalde olmamalı, ama yine de koru (implicit return)
    }
  }

  bool get _effectiveHasPendingRequest {
    // ✅ Local state varsa onu kullan, yoksa prop'u kullan
    return _localHasPendingRequest ?? widget.hasPendingRequest;
  }

  ParticipationState get _state {
    if (widget.isFull && !widget.isParticipant && !_effectiveHasPendingRequest) {
      return ParticipationState.full;
    } else if (_effectiveHasPendingRequest) {
      return ParticipationState.pending;
    } else if (widget.isParticipant) {
      return ParticipationState.joined;
    } else {
      return ParticipationState.notJoined;
    }
  }

  Future<void> _handleAction() async {
    setState(() => _isLoading = true);

    // ✅ Başlangıç state'ini kaydet (hata durumunda geri almak için)
    final previousLocalState = _localHasPendingRequest;
    final currentState = _state;

    try {
      final eventEntity = widget.event;
      
      switch (currentState) {
        case ParticipationState.pending:
          // ✅ İptal edildiğinde local state'i güncelle
          setState(() {
            _localHasPendingRequest = false;
          });
          try {
            await widget.eventViewModel.cancelJoinRequest(eventEntity, widget.userId);
            // ✅ Bildirim gösterimi de try-catch içinde (hata durumunda buton state'i korunur)
            if (mounted) {
              try {
                ModernSnackbar.showSuccess(context, widget.l10n.joinRequestCancelled);
              } catch (e) {
                // Bildirim gösterimi başarısız olsa bile devam et
                debugPrint('Snackbar gösterimi başarısız: $e');
              }
            }
          } catch (e) {
            // ✅ Hata durumunda local state'i geri al (yukarıdaki catch'e düşecek)
            rethrow;
          }
          break;
        case ParticipationState.joined:
          await widget.eventViewModel.leaveEvent(eventEntity, widget.userId);
          if (mounted) {
            ModernSnackbar.showSuccess(context, widget.l10n.leftEvent);
          }
          break;
        case ParticipationState.notJoined:
          // ✅ İstek atıldıktan hemen sonra local state'i güncelle
          // Böylece buton hemen "İptal" durumuna geçer
          if (kDebugMode) {
            debugPrint('✅ [PARTICIPATION] İstek atılıyor, local state true yapılıyor');
          }
          setState(() {
            _localHasPendingRequest = true;
          });
          try {
            await widget.eventViewModel.sendJoinRequest(eventEntity, widget.userId);
            // ✅ Bildirim gösterimi de try-catch içinde (hata durumunda buton state'i korunur)
            if (mounted) {
              try {
                ModernSnackbar.showSuccess(context, widget.l10n.joinRequestSent);
              } catch (e) {
                // Bildirim gösterimi başarısız olsa bile devam et
                debugPrint('Snackbar gösterimi başarısız: $e');
              }
            }
          } catch (e) {
            // ✅ Hata durumunda local state'i geri al (yukarıdaki catch'e düşecek)
            rethrow;
          }
          break;
        case ParticipationState.full:
          // No action for full state
          break;
      }
    } catch (e) {
      // ✅ Hata durumunda local state'i geri al
      if (mounted) {
        setState(() {
          _localHasPendingRequest = previousLocalState;
        });
        ModernSnackbar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case ParticipationState.full:
        return _buildFullButton();
      case ParticipationState.pending:
        return _buildPendingButton();
      case ParticipationState.joined:
        return _buildJoinedButton();
      case ParticipationState.notJoined:
        return _buildJoinButton();
    }
  }

  /// Modern buton stili (Edit ve Search Users gibi)
  /// ✅ Get Directions ile aynı boyut için minimumSize ve padding eşit
  ButtonStyle _getModernButtonStyle() {
    return OutlinedButton.styleFrom(
      backgroundColor: widget.theme.brightness == Brightness.dark
          ? widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
          : Colors.grey[800],
      side: BorderSide(
        color: widget.theme.brightness == Brightness.dark
            ? widget.theme.colorScheme.outline.withValues(alpha: 0.3)
            : Colors.grey[600]!,
        width: 1.0,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // ✅ Aynı padding
      minimumSize: const Size(0, 44), // ✅ Aynı yükseklik (Get Directions ile eşit)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Pill-like (rounded)
      ),
    );
  }

  Widget _buildFullButton() {
    return OutlinedButton.icon(
      onPressed: null, // Disabled
      icon: Icon(
        Icons.event_busy_rounded,
        size: 18,
        color: widget.theme.brightness == Brightness.dark
            ? Colors.white70
            : Colors.white70,
      ),
      label: Text(
        'Dolu', // ✅ Kısa metin - buton boyutunu eşitler
        style: TextStyle(
          color: widget.theme.brightness == Brightness.dark
              ? Colors.white70
              : Colors.white70,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      style: _getModernButtonStyle(),
    );
  }

  Widget _buildPendingButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleAction,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
              ),
            )
          : Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: widget.theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
            ),
      label: Text(
        'İptal', // ✅ Kısa metin - buton boyutunu eşitler
        style: TextStyle(
          color: widget.theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      style: _getModernButtonStyle(),
    );
  }

  Widget _buildJoinedButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleAction,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
              ),
            )
          : Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: widget.theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
            ),
      label: Text(
        'Ayrıl', // ✅ Kısa metin - buton boyutunu eşitler
        style: TextStyle(
          color: widget.theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      style: _getModernButtonStyle(),
    );
  }

  Widget _buildJoinButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleAction,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
              ),
            )
          : Icon(
              Icons.person_add_rounded,
              size: 18,
              color: widget.theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
            ),
      label: Text(
        widget.l10n.join, // ✅ "Katıl" - daha kısa ve buton boyutunu eşitler
        style: TextStyle(
          color: widget.theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      style: _getModernButtonStyle(),
    );
  }
}
