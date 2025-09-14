import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Uygulama başlığı
  ///
  /// In tr, this message translates to:
  /// **'Thunder'**
  String get appTitle;

  /// Giriş yap butonu
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// Kayıt ol butonu
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get signUp;

  /// E-posta alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// Şifre alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// Kayıt ol linki
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt ol'**
  String get noAccount;

  /// Giriş yap linki
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get hasAccount;

  /// Profil tamamlama başlığı
  ///
  /// In tr, this message translates to:
  /// **'Profilini Tamamla'**
  String get completeProfile;

  /// İsim alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'İsim Soyisim'**
  String get name;

  /// Biyografi alanı etiketi
  ///
  /// In tr, this message translates to:
  /// **'Biyografi'**
  String get bio;

  /// Profil kaydet butonu
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve Devam Et'**
  String get saveAndContinue;

  /// Ana sayfa tab etiketi
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// Harita tab etiketi
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get map;

  /// Profil tab etiketi
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// Kullanıcı arama butonu
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Ara'**
  String get searchUsers;

  /// Etkinlikler başlığı
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler'**
  String get events;

  /// Etkinlik oluştur butonu
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Oluştur'**
  String get createEvent;

  /// Etkinlik başlığı alanı
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get eventTitle;

  /// Etkinlik açıklaması alanı
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get eventDescription;

  /// Etkinlik adresi alanı
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get eventAddress;

  /// Etkinlik kotası alanı
  ///
  /// In tr, this message translates to:
  /// **'Kota'**
  String get eventQuota;

  /// Etkinlik kategorisi alanı
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get eventCategory;

  /// Etkinlik tarih/saat alanı
  ///
  /// In tr, this message translates to:
  /// **'Tarih/Saat'**
  String get eventDateTime;

  /// Etkinlik konumu alanı
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get eventLocation;

  /// Konum seç butonu
  ///
  /// In tr, this message translates to:
  /// **'Haritadan Konum Seç'**
  String get selectLocation;

  /// Konum seçildi mesajı
  ///
  /// In tr, this message translates to:
  /// **'Konum Seçildi'**
  String get locationSelected;

  /// Etkinliğe katıl butonu
  ///
  /// In tr, this message translates to:
  /// **'Katıl'**
  String get join;

  /// Etkinlikten ayrıl butonu
  ///
  /// In tr, this message translates to:
  /// **'Ayrıl'**
  String get leave;

  /// Katılımcılar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Katılımcılar'**
  String get participants;

  /// Kota dolu durumu
  ///
  /// In tr, this message translates to:
  /// **'Kota Dolu'**
  String get quotaFull;

  /// Mesafe etiketi
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get distance;

  /// Kilometre birimi
  ///
  /// In tr, this message translates to:
  /// **'km'**
  String get km;

  /// Arama butonu
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// Filtrele butonu
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filter;

  /// Tümü filtresi
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// Müzik kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Müzik'**
  String get music;

  /// Spor kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Spor'**
  String get sport;

  /// Yemek kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Yemek'**
  String get food;

  /// Sanat kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Sanat'**
  String get art;

  /// Parti kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Parti'**
  String get party;

  /// Teknoloji kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Teknoloji'**
  String get technology;

  /// Doğa kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Doğa'**
  String get nature;

  /// Eğitim kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Eğitim'**
  String get education;

  /// Oyun kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Oyun'**
  String get game;

  /// Diğer kategorisi
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get other;

  /// Sohbet başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get chat;

  /// Mesaj gönder butonu
  ///
  /// In tr, this message translates to:
  /// **'Mesaj Gönder'**
  String get sendMessage;

  /// Mesaj yazma alanı placeholder
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz...'**
  String get typeMessage;

  /// Takipçi sayısı
  ///
  /// In tr, this message translates to:
  /// **'Takipçi'**
  String get followers;

  /// Takip edilen sayısı
  ///
  /// In tr, this message translates to:
  /// **'Takip'**
  String get following;

  /// Takip et butonu
  ///
  /// In tr, this message translates to:
  /// **'Takip Et'**
  String get follow;

  /// Takibi bırak butonu
  ///
  /// In tr, this message translates to:
  /// **'Takibi Bırak'**
  String get unfollow;

  /// Sohbet başlat butonu
  ///
  /// In tr, this message translates to:
  /// **'Sohbet Başlat'**
  String get startChat;

  /// Düzenle butonu
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// Kaydet butonu
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// İptal butonu
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// Sil butonu
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// Çıkış yap butonu
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// Yükleniyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// Hata başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// Başarı mesajı
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// Veri yok mesajı
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noData;

  /// Tekrar dene butonu
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
