import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';

/// Event cover photo picker widget
/// Handles photo selection, cropping, and uploading with visual feedback
class EventCoverPhotoPicker extends StatelessWidget {
  final String? uploadedPhotoUrl;
  final bool isUploading;
  final VoidCallback onPickPhoto;

  const EventCoverPhotoPicker({
    super.key,
    this.uploadedPhotoUrl,
    required this.isUploading,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GlassContainer(
      borderRadius: AppTheme.radiusXl,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Stack(
          children: [
            // Photo or Placeholder
            GestureDetector(
              onTap: isUploading ? null : onPickPhoto,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: uploadedPhotoUrl != null
                    ? null
                    : BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                            AppColorConfig.secondaryColor.withAlpha(AppTheme.alphaVeryLight),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                child: uploadedPhotoUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            uploadedPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            ),
                          ),
                          // Overlay for change button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(AppTheme.alphaMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: AppColorConfig.primaryColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              l10n.addCoverPhoto,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColorConfig.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXs),
                            Text(
                              l10n.selectFromGalleryOrCamera,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(AppTheme.alphaMedium),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            // Upload Progress Overlay
            if (isUploading)
              Container(
                height: 200,
                color: Colors.black.withAlpha(AppTheme.alphaMedium),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColorConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        l10n.uploadingPhoto,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Change Photo Button (when photo is uploaded)
            if (uploadedPhotoUrl != null && !isUploading)
              Positioned(
                bottom: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                child: FilledButton.icon(
                  onPressed: onPickPhoto,
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(l10n.change),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface.withAlpha(AppTheme.alphaAlmostOpaque),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

