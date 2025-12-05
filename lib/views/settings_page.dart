import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../core/widgets/modern_components.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/settings_service.dart';
import '../services/feedback_service.dart';
import '../services/user_service.dart';
import '../l10n/app_localizations.dart';
import 'blocked_users_page.dart';

/// Ayarlar Sayfası
/// 
/// Kullanıcı ayarları, gizlilik, yardım ve çıkış işlemleri
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColorConfig.primaryColor,
        foregroundColor: AppColorConfig.cardColor,
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          
          // Hesap Bölümü
          _buildSectionHeader(l10n.account, theme),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: l10n.editProfile,
            subtitle: l10n.editProfileSubtitle,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: l10n.changePassword,
            subtitle: l10n.accountSecurity,
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user?.email != null) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: user!.email!,
                  );
                  if (context.mounted) {
                    ModernSnackbar.showSuccess(context, l10n.passwordResetSent);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ModernSnackbar.showError(context, '${l10n.error}: $e');
                  }
                }
              } else {
                ModernSnackbar.showError(context, l10n.emailNotFound);
              }
            },
          ),
          
          const Divider(height: AppTheme.spacingXl),
          
          // Bildirimler Bölümü
          _buildSectionHeader(l10n.notifications, theme),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: l10n.notificationSettings,
            subtitle: l10n.notificationSettingsSubtitle,
            onTap: () => _showNotificationSettings(context, l10n),
          ),
          
          const Divider(height: AppTheme.spacingXl),
          
          // Görünüm Bölümü
          _buildSectionHeader(l10n.appearance, theme),
          Consumer<ThemeService>(
            builder: (context, themeService, _) => _buildSettingsTile(
              icon: Icons.dark_mode_outlined,
              title: l10n.darkMode,
              subtitle: themeService.isDark ? l10n.on : l10n.off,
              onTap: () => themeService.toggleTheme(),
              trailing: Switch(
                value: themeService.isDark,
                activeTrackColor: AppColorConfig.primaryColor,
                onChanged: (v) => themeService.toggleTheme(),
              ),
            ),
          ),
          Consumer<LanguageService>(
            builder: (context, languageService, _) => _buildSettingsTile(
              icon: Icons.language,
              title: l10n.language,
              subtitle: languageService.isTurkish ? 'Türkçe' : 'English',
              onTap: () => _showLanguageSelector(context, languageService, l10n),
            ),
          ),
          
          const Divider(height: AppTheme.spacingXl),
          
          // Gizlilik ve Güvenlik
          _buildSectionHeader(l10n.privacySecurity, theme),
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: l10n.privacySettings,
            subtitle: l10n.accountPrivacy,
            onTap: () => _showPrivacySettings(context, l10n),
          ),
          _buildSettingsTile(
            icon: Icons.block,
            title: l10n.blockedUsers,
            subtitle: l10n.manageBlockList,
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlockedUsersPage(currentUserId: user.uid),
                  ),
                );
              }
            },
          ),
          
          const Divider(height: AppTheme.spacingXl),
          
          // Yardım ve Destek
          _buildSectionHeader(l10n.helpSupport, theme),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: l10n.helpCenter,
            subtitle: l10n.faq,
            onTap: () => _openUrl(context, 'https://thunder-app.com/help', l10n),
          ),
          _buildSettingsTile(
            icon: Icons.bug_report_outlined,
            title: l10n.reportProblem,
            subtitle: l10n.reportProblemSubtitle,
            onTap: () => _showFeedbackDialog(context, l10n),
          ),
          
          const Divider(height: AppTheme.spacingXl),
          
          // Yasal
          _buildSectionHeader(l10n.legal, theme),
          _buildSettingsTile(
            icon: Icons.policy_outlined,
            title: l10n.privacyPolicy,
            onTap: () => _openUrl(context, 'https://thunder-app.com/privacy', l10n),
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: l10n.termsOfService,
            onTap: () => _openUrl(context, 'https://thunder-app.com/terms', l10n),
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: l10n.about,
            subtitle: '${l10n.version} 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Thunder',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColorConfig.gradientPrimary,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 40),
                ),
                applicationLegalese: '© 2024 Thunder.',
              );
            },
          ),
          
          const Divider(height: AppTheme.spacingXl),
          
          // Çıkış Yap - En altta
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logout),
                    content: Text(l10n.logoutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColorConfig.errorColor,
                        ),
                        child: Text(l10n.logout),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await authViewModel.signOut();
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColorConfig.errorColor,
                side: const BorderSide(color: AppColorConfig.errorColor),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: AppColorConfig.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColorConfig.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLanguageSelector(BuildContext context, LanguageService languageService, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.selectLanguage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Türkçe'),
              trailing: languageService.isTurkish 
                  ? const Icon(Icons.check, color: AppColorConfig.primaryColor)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await languageService.setTurkish();
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: languageService.isEnglish 
                  ? const Icon(Icons.check, color: AppColorConfig.primaryColor)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await languageService.setEnglish();
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }

  void _showPrivacySettings(BuildContext context, AppLocalizations l10n) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    
    if (currentUser == null) {
      ModernSnackbar.showError(context, l10n.userInfoNotFound);
      return;
    }
    
    final userService = UserService();
    
    bool isPrivateAccount = currentUser.isPrivate;
    bool showLocation = currentUser.showLocation;
    bool showOnlineStatus = currentUser.showOnlineStatus;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  l10n.privacySettings,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                SwitchListTile(
                  title: Text(l10n.privateAccount),
                  subtitle: Text(l10n.privateAccountSubtitle),
                  value: isPrivateAccount,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) async {
                    setState(() => isPrivateAccount = v);
                    try {
                      await userService.setPrivateAccount(currentUser.uid, v);
                      authViewModel.updateUserPrivacy(isPrivate: v);
                      if (context.mounted) {
                        ModernSnackbar.showSuccess(
                          context, 
                          v ? l10n.accountMadePrivate : l10n.accountMadePublic,
                        );
                      }
                    } catch (e) {
                      setState(() => isPrivateAccount = !v);
                      if (context.mounted) {
                        ModernSnackbar.showError(context, l10n.settingUpdateFailed);
                      }
                    }
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.showLocation),
                  subtitle: Text(l10n.showLocationSubtitle),
                  value: showLocation,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) async {
                    setState(() => showLocation = v);
                    try {
                      await userService.setShowLocation(currentUser.uid, v);
                      authViewModel.updateUserPrivacy(showLocation: v);
                      if (context.mounted) {
                        ModernSnackbar.showSuccess(
                          context, 
                          v ? l10n.locationShown : l10n.locationHidden,
                        );
                      }
                    } catch (e) {
                      setState(() => showLocation = !v);
                      if (context.mounted) {
                        ModernSnackbar.showError(context, l10n.settingUpdateFailed);
                      }
                    }
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.onlineStatus),
                  subtitle: Text(l10n.onlineStatusSubtitle),
                  value: showOnlineStatus,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) async {
                    setState(() => showOnlineStatus = v);
                    try {
                      await userService.setShowOnlineStatus(currentUser.uid, v);
                      authViewModel.updateUserPrivacy(showOnlineStatus: v);
                      if (context.mounted) {
                        ModernSnackbar.showSuccess(
                          context, 
                          v ? l10n.onlineStatusShown : l10n.onlineStatusHidden,
                        );
                      }
                    } catch (e) {
                      setState(() => showOnlineStatus = !v);
                      if (context.mounted) {
                        ModernSnackbar.showError(context, l10n.settingUpdateFailed);
                      }
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
      ),
      builder: (context) => Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  l10n.notificationSettings,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                SwitchListTile(
                  title: Text(l10n.pushNotifications),
                  subtitle: Text(l10n.appNotifications),
                  value: settingsService.pushEnabled,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) => settingsService.setPushEnabled(v),
                ),
                SwitchListTile(
                  title: Text(l10n.emailNotifications),
                  subtitle: Text(l10n.importantUpdates),
                  value: settingsService.emailEnabled,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) => settingsService.setEmailEnabled(v),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(l10n.eventReminders),
                  value: settingsService.eventReminders,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) => settingsService.setEventReminders(v),
                ),
                SwitchListTile(
                  title: Text(l10n.newFollowers),
                  value: settingsService.newFollowers,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) => settingsService.setNewFollowers(v),
                ),
                SwitchListTile(
                  title: Text(l10n.messages),
                  value: settingsService.messages,
                  activeTrackColor: AppColorConfig.primaryColor,
                  onChanged: (v) => settingsService.setMessages(v),
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    String selectedType = FeedbackService.typeGeneral;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.reportProblem),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.feedbackType),
              const SizedBox(height: AppTheme.spacingSm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: FeedbackService.typeBug,
                    label: Text(l10n.bugReport),
                    icon: const Icon(Icons.bug_report, size: 18),
                  ),
                  ButtonSegment(
                    value: FeedbackService.typeSuggestion,
                    label: Text(l10n.suggestion),
                    icon: const Icon(Icons.lightbulb, size: 18),
                  ),
                  ButtonSegment(
                    value: FeedbackService.typeGeneral,
                    label: Text(l10n.other),
                    icon: const Icon(Icons.chat, size: 18),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => selectedType = newSelection.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(l10n.description),
              const SizedBox(height: AppTheme.spacingSm),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.feedbackHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ModernSnackbar.showError(context, l10n.pleaseEnterDescription);
                  return;
                }
                
                Navigator.pop(context);
                ModernSnackbar.showInfo(context, l10n.sending);
                
                final feedbackService = FeedbackService();
                final success = await feedbackService.submitFeedback(
                  message: controller.text.trim(),
                  type: selectedType,
                );
                
                if (context.mounted) {
                  if (success) {
                    ModernSnackbar.showSuccess(context, l10n.thankYouFeedback);
                  } else {
                    ModernSnackbar.showError(context, l10n.sendError);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorConfig.primaryColor,
                foregroundColor: AppColorConfig.cardColor,
              ),
              child: Text(l10n.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url, AppLocalizations l10n) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ModernSnackbar.showInfo(context, l10n.comingSoon);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ModernSnackbar.showInfo(context, l10n.comingSoon);
      }
    }
  }
}
