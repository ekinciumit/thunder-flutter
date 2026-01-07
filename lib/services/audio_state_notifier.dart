import 'package:flutter/foundation.dart';

/// Notifier for audio playback state changes
/// Allows widgets to listen to which audio is currently playing
class AudioStateNotifier extends ChangeNotifier {
  String? _currentlyPlayingUrl;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  String? get currentlyPlayingUrl => _currentlyPlayingUrl;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;

  /// Check if a specific URL is currently playing
  bool isUrlPlaying(String url) {
    return _isPlaying && _currentlyPlayingUrl == url;
  }

  /// Update playing state
  void updatePlayingState({
    String? url,
    bool isPlaying = false,
    Duration currentPosition = Duration.zero,
    Duration totalDuration = Duration.zero,
  }) {
    _currentlyPlayingUrl = url;
    _isPlaying = isPlaying;
    _currentPosition = currentPosition;
    _totalDuration = totalDuration;
    notifyListeners();
  }

  /// Stop playing
  void stop() {
    _currentlyPlayingUrl = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
  }
}

