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

  /// Kayıt başarılı mesajı
  ///
  /// In tr, this message translates to:
  /// **'Kaydınız başarıyla oluşturuldu! Giriş yapılıyor...'**
  String get signUpSuccess;

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

  /// Ayarlar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// Hesap bölümü
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get account;

  /// Profil düzenle butonu
  ///
  /// In tr, this message translates to:
  /// **'Profil Düzenle'**
  String get editProfile;

  /// Profil düzenle alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'İsim, biyografi, fotoğraf'**
  String get editProfileSubtitle;

  /// Şifre değiştir butonu
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get changePassword;

  /// Hesap güvenliği alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hesap güvenliği'**
  String get accountSecurity;

  /// Bildirimler bölümü
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// Bildirim ayarları butonu
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Ayarları'**
  String get notificationSettings;

  /// Bildirim ayarları alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Push bildirimleri, e-posta'**
  String get notificationSettingsSubtitle;

  /// Görünüm bölümü
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get appearance;

  /// Gece modu butonu
  ///
  /// In tr, this message translates to:
  /// **'Gece Modu'**
  String get darkMode;

  /// Açık durumu
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get on;

  /// Kapalı durumu
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get off;

  /// Dil butonu
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// Dil seçin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get selectLanguage;

  /// Gizlilik ve güvenlik bölümü
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ve Güvenlik'**
  String get privacySecurity;

  /// Gizlilik ayarları butonu
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Ayarları'**
  String get privacySettings;

  /// Hesap gizliliği alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hesap gizliliği'**
  String get accountPrivacy;

  /// Engellenen kullanıcılar butonu
  ///
  /// In tr, this message translates to:
  /// **'Engellenen Kullanıcılar'**
  String get blockedUsers;

  /// Engel listesi alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Engel listesini yönet'**
  String get manageBlockList;

  /// Yardım ve destek bölümü
  ///
  /// In tr, this message translates to:
  /// **'Yardım ve Destek'**
  String get helpSupport;

  /// Yardım merkezi butonu
  ///
  /// In tr, this message translates to:
  /// **'Yardım Merkezi'**
  String get helpCenter;

  /// SSS alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sıkça sorulan sorular'**
  String get faq;

  /// Sorun bildir butonu
  ///
  /// In tr, this message translates to:
  /// **'Sorun Bildir'**
  String get reportProblem;

  /// Sorun bildir alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hata veya öneri gönder'**
  String get reportProblemSubtitle;

  /// Yasal bölümü
  ///
  /// In tr, this message translates to:
  /// **'Yasal'**
  String get legal;

  /// Gizlilik politikası butonu
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// Kullanım şartları butonu
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Şartları'**
  String get termsOfService;

  /// Hakkında butonu
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// Versiyon etiketi
  ///
  /// In tr, this message translates to:
  /// **'Versiyon'**
  String get version;

  /// Çıkış onay mesajı
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızdan çıkış yapmak istediğinize emin misiniz?'**
  String get logoutConfirm;

  /// Push bildirimleri
  ///
  /// In tr, this message translates to:
  /// **'Push Bildirimleri'**
  String get pushNotifications;

  /// Uygulama bildirimleri alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Uygulama bildirimleri'**
  String get appNotifications;

  /// E-posta bildirimleri
  ///
  /// In tr, this message translates to:
  /// **'E-posta Bildirimleri'**
  String get emailNotifications;

  /// Önemli güncellemeler alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Önemli güncellemeler'**
  String get importantUpdates;

  /// Etkinlik hatırlatıcıları
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Hatırlatıcıları'**
  String get eventReminders;

  /// Yeni takipçiler
  ///
  /// In tr, this message translates to:
  /// **'Yeni Takipçiler'**
  String get newFollowers;

  /// Mesajlar
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get messages;

  /// Gizli hesap
  ///
  /// In tr, this message translates to:
  /// **'Gizli Hesap'**
  String get privateAccount;

  /// Gizli hesap alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sadece takipçileriniz profilinizi görebilir'**
  String get privateAccountSubtitle;

  /// Konumu göster
  ///
  /// In tr, this message translates to:
  /// **'Konumu Göster'**
  String get showLocation;

  /// Konumu göster alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Etkinliklerde konumunuzu paylaşın'**
  String get showLocationSubtitle;

  /// Çevrimiçi durumu
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi Durumu'**
  String get onlineStatus;

  /// Çevrimiçi durumu alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Aktif olduğunuzda diğerleri görsün'**
  String get onlineStatusSubtitle;

  /// Geri bildirim türü
  ///
  /// In tr, this message translates to:
  /// **'Geri bildirim türü:'**
  String get feedbackType;

  /// Hata türü
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get bugReport;

  /// Öneri türü
  ///
  /// In tr, this message translates to:
  /// **'Öneri'**
  String get suggestion;

  /// Açıklama etiketi
  ///
  /// In tr, this message translates to:
  /// **'Açıklama:'**
  String get description;

  /// Geri bildirim ipucu
  ///
  /// In tr, this message translates to:
  /// **'Yaşadığınız sorunu veya önerinizi yazın...'**
  String get feedbackHint;

  /// Gönder butonu
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get send;

  /// Gönderiliyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor...'**
  String get sending;

  /// Teşekkür mesajı
  ///
  /// In tr, this message translates to:
  /// **'Geri bildiriminiz için teşekkürler!'**
  String get thankYouFeedback;

  /// Gönderim hatası
  ///
  /// In tr, this message translates to:
  /// **'Gönderilirken bir hata oluştu'**
  String get sendError;

  /// Şifre sıfırlama mesajı
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi'**
  String get passwordResetSent;

  /// E-posta bulunamadı hatası
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi bulunamadı'**
  String get emailNotFound;

  /// Yakında mesajı
  ///
  /// In tr, this message translates to:
  /// **'Sayfa yakında eklenecek'**
  String get comingSoon;

  /// Ayar güncellendi mesajı
  ///
  /// In tr, this message translates to:
  /// **'Ayar güncellendi'**
  String get settingUpdated;

  /// Ayar güncelleme hatası
  ///
  /// In tr, this message translates to:
  /// **'Ayar güncellenemedi'**
  String get settingUpdateFailed;

  /// Hesap gizli mesajı
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız gizli yapıldı'**
  String get accountMadePrivate;

  /// Hesap açık mesajı
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız herkese açık yapıldı'**
  String get accountMadePublic;

  /// Konum gösteriliyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Konumunuz gösterilecek'**
  String get locationShown;

  /// Konum gizleniyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Konumunuz gizlenecek'**
  String get locationHidden;

  /// Çevrimiçi durumu gösteriliyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi durumunuz gösterilecek'**
  String get onlineStatusShown;

  /// Çevrimiçi durumu gizleniyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi durumunuz gizlenecek'**
  String get onlineStatusHidden;

  /// Kullanıcı bilgisi hatası
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bilgisi alınamadı'**
  String get userInfoNotFound;

  /// Açıklama uyarısı
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir açıklama yazın'**
  String get pleaseEnterDescription;

  /// Engellenen kullanıcı yok mesajı
  ///
  /// In tr, this message translates to:
  /// **'Engellenen kullanıcı yok'**
  String get noBlockedUsers;

  /// Engeli kaldır butonu
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get unblock;

  /// Engel kaldırıldı mesajı
  ///
  /// In tr, this message translates to:
  /// **'Engel kaldırıldı'**
  String get unblocked;

  /// No description provided for @selectPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Seç'**
  String get selectPhoto;

  /// No description provided for @cropPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı Kırp'**
  String get cropPhoto;

  /// No description provided for @uploading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get uploading;

  /// No description provided for @compressingImage.
  ///
  /// In tr, this message translates to:
  /// **'Resim sıkıştırılıyor...'**
  String get compressingImage;

  /// No description provided for @preparingVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video hazırlanıyor...'**
  String get preparingVideo;

  /// No description provided for @uploadError.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme hatası'**
  String get uploadError;

  /// No description provided for @videoUpload.
  ///
  /// In tr, this message translates to:
  /// **'Video Yükleme'**
  String get videoUpload;

  /// No description provided for @photoUpload.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Yükleme'**
  String get photoUpload;

  /// No description provided for @videoSent.
  ///
  /// In tr, this message translates to:
  /// **'Video gönderildi'**
  String get videoSent;

  /// No description provided for @photoSent.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf gönderildi'**
  String get photoSent;

  /// No description provided for @uploadCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme iptal edildi'**
  String get uploadCancelled;

  /// No description provided for @voiceRecordingCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı iptal edildi'**
  String get voiceRecordingCancelled;

  /// No description provided for @slideToCancel.
  ///
  /// In tr, this message translates to:
  /// **'◀ Kaydır iptal'**
  String get slideToCancel;

  /// No description provided for @releaseToCancel.
  ///
  /// In tr, this message translates to:
  /// **'Bırak ve iptal et'**
  String get releaseToCancel;

  /// No description provided for @releaseToSend.
  ///
  /// In tr, this message translates to:
  /// **'Bırak → Gönder'**
  String get releaseToSend;

  /// No description provided for @editEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliği Düzenle'**
  String get editEvent;

  /// No description provided for @user.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get user;

  /// No description provided for @createRoute.
  ///
  /// In tr, this message translates to:
  /// **'Rota Oluştur'**
  String get createRoute;

  /// No description provided for @requestSent.
  ///
  /// In tr, this message translates to:
  /// **'İstek Gönderildi (Geri Al)'**
  String get requestSent;

  /// No description provided for @sendJoinRequest.
  ///
  /// In tr, this message translates to:
  /// **'Katılma İsteği Gönder'**
  String get sendJoinRequest;

  /// No description provided for @joinRequestSent.
  ///
  /// In tr, this message translates to:
  /// **'Katılma isteği gönderildi. Onaylandığında bildirim alacaksınız.'**
  String get joinRequestSent;

  /// No description provided for @joinRequestCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Katılma isteği geri alındı'**
  String get joinRequestCancelled;

  /// No description provided for @leftEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikten ayrıldınız'**
  String get leftEvent;

  /// No description provided for @participantsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcılar:'**
  String get participantsLabel;

  /// No description provided for @joinRequests.
  ///
  /// In tr, this message translates to:
  /// **'Katılma İstekleri'**
  String get joinRequests;

  /// No description provided for @accept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul Et'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reject;

  /// No description provided for @commentsChat.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar / Sohbet'**
  String get commentsChat;

  /// No description provided for @goToGroupChat.
  ///
  /// In tr, this message translates to:
  /// **'Grup Sohbetine Git'**
  String get goToGroupChat;

  /// No description provided for @createGroupChat.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Grup Oluştur'**
  String get createGroupChat;

  /// No description provided for @mustJoinToChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti görmek ve katılmak için etkinliğe katılmalısınız.'**
  String get mustJoinToChat;

  /// No description provided for @noComments.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok. İlk yorumu sen yaz!'**
  String get noComments;

  /// No description provided for @writeComment.
  ///
  /// In tr, this message translates to:
  /// **'Yorum yaz...'**
  String get writeComment;

  /// No description provided for @hoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'saat önce'**
  String get hoursAgo;

  /// No description provided for @minutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'dakika önce'**
  String get minutesAgo;

  /// No description provided for @daysAgo.
  ///
  /// In tr, this message translates to:
  /// **'gün önce'**
  String get daysAgo;

  /// No description provided for @justNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get justNow;

  /// No description provided for @calculatingDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe hesaplanıyor...'**
  String get calculatingDistance;

  /// No description provided for @distanceToEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliğe uzaklık:'**
  String get distanceToEvent;

  /// No description provided for @noParticipants.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcı yok.'**
  String get noParticipants;

  /// No description provided for @selectCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Seç'**
  String get selectCategory;

  /// No description provided for @addCoverPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Kapak Fotoğrafı Ekle'**
  String get addCoverPhoto;

  /// No description provided for @selectFromGalleryOrCamera.
  ///
  /// In tr, this message translates to:
  /// **'Galeri veya kameradan seç'**
  String get selectFromGalleryOrCamera;

  /// No description provided for @uploadingPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yükleniyor...'**
  String get uploadingPhoto;

  /// No description provided for @change.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get change;

  /// No description provided for @selectDateTime.
  ///
  /// In tr, this message translates to:
  /// **'Tarih/Saat seçiniz'**
  String get selectDateTime;

  /// No description provided for @selectLocationAndCategory.
  ///
  /// In tr, this message translates to:
  /// **'Konum ve Kategori Seç'**
  String get selectLocationAndCategory;

  /// No description provided for @select.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get select;

  /// No description provided for @fillAllFields.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tüm zorunlu alanları doldurun'**
  String get fillAllFields;

  /// No description provided for @selectEventDateTime.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen etkinlik tarihi ve saatini seçin'**
  String get selectEventDateTime;

  /// No description provided for @selectEventLocation.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen etkinlik konumunu haritadan seçin'**
  String get selectEventLocation;

  /// No description provided for @markAllAsRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü okundu işaretle'**
  String get markAllAsRead;

  /// No description provided for @allNotificationsRead.
  ///
  /// In tr, this message translates to:
  /// **'Tüm bildirimler okundu olarak işaretlendi'**
  String get allNotificationsRead;

  /// No description provided for @loadingNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler yükleniyor...'**
  String get loadingNotifications;

  /// No description provided for @notificationsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler yüklenirken bir hata oluştu'**
  String get notificationsLoadError;

  /// No description provided for @noNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bildirim yok'**
  String get noNotifications;

  /// No description provided for @notificationsWillAppear.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bildirimler burada görünecek'**
  String get notificationsWillAppear;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @nearbyEvents.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki Etkinlikler'**
  String get nearbyEvents;

  /// No description provided for @noEventsFound.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik bulunamadı'**
  String get noEventsFound;

  /// No description provided for @createYourFirstEvent.
  ///
  /// In tr, this message translates to:
  /// **'İlk etkinliğini oluştur!'**
  String get createYourFirstEvent;

  /// No description provided for @searchEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik ara...'**
  String get searchEvents;

  /// No description provided for @allCategories.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Kategoriler'**
  String get allCategories;

  /// No description provided for @searchUserPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'İsim veya e-posta ile ara...'**
  String get searchUserPlaceholder;

  /// No description provided for @noUsersFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bulunamadı'**
  String get noUsersFound;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In tr, this message translates to:
  /// **'Farklı anahtar kelimeler deneyin'**
  String get tryDifferentKeywords;

  /// No description provided for @profileUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Profil başarıyla güncellendi!'**
  String get profileUpdated;

  /// No description provided for @photoUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Profil fotoğrafı başarıyla güncellendi!'**
  String get photoUpdated;

  /// No description provided for @uploadNewPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Fotoğraf Yükle'**
  String get uploadNewPhoto;

  /// No description provided for @noEventsCreated.
  ///
  /// In tr, this message translates to:
  /// **'Henüz etkinlik oluşturmadınız'**
  String get noEventsCreated;

  /// No description provided for @suggestedUsers.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen Kullanıcılar'**
  String get suggestedUsers;

  /// No description provided for @block.
  ///
  /// In tr, this message translates to:
  /// **'Engelle'**
  String get block;

  /// No description provided for @blocked.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı engellendi'**
  String get blocked;

  /// No description provided for @report.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet Et'**
  String get report;

  /// No description provided for @privateProfile.
  ///
  /// In tr, this message translates to:
  /// **'Bu profil gizli'**
  String get privateProfile;

  /// No description provided for @followToSee.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliklerini görmek için takip edin'**
  String get followToSee;

  /// No description provided for @chats.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get chats;

  /// No description provided for @noChats.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sohbet yok'**
  String get noChats;

  /// No description provided for @startNewChat.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir sohbet başlat!'**
  String get startNewChat;

  /// No description provided for @searchInMessages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlarda ara'**
  String get searchInMessages;

  /// No description provided for @messageDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj silindi'**
  String get messageDeleted;

  /// No description provided for @messageEdited.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj düzenlendi'**
  String get messageEdited;

  /// No description provided for @copyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copyMessage;

  /// No description provided for @editMessage.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get editMessage;

  /// No description provided for @deleteMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesajı Sil'**
  String get deleteMessage;

  /// No description provided for @forwardMessage.
  ///
  /// In tr, this message translates to:
  /// **'İlet'**
  String get forwardMessage;

  /// No description provided for @replyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtla'**
  String get replyMessage;

  /// No description provided for @online.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı'**
  String get offline;

  /// No description provided for @typing.
  ///
  /// In tr, this message translates to:
  /// **'Yazıyor...'**
  String get typing;

  /// No description provided for @lastSeen.
  ///
  /// In tr, this message translates to:
  /// **'Son görülme'**
  String get lastSeen;

  /// No description provided for @voiceMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sesli mesaj'**
  String get voiceMessage;

  /// No description provided for @photo.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @file.
  ///
  /// In tr, this message translates to:
  /// **'Dosya'**
  String get file;

  /// No description provided for @location.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get location;

  /// No description provided for @searchMessagesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj Ara'**
  String get searchMessagesTitle;

  /// No description provided for @forwardTo.
  ///
  /// In tr, this message translates to:
  /// **'İlet'**
  String get forwardTo;

  /// No description provided for @forward.
  ///
  /// In tr, this message translates to:
  /// **'İlet'**
  String get forward;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Konum servisi kapalı. Lütfen açın.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni reddedildi.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kalıcı reddedildi. Ayarlardan izin verin.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Tekrar deneyin.'**
  String get locationFailed;

  /// No description provided for @searchEventHint.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik ara (başlık, açıklama, adres)'**
  String get searchEventHint;

  /// No description provided for @filters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get filters;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @startDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get endDateLabel;

  /// No description provided for @enableDistanceFilter.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe filtresini aktif et'**
  String get enableDistanceFilter;

  /// No description provided for @distanceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get distanceLabel;

  /// No description provided for @locationObtained.
  ///
  /// In tr, this message translates to:
  /// **'Konum alındı! En yakın etkinlikler gösteriliyor.'**
  String get locationObtained;

  /// No description provided for @locationSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum İzni/Ayarı'**
  String get locationSettingsTitle;

  /// No description provided for @locationSettingsBtn.
  ///
  /// In tr, this message translates to:
  /// **'Konum Ayarları'**
  String get locationSettingsBtn;

  /// No description provided for @appSettingsBtn.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Ayarları'**
  String get appSettingsBtn;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @findNearbyEvents.
  ///
  /// In tr, this message translates to:
  /// **'Konumuma en yakın etkinlikleri bul'**
  String get findNearbyEvents;

  /// No description provided for @apply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// No description provided for @loadingEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler yükleniyor...'**
  String get loadingEvents;

  /// No description provided for @noEventsFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik bulunamadı'**
  String get noEventsFoundTitle;

  /// No description provided for @noEventsFoundSearch.
  ///
  /// In tr, this message translates to:
  /// **'Arama kriterlerinize uygun etkinlik bulunamadı.'**
  String get noEventsFoundSearch;

  /// No description provided for @noEventsFoundEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz etkinlik bulunmuyor.'**
  String get noEventsFoundEmpty;

  /// No description provided for @clearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri Temizle'**
  String get clearFilters;

  /// No description provided for @loadMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla yükle'**
  String get loadMore;

  /// No description provided for @thatsAll.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi bu kadar'**
  String get thatsAll;

  /// No description provided for @distanceDisplay.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get distanceDisplay;

  /// No description provided for @noMessagesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok'**
  String get noMessagesYet;

  /// No description provided for @sendFirstMessage.
  ///
  /// In tr, this message translates to:
  /// **'İlk mesajı siz gönderin!'**
  String get sendFirstMessage;

  /// No description provided for @chatStartFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet başlatılamadı. Lütfen tekrar deneyin.'**
  String get chatStartFailed;

  /// No description provided for @messageSendFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderilemedi'**
  String get messageSendFailed;

  /// No description provided for @fileNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Dosya bulunamadı'**
  String get fileNotFound;

  /// No description provided for @fileTooLarge.
  ///
  /// In tr, this message translates to:
  /// **'Dosya boyutu çok büyük (Max: 50MB)'**
  String get fileTooLarge;

  /// No description provided for @mediaUploading.
  ///
  /// In tr, this message translates to:
  /// **'yükleniyor...'**
  String get mediaUploading;

  /// No description provided for @mediaUploaded.
  ///
  /// In tr, this message translates to:
  /// **'yüklendi'**
  String get mediaUploaded;

  /// No description provided for @mediaSendError.
  ///
  /// In tr, this message translates to:
  /// **'gönderme hatası'**
  String get mediaSendError;

  /// No description provided for @react.
  ///
  /// In tr, this message translates to:
  /// **'Tepki Ver'**
  String get react;

  /// No description provided for @copy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// No description provided for @messageCopied.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj kopyalandı'**
  String get messageCopied;

  /// No description provided for @editMessageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesajı Düzenle'**
  String get editMessageTitle;

  /// No description provided for @editMessageHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesajınızı düzenleyin...'**
  String get editMessageHint;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesajı Sil'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu mesajı silmek istediğinizden emin misiniz?'**
  String get deleteMessageConfirm;

  /// No description provided for @reactionError.
  ///
  /// In tr, this message translates to:
  /// **'Tepki hatası'**
  String get reactionError;

  /// No description provided for @voiceMessageUploading.
  ///
  /// In tr, this message translates to:
  /// **'Sesli mesaj yükleniyor...'**
  String get voiceMessageUploading;

  /// No description provided for @voiceMessageSent.
  ///
  /// In tr, this message translates to:
  /// **'Sesli mesaj gönderildi'**
  String get voiceMessageSent;

  /// No description provided for @voiceMessageError.
  ///
  /// In tr, this message translates to:
  /// **'Sesli mesaj gönderme hatası'**
  String get voiceMessageError;

  /// No description provided for @fileUploading.
  ///
  /// In tr, this message translates to:
  /// **'yükleniyor...'**
  String get fileUploading;

  /// No description provided for @fileSent.
  ///
  /// In tr, this message translates to:
  /// **'gönderildi'**
  String get fileSent;

  /// No description provided for @fileSendError.
  ///
  /// In tr, this message translates to:
  /// **'Dosya gönderme hatası'**
  String get fileSendError;

  /// No description provided for @gallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @unknownFile.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen dosya'**
  String get unknownFile;

  /// No description provided for @fileOpenSoon.
  ///
  /// In tr, this message translates to:
  /// **'Dosya açma özelliği yakında eklenecek'**
  String get fileOpenSoon;

  /// No description provided for @deleteEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliği Sil'**
  String get deleteEvent;

  /// No description provided for @deleteEventConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinliği silmek istediğinize emin misiniz?'**
  String get deleteEventConfirm;

  /// No description provided for @deleteEventWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Etkinliğe ait tüm mesajlar ve medyalar silinecektir.'**
  String get deleteEventWarning;

  /// No description provided for @eventDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik başarıyla silindi'**
  String get eventDeleted;

  /// Katılımcı çıkarma dialog başlığı
  ///
  /// In tr, this message translates to:
  /// **'Katılımcıyı Çıkar'**
  String get removeParticipant;

  /// Çıkar butonu
  ///
  /// In tr, this message translates to:
  /// **'Çıkar'**
  String get remove;

  /// Katılımcı çıkarıldı mesajı
  ///
  /// In tr, this message translates to:
  /// **'Katılımcı çıkarıldı'**
  String get participantRemoved;

  /// Katılımcı yönetimi başlığı
  ///
  /// In tr, this message translates to:
  /// **'Katılımcı Yönetimi'**
  String get participantManagement;

  /// No description provided for @notLoggedIn.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı giriş yapmamış'**
  String get notLoggedIn;

  /// No description provided for @groupChatNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Grup sohbeti bulunamadı'**
  String get groupChatNotFound;

  /// No description provided for @groupInfo.
  ///
  /// In tr, this message translates to:
  /// **'Grup Bilgileri'**
  String get groupInfo;

  /// No description provided for @noDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama yok'**
  String get noDescription;

  /// No description provided for @noParticipantsFound.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcı bulunamadı'**
  String get noParticipantsFound;

  /// No description provided for @unnamed.
  ///
  /// In tr, this message translates to:
  /// **'İsimsiz'**
  String get unnamed;

  /// No description provided for @creator.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturan'**
  String get creator;

  /// No description provided for @admin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get admin;

  /// No description provided for @you.
  ///
  /// In tr, this message translates to:
  /// **'Sen'**
  String get you;

  /// No description provided for @demoteAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yöneticilikten Çıkar'**
  String get demoteAdmin;

  /// No description provided for @promoteAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici Yap'**
  String get promoteAdmin;

  /// No description provided for @adminPromoted.
  ///
  /// In tr, this message translates to:
  /// **'{name} yönetici yapıldı'**
  String adminPromoted(String name);

  /// No description provided for @adminDemoted.
  ///
  /// In tr, this message translates to:
  /// **'{name} yöneticilikten çıkarıldı'**
  String adminDemoted(String name);

  /// No description provided for @groupPhotoUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Grup fotoğrafı güncellendi'**
  String get groupPhotoUpdated;

  /// No description provided for @groupPhotoUploadError.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklenirken hata oluştu: {error}'**
  String groupPhotoUploadError(String error);

  /// No description provided for @editGroupName.
  ///
  /// In tr, this message translates to:
  /// **'Grup Adını Düzenle'**
  String get editGroupName;

  /// No description provided for @groupName.
  ///
  /// In tr, this message translates to:
  /// **'Grup Adı'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Grup adını girin'**
  String get groupNameHint;

  /// No description provided for @groupNameUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Grup adı güncellendi'**
  String get groupNameUpdated;

  /// No description provided for @groupNameUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Grup adı güncellenirken hata oluştu: {error}'**
  String groupNameUpdateError(String error);

  /// No description provided for @editDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklamayı Düzenle'**
  String get editDescription;

  /// No description provided for @descriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Grup açıklamasını girin'**
  String get descriptionHint;

  /// No description provided for @descriptionUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama güncellendi'**
  String get descriptionUpdated;

  /// No description provided for @descriptionUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama güncellenirken hata oluştu: {error}'**
  String descriptionUpdateError(String error);

  /// No description provided for @removeParticipantConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} etkinlikten çıkarılsın mı?'**
  String removeParticipantConfirm(String name);

  /// No description provided for @userLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı: {id}'**
  String userLabel(String id);

  /// No description provided for @view.
  ///
  /// In tr, this message translates to:
  /// **'Görüntüle'**
  String get view;

  /// No description provided for @manage.
  ///
  /// In tr, this message translates to:
  /// **'Yönet'**
  String get manage;

  /// No description provided for @goToEventDetail.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Detayına Git'**
  String get goToEventDetail;

  /// No description provided for @chatsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler yüklenirken hata: {error}'**
  String chatsLoadError(String error);

  /// No description provided for @messageForwardedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj başarıyla iletildi'**
  String get messageForwardedSuccess;

  /// No description provided for @messageForwardFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj iletilemedi: {error}'**
  String messageForwardFailed(String error);

  /// No description provided for @commentSendFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yorum gönderilemedi: {error}'**
  String commentSendFailed(String error);

  /// No description provided for @photoUploadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklenemedi'**
  String get photoUploadFailed;

  /// No description provided for @photoUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklendi'**
  String get photoUploaded;

  /// No description provided for @photoUploadError.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yükleme hatası: {error}'**
  String photoUploadError(String error);

  /// No description provided for @filePickError.
  ///
  /// In tr, this message translates to:
  /// **'Dosya seçme hatası: {error}'**
  String filePickError(String error);

  /// No description provided for @logoutError.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapılırken bir hata oluştu: {error}'**
  String logoutError(String error);

  /// No description provided for @themeSelection.
  ///
  /// In tr, this message translates to:
  /// **'Tema Seçimi'**
  String get themeSelection;

  /// No description provided for @lightMode.
  ///
  /// In tr, this message translates to:
  /// **'Gündüz Modu'**
  String get lightMode;

  /// No description provided for @lightThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Açık renk teması'**
  String get lightThemeSubtitle;

  /// No description provided for @darkThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Koyu renk teması'**
  String get darkThemeSubtitle;

  /// No description provided for @systemMode.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get systemMode;

  /// No description provided for @systemThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sistem ayarına göre otomatik'**
  String get systemThemeSubtitle;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @crashTestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Test crash?'**
  String get crashTestTitle;

  /// No description provided for @crashTestMessage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama çökecek. Yalnızca Crashlytics testi için kullanın.'**
  String get crashTestMessage;

  /// No description provided for @crashTestButton.
  ///
  /// In tr, this message translates to:
  /// **'Çökert'**
  String get crashTestButton;

  /// No description provided for @crashlyticsTestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Crashlytics Test (crash)'**
  String get crashlyticsTestTitle;

  /// No description provided for @crashlyticsTestSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı bilinçli çökertir'**
  String get crashlyticsTestSubtitle;

  /// No description provided for @bioOptional.
  ///
  /// In tr, this message translates to:
  /// **'Biyografi (Opsiyonel)'**
  String get bioOptional;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı kişiselleştirmek için birkaç bilgi daha'**
  String get completeProfileSubtitle;

  /// No description provided for @nameHint.
  ///
  /// In tr, this message translates to:
  /// **'Adınız ve soyadınız'**
  String get nameHint;

  /// No description provided for @bioHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendiniz hakkında kısa bir açıklama yazın'**
  String get bioHint;

  /// No description provided for @nameRequired.
  ///
  /// In tr, this message translates to:
  /// **'İsim alanı boş olamaz'**
  String get nameRequired;

  /// No description provided for @profileSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Profil kaydedilemedi: {error}'**
  String profileSaveFailed(String error);

  /// No description provided for @devPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'📱 Ekran Önizlemeleri'**
  String get devPreviewTitle;

  /// No description provided for @screenPreviewsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm ekranları mock data ile görüntüle'**
  String get screenPreviewsSubtitle;

  /// No description provided for @selectFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Seç'**
  String get selectFile;

  /// No description provided for @allFiles.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Dosyalar'**
  String get allFiles;

  /// No description provided for @fileTypeWord.
  ///
  /// In tr, this message translates to:
  /// **'Word'**
  String get fileTypeWord;

  /// No description provided for @fileTypeExcel.
  ///
  /// In tr, this message translates to:
  /// **'Excel'**
  String get fileTypeExcel;

  /// No description provided for @fileTypePowerPoint.
  ///
  /// In tr, this message translates to:
  /// **'PowerPoint'**
  String get fileTypePowerPoint;

  /// No description provided for @fileTypeArchive.
  ///
  /// In tr, this message translates to:
  /// **'ZIP/RAR'**
  String get fileTypeArchive;

  /// No description provided for @errorWithDetails.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @fileSentSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Dosya gönderildi'**
  String get fileSentSuccess;

  /// No description provided for @myEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliklerim'**
  String get myEvents;

  /// No description provided for @past.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get past;

  /// No description provided for @addMembers.
  ///
  /// In tr, this message translates to:
  /// **'Üye Ekle'**
  String get addMembers;

  /// No description provided for @removeMember.
  ///
  /// In tr, this message translates to:
  /// **'Gruptan Çıkar'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} gruptan çıkarılsın mı?'**
  String removeMemberConfirm(String name);

  /// No description provided for @membersAdded.
  ///
  /// In tr, this message translates to:
  /// **'Üyeler eklendi'**
  String get membersAdded;

  /// No description provided for @memberRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Üye gruptan çıkarıldı'**
  String get memberRemoved;

  /// No description provided for @leaveGroup.
  ///
  /// In tr, this message translates to:
  /// **'Gruptan Ayrıl'**
  String get leaveGroup;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu gruptan ayrılmak istediğinize emin misiniz?'**
  String get leaveGroupConfirm;

  /// No description provided for @leftGroup.
  ///
  /// In tr, this message translates to:
  /// **'Gruptan ayrıldınız'**
  String get leftGroup;

  /// No description provided for @creatorCannotLeave.
  ///
  /// In tr, this message translates to:
  /// **'Grup oluşturan gruptan ayrılamaz'**
  String get creatorCannotLeave;

  /// No description provided for @selectMembersToAdd.
  ///
  /// In tr, this message translates to:
  /// **'Eklenecek kişileri seçin'**
  String get selectMembersToAdd;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileriniz kalıcı olarak silinir'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı silmek istediğinize emin misiniz?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Profiliniz, mesajlarınız ve etkinlikleriniz silinir.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountPasswordPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Onaylamak için şifrenizi girin'**
  String get deleteAccountPasswordPrompt;

  /// No description provided for @accountDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız silindi'**
  String get accountDeleted;

  /// No description provided for @deleteAccountError.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinirken hata oluştu: {error}'**
  String deleteAccountError(String error);

  /// No description provided for @participantsCount.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcılar ({count})'**
  String participantsCount(int count);

  /// No description provided for @fileUploadingNamed.
  ///
  /// In tr, this message translates to:
  /// **'{fileName} yükleniyor...'**
  String fileUploadingNamed(String fileName);

  /// No description provided for @create.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get create;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @groupNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Grup adı gereklidir'**
  String get groupNameRequired;

  /// No description provided for @groupNameExampleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Arkadaşlarım, İş Ekibi'**
  String get groupNameExampleHint;

  /// No description provided for @groupDescriptionOptional.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama (Opsiyonel)'**
  String get groupDescriptionOptional;

  /// No description provided for @groupDescriptionShortHint.
  ///
  /// In tr, this message translates to:
  /// **'Grup hakkında kısa bir açıklama'**
  String get groupDescriptionShortHint;

  /// No description provided for @selectParticipants.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcılar Seçin *'**
  String get selectParticipants;

  /// No description provided for @participantsSelectedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi seçildi'**
  String participantsSelectedCount(int count);

  /// No description provided for @selectAtLeastOneParticipant.
  ///
  /// In tr, this message translates to:
  /// **'En az bir kişi seçmelisiniz'**
  String get selectAtLeastOneParticipant;

  /// No description provided for @groupChatCreated.
  ///
  /// In tr, this message translates to:
  /// **'Grup sohbeti oluşturuldu'**
  String get groupChatCreated;

  /// No description provided for @groupChatCreateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Grup sohbeti oluşturulamadı'**
  String get groupChatCreateFailed;

  /// No description provided for @usersLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar yüklenemedi'**
  String get usersLoadFailed;

  /// No description provided for @noOtherUsersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz başka kullanıcı yok'**
  String get noOtherUsersYet;

  /// No description provided for @noSearchResults.
  ///
  /// In tr, this message translates to:
  /// **'Arama sonucu bulunamadı'**
  String get noSearchResults;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir arama terimi deneyin'**
  String get tryDifferentSearchTerm;

  /// No description provided for @clusterEventsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} etkinlik'**
  String clusterEventsCount(int count);

  /// No description provided for @developerSection.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici'**
  String get developerSection;

  /// No description provided for @crashlyticsNonFatalTest.
  ///
  /// In tr, this message translates to:
  /// **'Crashlytics Test (non-fatal)'**
  String get crashlyticsNonFatalTest;

  /// No description provided for @crashlyticsNonFatalSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Firebase Console\'da hata kaydı oluşturur'**
  String get crashlyticsNonFatalSubtitle;

  /// No description provided for @nonFatalTestSent.
  ///
  /// In tr, this message translates to:
  /// **'Non-fatal test kaydı gönderildi'**
  String get nonFatalTestSent;

  /// No description provided for @searchUsersShort.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ara...'**
  String get searchUsersShort;

  /// No description provided for @validationEmailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi zorunludur'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi giriniz'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre zorunludur'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalıdır'**
  String get validationPasswordMinLength;

  /// No description provided for @validationPasswordStrength.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az bir harf ve bir rakam içermelidir'**
  String get validationPasswordStrength;

  /// No description provided for @validationNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'İsim zorunludur'**
  String get validationNameRequired;

  /// No description provided for @validationNameMinLength.
  ///
  /// In tr, this message translates to:
  /// **'İsim en az 2 karakter olmalıdır'**
  String get validationNameMinLength;

  /// No description provided for @validationNameInvalid.
  ///
  /// In tr, this message translates to:
  /// **'İsim sadece harf ve boşluk içerebilir'**
  String get validationNameInvalid;

  /// No description provided for @validationBioMaxLength.
  ///
  /// In tr, this message translates to:
  /// **'Biyografi en fazla 500 karakter olabilir'**
  String get validationBioMaxLength;

  /// No description provided for @validationTitleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık zorunludur'**
  String get validationTitleRequired;

  /// No description provided for @validationTitleMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Başlık en az 3 karakter olmalıdır'**
  String get validationTitleMinLength;

  /// No description provided for @validationTitleMaxLength.
  ///
  /// In tr, this message translates to:
  /// **'Başlık en fazla 100 karakter olabilir'**
  String get validationTitleMaxLength;

  /// No description provided for @validationDescriptionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama zorunludur'**
  String get validationDescriptionRequired;

  /// No description provided for @validationDescriptionMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama en az 10 karakter olmalıdır'**
  String get validationDescriptionMinLength;

  /// No description provided for @validationDescriptionMaxLength.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama en fazla 2000 karakter olabilir'**
  String get validationDescriptionMaxLength;

  /// No description provided for @validationAddressRequired.
  ///
  /// In tr, this message translates to:
  /// **'Adres zorunludur'**
  String get validationAddressRequired;

  /// No description provided for @validationAddressMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Adres en az 5 karakter olmalıdır'**
  String get validationAddressMinLength;

  /// No description provided for @validationQuotaRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kota zorunludur'**
  String get validationQuotaRequired;

  /// No description provided for @validationQuotaInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir sayı giriniz'**
  String get validationQuotaInvalid;

  /// No description provided for @validationQuotaMin.
  ///
  /// In tr, this message translates to:
  /// **'Kota en az 1 olmalıdır'**
  String get validationQuotaMin;

  /// No description provided for @validationQuotaMax.
  ///
  /// In tr, this message translates to:
  /// **'Kota en fazla 1000 olabilir'**
  String get validationQuotaMax;

  /// No description provided for @validationFieldRequired.
  ///
  /// In tr, this message translates to:
  /// **'{fieldName} zorunludur'**
  String validationFieldRequired(String fieldName);

  /// No description provided for @validationFieldMinLength.
  ///
  /// In tr, this message translates to:
  /// **'{fieldName} en az {minLength} karakter olmalıdır'**
  String validationFieldMinLength(String fieldName, int minLength);

  /// No description provided for @validationFieldMaxLength.
  ///
  /// In tr, this message translates to:
  /// **'{fieldName} en fazla {maxLength} karakter olabilir'**
  String validationFieldMaxLength(String fieldName, int maxLength);
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
