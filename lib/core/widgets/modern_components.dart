import 'package:flutter/material.dart';
import 'dart:ui';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Dark mode için beyaz, light mode için success color
    final color = isDark ? Colors.white : AppColorConfig.successColor;
    _show(context, message, color, Icons.check_circle);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Dark mode'da beyaz arka plan için koyu metin, light mode'da beyaz metin
    final textColor = isDark && color == Colors.white 
        ? Colors.black 
        : Colors.white;
    final iconColor = isDark && color == Colors.white 
        ? Colors.black 
        : Colors.white;
    
    // ✅ Üstten göster: OverlayEntry kullanarak özel bir top snackbar
    _showTopSnackbar(
      context: context,
      message: message,
      color: color,
      icon: icon,
      textColor: textColor,
      iconColor: iconColor,
    );
  }

  /// Üstten gösterilen snackbar (basit slide-down animasyon ile)
  static void _showTopSnackbar({
    required BuildContext context,
    required String message,
    required Color color,
    required IconData icon,
    required Color textColor,
    required Color iconColor,
  }) {
    try {
      // ✅ Context kontrolü
      if (!context.mounted) return;
      
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        // ✅ Fallback: Eğer Overlay bulunamazsa normal SnackBar kullan
        _showFallbackSnackbar(context, message, color, icon, textColor, iconColor);
        return;
      }
      
      late OverlayEntry overlayEntry;
      
      overlayEntry = OverlayEntry(
        builder: (context) => _TopSnackbarWidget(
          message: message,
          color: color,
          icon: icon,
          textColor: textColor,
          iconColor: iconColor,
          onDismiss: () {
            try {
              overlayEntry.remove();
            } catch (_) {
              // OverlayEntry zaten kaldırılmış, sessizce devam et
            }
          },
        ),
      );

      overlay.insert(overlayEntry);
    } catch (e) {
      // ✅ Hata durumunda fallback kullan
      if (context.mounted) {
        _showFallbackSnackbar(context, message, color, icon, textColor, iconColor);
      }
    }
  }

  /// Fallback: Normal SnackBar (Overlay kullanılamazsa)
  static void _showFallbackSnackbar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    Color textColor,
    Color iconColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
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
        margin: EdgeInsets.only(
          left: AppTheme.spacingLg,
          right: AppTheme.spacingLg,
          top: MediaQuery.of(context).padding.top + AppTheme.spacingMd, // ✅ Üstten göster
          bottom: 100.0 + AppTheme.spacingLg,
        ),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }
}

/// Üstten gösterilen snackbar widget (animasyon ile)
class _TopSnackbarWidget extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onDismiss;

  const _TopSnackbarWidget({
    required this.message,
    required this.color,
    required this.icon,
    required this.textColor,
    required this.iconColor,
    required this.onDismiss,
  });

  @override
  State<_TopSnackbarWidget> createState() => _TopSnackbarWidgetState();
}

class _TopSnackbarWidgetState extends State<_TopSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Slide-down animasyon controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5), // Üstten başla (görünmez)
      end: Offset.zero, // Normal pozisyon
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // ✅ Smooth animasyon
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // ✅ Animasyonu başlat
    _animationController.forward();

    // ✅ 3 saniye sonra kapat (animasyon ile)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && (_animationController.isAnimating || _animationController.isCompleted)) {
        _animationController.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppTheme.spacingMd, // ✅ Status bar'dan hemen sonra
      left: AppTheme.spacingLg,
      right: AppTheme.spacingLg,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingMd,
              ),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    Widget dialog = AlertDialog(
      backgroundColor: isDark ? Colors.transparent : null,
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
    );
    
    // Dark mode'da glassmorphism ekle
    if (isDark) {
      dialog = ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: dialog,
          ),
        ),
      );
    }
    
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog,
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
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    Widget dialog = AlertDialog(
      backgroundColor: isDark ? Colors.transparent : null,
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
    );
    
    // Dark mode'da glassmorphism ekle
    if (isDark) {
      dialog = ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: dialog,
          ),
        ),
      );
    }
    
    return showDialog<bool>(
      context: context,
      builder: (context) => dialog,
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
// 🎨 MODERN MODAL BOTTOM SHEET HELPER
// ============================================================================

/// Glassmorphism wrapper for modal bottom sheets in dark mode
class GlassModalBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    Widget content = Container(
      constraints: height != null ? BoxConstraints(maxHeight: height) : null,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingLg),
      child: child,
    );
    
    // Dark mode'da glassmorphism ekle
    if (isDark) {
      content = ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusRound),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusRound),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
            ),
            child: content,
          ),
        ),
      );
    } else {
      content = Container(
        constraints: height != null ? BoxConstraints(maxHeight: height) : null,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusRound),
          ),
        ),
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingLg),
        child: child,
      );
    }
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusRound),
        ),
      ),
      builder: (context) => content,
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
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    final textField = Focus(
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
          fillColor: isDark
              ? Colors.transparent // Dark mode'da şeffaf (glassmorphism için)
              : (_isFocused
                  ? theme.colorScheme.primaryContainer.withAlpha(AppTheme.alphaVeryLight)
                  : theme.colorScheme.surfaceContainerHighest),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium),
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
          // Label kesilmesini önlemek için - label her zaman input içinde kalır
          floatingLabelBehavior: FloatingLabelBehavior.never,
          // Label'ın kesilmemesi için yeterli padding - prefix icon varsa daha fazla padding
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.prefixIcon != null ? 16 : AppTheme.spacingLg,
            vertical: widget.maxLines != null && widget.maxLines! > 1 
                ? 20 
                : 20, // Label için yeterli boşluk
          ),
          isDense: false,
          // Label'ın üstte görünmesi için hint text kullan
          alignLabelWithHint: true,
        ),
      ),
    );
    
    // Dark mode'da glassmorphism ekle
    if (isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: textField,
          ),
        ),
      );
    }
    
    return textField;
  }
}

