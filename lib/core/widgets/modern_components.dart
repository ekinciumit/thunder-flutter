import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../theme/app_color_config.dart';

/// Modern UI Components Library
/// 
/// Material Design 3 standartlarına uygun, en güncel component'ler
/// Tüm uygulama genelinde tutarlı kullanım için

// ============================================================================
// 🎨 MODERN SNACKBAR
// ============================================================================

class ModernSnackbar {
  /// Success Snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColorConfig.successColor, Icons.check_circle);
  }

  /// Error Snackbar
  static void showError(BuildContext context, String message) {
    _show(context, message, AppColorConfig.errorColor, Icons.error);
  }

  /// Warning Snackbar
  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppColorConfig.warningColor, Icons.warning);
  }

  /// Info Snackbar
  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColorConfig.infoColor, Icons.info);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingLg),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }
}

// ============================================================================
// 🎨 MODERN DIALOG
// ============================================================================

class ModernDialog {
  /// Alert Dialog
  static Future<bool?> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Tamam',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor ?? AppColorConfig.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmation Dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Evet',
    String cancelText = 'İptal',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: AppColorConfig.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? AppColorConfig.primaryColor,
            ),
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Image Source Selection Dialog
  static Future<ImageSource?> showImageSource({
    required BuildContext context,
    required String title,
  }) {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🎨 EMPTY STATE WIDGET
// ============================================================================

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? textColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;
    final txtColor = textColor ?? theme.colorScheme.onSurface;
    final txtVariantColor = textColor?.withAlpha(AppTheme.alphaVeryDark) ?? theme.colorScheme.onSurfaceVariant;
    final iconClr = iconColor ?? (textColor ?? theme.colorScheme.primary).withAlpha(AppTheme.alphaMedium);
    
    return bgColor == Colors.transparent
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: iconClr,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: txtColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: txtVariantColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if ((actionText != null || actionLabel != null) && onAction != null) ...[
                    const SizedBox(height: AppTheme.spacingXxl),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.add),
                      label: Text(actionLabel ?? actionText ?? 'Devam Et'),
                      style: FilledButton.styleFrom(
                        backgroundColor: textColor != null 
                            ? Colors.white.withAlpha(AppTheme.alphaMedium)
                            : theme.colorScheme.primary,
                        foregroundColor: textColor ?? Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXxl,
                          vertical: AppTheme.spacingLg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        : Container(
            color: bgColor,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 64,
                      color: iconClr,
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: txtColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: txtVariantColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if ((actionText != null || actionLabel != null) && onAction != null) ...[
                      const SizedBox(height: AppTheme.spacingXxl),
                      FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.add),
                        label: Text(actionLabel ?? actionText ?? 'Devam Et'),
                        style: FilledButton.styleFrom(
                          backgroundColor: textColor != null 
                              ? Colors.white.withAlpha(AppTheme.alphaMedium)
                              : theme.colorScheme.primary,
                          foregroundColor: textColor ?? Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXxl,
                            vertical: AppTheme.spacingLg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
  }
}

// ============================================================================
// 🎨 ERROR STATE WIDGET
// ============================================================================

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;
  final String? error;
  final Color? backgroundColor;
  final Color? textColor;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText,
    this.error,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;
    final txtColor = textColor ?? theme.colorScheme.onSurface;
    final txtVariantColor = textColor?.withAlpha(AppTheme.alphaVeryDark) ?? theme.colorScheme.onSurfaceVariant;
    
    return bgColor == Colors.transparent
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: (textColor ?? AppColorConfig.errorColor).withAlpha(AppTheme.alphaMedium),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text(
                    'Bir hata oluştu',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: txtColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: txtVariantColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: txtVariantColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: AppTheme.spacingXxl),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(retryText ?? 'Tekrar Dene'),
                      style: FilledButton.styleFrom(
                        backgroundColor: textColor != null 
                            ? Colors.white.withAlpha(AppTheme.alphaMedium)
                            : AppColorConfig.errorColor,
                        foregroundColor: textColor ?? Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXxl,
                          vertical: AppTheme.spacingLg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        : Container(
            color: bgColor,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: (textColor ?? AppColorConfig.errorColor).withAlpha(AppTheme.alphaMedium),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    Text(
                      'Bir hata oluştu',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: txtColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: txtVariantColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: txtVariantColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (onRetry != null) ...[
                      const SizedBox(height: AppTheme.spacingXxl),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: Text(retryText ?? 'Tekrar Dene'),
                        style: FilledButton.styleFrom(
                          backgroundColor: textColor != null 
                              ? Colors.white.withAlpha(AppTheme.alphaMedium)
                              : AppColorConfig.errorColor,
                          foregroundColor: textColor ?? Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXxl,
                            vertical: AppTheme.spacingLg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
  }
}

// ============================================================================
// 🎨 MODERN INPUT FIELD
// ============================================================================

class ModernInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;

  const ModernInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<ModernInputField> createState() => _ModernInputFieldState();
}

class _ModernInputFieldState extends State<ModernInputField> {
  bool _obscureText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode?.hasFocus ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        onTap: widget.onTap,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : widget.suffixIcon,
          filled: true,
          fillColor: _isFocused
              ? theme.colorScheme.primaryContainer.withAlpha(AppTheme.alphaVeryLight)
              : theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(
              color: AppColorConfig.errorColor,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(
              color: AppColorConfig.errorColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingLg,
          ),
        ),
      ),
    );
  }
}

