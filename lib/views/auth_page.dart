import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../core/validators/form_validators.dart';
import '../core/widgets/responsive_widgets.dart';
import '../core/utils/responsive_helper.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/modern_components.dart';
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
      gradientColors: AppTheme.gradientPrimary,
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
                  const SizedBox(height: AppTheme.spacingXxl),
                  ModernInputField(
                    controller: emailController,
                    label: l10n.email,
                    hint: 'ornek@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.email,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  ModernInputField(
                    controller: passwordController,
                    label: l10n.password,
                    hint: '••••••••',
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
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (authViewModel.error != null) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: theme.colorScheme.error.withAlpha(AppTheme.alphaMedium),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Text(
                              authViewModel.error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingXxl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: authViewModel.isLoading 
                          ? null 
                          : () => _handleSubmit(authViewModel),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingLg,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                      ),
                      child: authViewModel.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              isLogin ? l10n.login : l10n.signUp,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  TextButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      setState(() {
                        isLogin = !isLogin;
                        authViewModel.error = null;
                      });
                    },
                    child: Text(
                      isLogin ? l10n.noAccount : l10n.hasAccount,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
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