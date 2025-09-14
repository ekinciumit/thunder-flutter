import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLocale = languageService.currentLocale;
    
    return PopupMenuButton<Locale>(
      icon: Icon(
        Icons.language,
        color: Theme.of(context).colorScheme.primary,
      ),
      tooltip: 'Dil Seç',
      onSelected: (Locale locale) async {
        await languageService.changeLanguage(locale);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale.languageCode == 'tr' 
                  ? 'Dil Türkçe olarak değiştirildi' 
                  : 'Language changed to English'
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<Locale>(
          value: const Locale('tr', ''),
          child: Row(
            children: [
              Text('🇹🇷'),
              const SizedBox(width: 8),
              Text('Türkçe'),
              if (currentLocale.languageCode == 'tr') ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('en', ''),
          child: Row(
            children: [
              Text('🇺🇸'),
              const SizedBox(width: 8),
              Text('English'),
              if (currentLocale.languageCode == 'en') ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
