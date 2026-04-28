// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'MoneyWise';

  @override
  String get tabTransactions => 'İşlemler';

  @override
  String get tabStats => 'İstatistik';

  @override
  String get tabAccounts => 'Hesaplar';

  @override
  String get tabMore => 'Daha Fazla';

  @override
  String get themeDark => 'Koyu Tema';

  @override
  String get themeLight => 'Açık Tema';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get income => 'Gelir';

  @override
  String get expense => 'Gider';

  @override
  String get transfer => 'Transfer';

  @override
  String get amount => 'Tutar';

  @override
  String get category => 'Kategori';

  @override
  String get account => 'Hesap';

  @override
  String get note => 'Not';

  @override
  String get description => 'Açıklama';

  @override
  String get date => 'Tarih';

  @override
  String get settings => 'Ayarlar';

  @override
  String get accounts => 'Hesaplar';

  @override
  String get addAccount => 'Hesap Ekle';

  @override
  String get editAccount => 'Hesap Düzenle';

  @override
  String get accountName => 'Hesap Adı';

  @override
  String get accountGroup => 'Hesap Grubu';

  @override
  String get currency => 'Para Birimi';

  @override
  String get initialBalance => 'Başlangıç Bakiyesi';

  @override
  String get includeInTotals => 'Toplamda Göster';

  @override
  String get accountNameRequired => 'Hesap adı zorunludur';

  @override
  String get invalidBalance => 'Lütfen geçerli bir sayı girin';

  @override
  String get emptyAccountsMessage =>
      'Henüz hesap yok.\nİlk hesabınızı eklemek için + tuşuna basın.';

  @override
  String get categories => 'Kategoriler';

  @override
  String get addCategory => 'Kategori Ekle';

  @override
  String get categoryName => 'Kategori Adı';

  @override
  String get categoryNameRequired => 'Kategori adı zorunludur';

  @override
  String get categoryIcon => 'İkon (emoji)';

  @override
  String get emptyCategoriesMessage => 'Henüz kategori yok.';

  @override
  String get defaultBadge => 'Varsayılan';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get errorSavingAccount =>
      'Hesap kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get errorSavingCategory =>
      'Kategori kaydedilemedi. Lütfen tekrar deneyin.';
}
