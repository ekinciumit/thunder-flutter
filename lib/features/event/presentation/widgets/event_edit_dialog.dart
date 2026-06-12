import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../../domain/entities/event_entity.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/modern_loading_widget.dart';

/// Dialog for editing an event
class EventEditDialog {
  static void show(
    BuildContext context, {
    required EventEntity event,
    required EventViewModel eventViewModel,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: event.title);
    final descController = TextEditingController(text: event.description);
    final addressController = TextEditingController(text: event.address);
    final quotaController = TextEditingController(text: event.quota.toString());
    DateTime tempDate = event.datetime;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool dialogIsUploading = false;
        String? dialogUploadedPhotoUrl = event.coverPhotoUrl;

        Future<void> pickPhoto() async {
          // Önce galeri veya kamera seçimi göster
          final source = await ModernDialog.showImageSource(
            context: dialogContext,
            title: l10n.selectPhoto,
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
                  toolbarTitle: l10n.cropPhoto,
                  toolbarColor: theme.colorScheme.primary,
                  toolbarWidgetColor: theme.colorScheme.onPrimary,
                  initAspectRatio: CropAspectRatioPreset.ratio16x9,
                  lockAspectRatio: false, // Serbest kırpma
                ),
                IOSUiSettings(
                  title: l10n.cropPhoto,
                  aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
                ),
              ],
            );

            if (croppedFile != null) {
              dialogIsUploading = true;
              if (!dialogContext.mounted) return;

              try {
                final file = File(croppedFile.path);
                // Clean Architecture: ViewModel üzerinden yükle
                final url = await eventViewModel.uploadEventPhoto(file.path, event.id);

                if (!dialogContext.mounted) return;
                dialogIsUploading = false;
                if (url != null) {
                  dialogUploadedPhotoUrl = url;
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.photoUploaded),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.photoUploadFailed),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                dialogIsUploading = false;
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.photoUploadError(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.editEvent),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: dialogIsUploading
                        ? null
                        : () async {
                            await pickPhoto();
                            setDialogState(() {});
                          },
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.deepPurple.withAlpha(40)),
                        color: Colors.deepPurple.withAlpha(10),
                      ),
                      child: dialogIsUploading
                          ? Center(
                              child: ModernLoadingWidget(
                                size: 32,
                                message: l10n.uploading,
                                showMessage: false,
                              ),
                            )
                          : (dialogUploadedPhotoUrl != null && dialogUploadedPhotoUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    dialogUploadedPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
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
                    label: l10n.eventTitle,
                  ),
                  const SizedBox(height: 8),
                  ModernInputField(
                    controller: descController,
                    label: l10n.eventDescription,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  ModernInputField(
                    controller: addressController,
                    label: l10n.eventAddress,
                  ),
                  const SizedBox(height: 8),
                  ModernInputField(
                    controller: quotaController,
                    label: l10n.eventQuota,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${tempDate.day}.${tempDate.month}.${tempDate.year} - ${tempDate.hour.toString().padLeft(2, '0')}:${tempDate.minute.toString().padLeft(2, '0')}',
                    ),
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
                          setDialogState(() {
                            tempDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
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
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: dialogIsUploading
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final updatedEvent = event.copyWith(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          address: addressController.text.trim(),
                          quota: int.tryParse(quotaController.text.trim()) ?? event.quota,
                          coverPhotoUrl: dialogUploadedPhotoUrl,
                          datetime: tempDate,
                        );
                        await eventViewModel.updateEvent(updatedEvent);
                        if (!context.mounted) return;
                        navigator.pop();
                      },
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    );
  }
}
