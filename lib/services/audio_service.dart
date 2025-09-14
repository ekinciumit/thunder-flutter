import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  String? _currentPlayingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get currentPlayingPath => _currentPlayingPath;

  /// Mikrofon izni iste
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// Ses kaydı başlat
  Future<bool> startRecording() async {
    try {
      if (_isRecording) return false;

      // İzin kontrolü
      if (!await requestMicrophonePermission()) {
        throw Exception('Mikrofon izni gerekli');
      }

      // Geçici dosya yolu oluştur
      final directory = await getTemporaryDirectory();
      final fileName = 'voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = path.join(directory.path, fileName);

      // Kayıt başlat
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('Ses kaydı başlatma hatası: $e');
      return false;
    }
  }

  /// Ses kaydı durdur
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null && File(path).existsSync()) {
        return path;
      }
      
      return null;
    } catch (e) {
      debugPrint('Ses kaydı durdurma hatası: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Ses kaydı iptal et
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.cancel();
        _isRecording = false;
      }
      
      if (_currentRecordingPath != null && File(_currentRecordingPath!).existsSync()) {
        await File(_currentRecordingPath!).delete();
        _currentRecordingPath = null;
      }
    } catch (e) {
      debugPrint('Ses kaydı iptal etme hatası: $e');
    }
  }

  /// Ses dosyası oynat
  Future<void> playAudio(String filePath) async {
    try {
      if (_isPlaying && _currentPlayingPath == filePath) {
        // Aynı dosya çalıyorsa durdur
        await stopAudio();
        return;
      }

      // Önceki çalan dosyayı durdur
      if (_isPlaying) {
        await stopAudio();
      }

      _currentPlayingPath = filePath;
      _isPlaying = true;

      await _player.play(DeviceFileSource(filePath));
      
      // Oynatma bittiğinde durumu güncelle
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPlayingPath = null;
      });
    } catch (e) {
      debugPrint('Ses oynatma hatası: $e');
      _isPlaying = false;
      _currentPlayingPath = null;
    }
  }

  /// Ses oynatmayı durdur
  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPlayingPath = null;
    } catch (e) {
      debugPrint('Ses durdurma hatası: $e');
    }
  }

  /// Ses dosyası süresini al
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      await _player.setSource(DeviceFileSource(filePath));
      return await _player.getDuration();
    } catch (e) {
      debugPrint('Ses süresi alma hatası: $e');
      return null;
    }
  }

  /// Kaynakları temizle
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}



