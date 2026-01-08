import 'package:flutter/material.dart';
import '../../../../core/validators/form_validators.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';

/// Event form fields section widget
/// Contains title, description, address, and quota input fields
class EventFormFieldsSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController addressController;
  final TextEditingController quotaController;
  final AppLocalizations? l10n;

  const EventFormFieldsSection({
    super.key,
    required this.titleController,
    required this.descController,
    required this.addressController,
    required this.quotaController,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppTheme.radiusLg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingLg,
      ),
      child: Column(
        children: [
          ModernInputField(
            controller: titleController,
            label: l10n?.eventTitle ?? 'Event Title',
            textInputAction: TextInputAction.next,
            validator: FormValidators.title,
            prefixIcon: Icon(Icons.title, color: AppColorConfig.primaryColor),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ModernInputField(
            controller: descController,
            label: l10n?.eventDescription ?? 'Description',
            textInputAction: TextInputAction.next,
            maxLines: 3,
            validator: FormValidators.description,
            prefixIcon: Icon(Icons.description, color: AppColorConfig.secondaryColor),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ModernInputField(
            controller: addressController,
            label: l10n?.eventAddress ?? 'Address',
            textInputAction: TextInputAction.next,
            validator: FormValidators.address,
            prefixIcon: Icon(Icons.location_on, color: AppColorConfig.tertiaryColor),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ModernInputField(
            controller: quotaController,
            label: l10n?.eventQuota ?? 'Quota',
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            validator: FormValidators.quota,
            prefixIcon: Icon(Icons.people, color: AppColorConfig.primaryColor),
          ),
        ],
      ),
    );
  }
}

