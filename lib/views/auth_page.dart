import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../core/validators/form_validators.dart';
import '../core/widgets/responsive_widgets.dart';
import '../core/utils/responsive_helper.dart';
import '../core/theme/app_theme.dart';
import 'widgets/app_card.dart';
import 'widgets/app_gradient_container.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AppCard(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getWidth(context, 4),
                vertical: ResponsiveHelper.getHeight(context, 4),
              ),
              padding: ResponsiveHelper.getPadding(context),
              borderRadius: ResponsiveHelper.getBorderRadius(context, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Container(
                    padding: ResponsiveHelper.getPadding(context),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withAlpha(AppTheme.alphaMediumDark),
                          theme.colorScheme.secondary.withAlpha(AppTheme.alphaMediumLight),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLogin ? Icons.login : Icons.person_add,
                      size: ResponsiveHelper.getIconSize(context, 48),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  ResponsiveSizedBox.spacing(),
                  Text(
                    isLogin ? l10n.login : l10n.signUp,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  ResponsiveSizedBox(
                    height: ResponsiveHelper.getSpacing(context) * 2,
                  ),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.email,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: theme.colorScheme.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.primary.withAlpha(AppTheme.alphaVeryLight),
                      prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                      errorStyle: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  ResponsiveSizedBox.spacing(),
                  TextFormField(
                    controller: passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
                    obscureText: true,
                    validator: isLogin 
                        ? (value) => FormValidators.required(value, fieldName: 'Şifre')
                        : FormValidators.password,
                    onFieldSubmitted: (_) {
                      if (_formKey.currentState!.validate()) {
                        _handleSubmit(authViewModel);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      labelStyle: TextStyle(color: theme.colorScheme.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide(color: theme.colorScheme.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.secondary.withAlpha(AppTheme.alphaVeryLight),
                      prefixIcon: Icon(Icons.lock, color: theme.colorScheme.secondary),
                      errorStyle: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (authViewModel.error != null)
                    AppCard(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      borderRadius: 12,
                      gradientColors: [theme.colorScheme.error.withAlpha(20), theme.colorScheme.error.withAlpha(10)],
                      child: Row(
                        children: [
                          Icon(Icons.error, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authViewModel.error!,
                              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ResponsiveSizedBox.spacing(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleSubmit(authViewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getBorderRadius(context, 16),
                          ),
                        ),
                        padding: ResponsiveHelper.getVerticalPadding(context),
                      ),
                      child: Text(
                        isLogin ? l10n.login : l10n.signUp,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ),
                    ),
                  ResponsiveSizedBox.spacing(),
                  TextButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      setState(() {
                        isLogin = !isLogin;
                        authViewModel.error = null; // Toggle'da hatayı temizle
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface.withAlpha(0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 12),
                        ),
                      ),
                    ),
                    child: Text(
                      isLogin ? l10n.noAccount : l10n.hasAccount,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Form submit handler
  /// 
  /// Form validasyonunu kontrol eder ve geçerliyse auth işlemini başlatır
  Future<void> _handleSubmit(AuthViewModel authViewModel) async {
    if (!_formKey.currentState!.validate()) {
      return; // Form geçersizse işlem yapma
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    
    if (isLogin) {
      await authViewModel.signIn(email, password);
    } else {
      await authViewModel.signUp(email, password);
    }
  }
} 