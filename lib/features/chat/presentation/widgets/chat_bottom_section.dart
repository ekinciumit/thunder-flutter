import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'chat_input_bar.dart';
import 'file_picker_widget.dart';
import 'helpers/voice_recording_helper.dart';

/// Widget that contains the chat input bar, emoji picker, and file picker
class ChatBottomSection extends StatelessWidget {
  final TextEditingController textController;
  final bool showEmojiPicker;
  final bool isShowingFilePicker;
  final VoiceRecordingHelper voiceRecordingHelper;
  final VoidCallback onEmojiPickerToggle;
  final VoidCallback onSendTextMessage;
  final VoidCallback onVoiceRecordingCancel;
  final VoidCallback onVoiceRecordingStopAndSend;
  final VoidCallback onVoiceRecordingStart;
  final void Function(double offset, bool isCancelling) onVoiceRecordingSwipeUpdate;
  final void Function(ImageSource source, {bool isVideo}) onPickMedia;
  final VoidCallback onShowFilePicker;
  final void Function(bool) onEmojiPickerChanged;
  final void Function(Emoji) onEmojiSelected;
  final void Function(PlatformFile) onFileSelected;
  final VoidCallback onHideFilePicker;

  const ChatBottomSection({
    super.key,
    required this.textController,
    required this.showEmojiPicker,
    required this.isShowingFilePicker,
    required this.voiceRecordingHelper,
    required this.onEmojiPickerToggle,
    required this.onSendTextMessage,
    required this.onVoiceRecordingCancel,
    required this.onVoiceRecordingStopAndSend,
    required this.onVoiceRecordingStart,
    required this.onVoiceRecordingSwipeUpdate,
    required this.onPickMedia,
    required this.onShowFilePicker,
    required this.onEmojiPickerChanged,
    required this.onEmojiSelected,
    required this.onFileSelected,
    required this.onHideFilePicker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatInputBar(
          textController: textController,
          showEmojiPicker: showEmojiPicker,
          isRecordingVoice: voiceRecordingHelper.isRecording,
          isCancellingBySwipe: voiceRecordingHelper.isCancellingBySwipe,
          voiceRecordingDuration: voiceRecordingHelper.duration,
          voiceRecordingSwipeOffset: voiceRecordingHelper.swipeOffset,
          onEmojiPickerToggle: onEmojiPickerToggle,
          onSendTextMessage: onSendTextMessage,
          onVoiceRecordingCancel: onVoiceRecordingCancel,
          onVoiceRecordingStopAndSend: onVoiceRecordingStopAndSend,
          onVoiceRecordingStart: onVoiceRecordingStart,
          onVoiceRecordingSwipeUpdate: onVoiceRecordingSwipeUpdate,
          onPickMedia: onPickMedia,
          onShowFilePicker: onShowFilePicker,
          onEmojiPickerChanged: onEmojiPickerChanged,
          onEmojiSelected: onEmojiSelected,
        ),
        if (showEmojiPicker)
          SizedBox(
            height: 280,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => onEmojiSelected(emoji),
              config: const Config(),
            ),
          ),
        if (isShowingFilePicker)
          Container(
            padding: const EdgeInsets.all(16),
            child: FilePickerWidget(
              onFileSelected: onFileSelected,
              onClose: onHideFilePicker,
            ),
          ),
      ],
    );
  }
}

