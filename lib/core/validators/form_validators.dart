import '../../l10n/app_localizations.dart';
import 'validation_logic.dart';

class FormValidators {
  static final RegExp _nameRegex = RegExp(
    r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]{2,}$',
  );

  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEmailRequired;
    }

    if (!ValidationLogic.isValidEmail(value.trim())) {
      return l10n.validationEmailInvalid;
    }

    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.validationPasswordRequired;
    }

    if (!ValidationLogic.isValidPasswordLength(value)) {
      return l10n.validationPasswordMinLength;
    }

    if (!ValidationLogic.isStrongPassword(value)) {
      return l10n.validationPasswordStrength;
    }

    return null;
  }

  static String? name(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationNameRequired;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return l10n.validationNameMinLength;
    }

    if (!_nameRegex.hasMatch(trimmedValue)) {
      return l10n.validationNameInvalid;
    }

    return null;
  }

  static String? bio(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (value.length > 500) {
      return l10n.validationBioMaxLength;
    }

    return null;
  }

  static String? title(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationTitleRequired;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 3) {
      return l10n.validationTitleMinLength;
    }

    if (trimmedValue.length > 100) {
      return l10n.validationTitleMaxLength;
    }

    return null;
  }

  static String? description(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationDescriptionRequired;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 10) {
      return l10n.validationDescriptionMinLength;
    }

    if (trimmedValue.length > 2000) {
      return l10n.validationDescriptionMaxLength;
    }

    return null;
  }

  static String? address(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationAddressRequired;
    }

    if (value.trim().length < 5) {
      return l10n.validationAddressMinLength;
    }

    return null;
  }

  static String? quota(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationQuotaRequired;
    }

    final quotaValue = int.tryParse(value.trim());
    if (quotaValue == null) {
      return l10n.validationQuotaInvalid;
    }

    if (quotaValue < 1) {
      return l10n.validationQuotaMin;
    }

    if (quotaValue > 1000) {
      return l10n.validationQuotaMax;
    }

    return null;
  }

  static String? required(
    String? value, {
    required AppLocalizations l10n,
    required String fieldName,
  }) {
    if (value == null || !ValidationLogic.isNotEmpty(value)) {
      return l10n.validationFieldRequired(fieldName);
    }
    return null;
  }

  static String? minLength(
    String? value,
    int minLength, {
    required AppLocalizations l10n,
    required String fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationFieldRequired(fieldName);
    }

    if (!ValidationLogic.hasMinLength(value.trim(), minLength)) {
      return l10n.validationFieldMinLength(fieldName, minLength);
    }

    return null;
  }

  static String? maxLength(
    String? value,
    int maxLength, {
    required AppLocalizations l10n,
    required String fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!ValidationLogic.hasMaxLength(value, maxLength)) {
      return l10n.validationFieldMaxLength(fieldName, maxLength);
    }

    return null;
  }
}
