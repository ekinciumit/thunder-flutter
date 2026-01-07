import 'package:flutter/material.dart';
import '../../features/event/domain/entities/event_entity.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../core/widgets/modern_components.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Katılma durumu enum'ı
enum ParticipationState {
  full,       // Kontenjan doldu
  pending,    // İstek bekliyor
  joined,     // Katılmış
  notJoined,  // Katılmamış
}

/// Etkinliğe Katılma Durumu Widget'ı
/// 
/// Net ve anlaşılır UX için tek bir widget ile tüm durumları yönetir:
/// - Kontenjan doldu → Bilgi mesajı
/// - İstek bekliyor → İptal et butonu (turuncu)
/// - Katılmış → Ayrıl butonu (gri)
/// - Katılmamış → Katıl butonu (primary)
/// 
/// Her durumda loading ve error feedback sağlar.
class EventParticipationButton extends StatefulWidget {
  final EventEntity event;
  final String userId;
  final bool isFull;
  final bool hasPendingRequest;
  final bool isParticipant;
  final EventViewModel eventViewModel;
  final AppLocalizations l10n;
  final ThemeData theme;

  const EventParticipationButton({
    super.key,
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
  State<EventParticipationButton> createState() => _EventParticipationButtonState();
}

class _EventParticipationButtonState extends State<EventParticipationButton> {
  bool _isLoading = false;

  /// Katılma durumunu belirle
  ParticipationState get _state {
    if (widget.isFull && !widget.isParticipant && !widget.hasPendingRequest) {
      return ParticipationState.full;
    } else if (widget.hasPendingRequest) {
      return ParticipationState.pending;
    } else if (widget.isParticipant) {
      return ParticipationState.joined;
    } else {
      return ParticipationState.notJoined;
    }
  }

  Future<void> _handleAction() async {
    setState(() => _isLoading = true);

    try {
      final eventEntity = widget.event;
      
      switch (_state) {
        case ParticipationState.pending:
          await widget.eventViewModel.cancelJoinRequest(eventEntity, widget.userId);
          if (mounted) {
            ModernSnackbar.showSuccess(context, widget.l10n.joinRequestCancelled);
          }
          break;
        case ParticipationState.joined:
          await widget.eventViewModel.leaveEvent(eventEntity, widget.userId);
          if (mounted) {
            ModernSnackbar.showSuccess(context, widget.l10n.leftEvent);
          }
          break;
        case ParticipationState.notJoined:
          await widget.eventViewModel.sendJoinRequest(eventEntity, widget.userId);
          if (mounted) {
            ModernSnackbar.showSuccess(context, widget.l10n.joinRequestSent);
          }
          break;
        case ParticipationState.full:
          // No action for full state
          break;
      }
    } catch (e) {
      if (mounted) {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (_state) {
      case ParticipationState.full:
        return _buildFullStateWidget();
      case ParticipationState.pending:
        return _buildPendingButton();
      case ParticipationState.joined:
        return _buildJoinedButton();
      case ParticipationState.notJoined:
        return _buildJoinButton();
    }
  }

  /// Kontenjan doldu durumu
  Widget _buildFullStateWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: widget.theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: widget.theme.colorScheme.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            widget.l10n.quotaFull,
            style: TextStyle(
              color: widget.theme.colorScheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// İstek bekliyor durumu - turuncu tema
  Widget _buildPendingButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleAction,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        foregroundColor: Colors.orange[700],
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.5), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange[700],
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_rounded, color: Colors.orange[700], size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.l10n.requestSent,
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'İptal Et',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Katılmış durumu - gri tema
  Widget _buildJoinedButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _handleAction,
      style: FilledButton.styleFrom(
        backgroundColor: widget.theme.colorScheme.surfaceContainerHighest,
        foregroundColor: widget.theme.colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.theme.colorScheme.onSurface,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green[600],
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Katıldın ✓',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        size: 16,
                        color: widget.theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.l10n.leave,
                        style: TextStyle(
                          color: widget.theme.colorScheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Katılmamış durumu - primary tema
  Widget _buildJoinButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _handleAction,
      style: FilledButton.styleFrom(
        backgroundColor: widget.theme.colorScheme.primary,
        foregroundColor: widget.theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
      ),
      child: _isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.theme.colorScheme.onPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_rounded, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.l10n.sendJoinRequest,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    );
  }
}

