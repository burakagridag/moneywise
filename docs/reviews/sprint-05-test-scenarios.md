# MoneyWise Sprint 5 — Manuel Test Senaryoları

**Tarih:** 2026-04-30
**Sprint:** 05 — Stats & Budget
**Branch:** `sprint/05-stats-budget`
**Tester:** QA Agent

> Tüm senaryolar temiz bir uygulama durumunda (fresh install veya uygulama verisi silinerek) başlatılmalıdır. Gerektiğinde önceki senaryolardan gelen veri kullanılabilir; bağımlılıklar "Önkoşul" alanında belirtilmiştir.

---

## Transactions — Daily Tab

---

## TC-001: Yeni expense (gider) ekleme
**Ekran:** Transactions > Daily tab > Add Transaction
**Önkoşul:** En az bir hesap mevcut (ör. "Nakit", başlangıç bakiyesi 500 EUR)
**Adımlar:**
1. Alt menüden "Transactions" sekmesine git.
2. Sağ alttaki mavi "+" (add_transaction) FAB butonuna dokun.
3. Type seçici: "Expense" seçili olduğunu doğrula.
4. Amount alanına "75.50" yaz.
5. Category seçiciye dokun ve "Food" kategorisini seç.
6. Account seçiciye dokun ve "Nakit" hesabını seç.
7. Tarih bugün olarak göründüğünü doğrula.
8. "Save" butonuna dokun.

**Beklenen sonuç:**
- Ekran kapanır, Daily View'a döner.
- Bugünün tarih satırında "75.50" expense tutarı kırmızı renkte görünür.
- Nakit hesabının bakiyesi 500 - 75.50 = 424.50 EUR olur (Accounts ekranında kontrol et).

**Geçti mi? [ ]**

---

## TC-002: Yeni income (gelir) ekleme
**Ekran:** Transactions > Daily tab > Add Transaction
**Önkoşul:** En az bir hesap mevcut.
**Adımlar:**
1. "+" FAB butonuna dokun.
2. Type seçicide "Income" seçeneğine dokun.
3. Amount alanına "1200.00" yaz.
4. Category seçiciden "Salary" kategorisini seç.
5. Account seçiciden herhangi bir hesap seç.
6. "Save" butonuna dokun.

**Beklenen sonuç:**
- Daily View'da bugünün başlık satırında income tutarı yeşil renkte gösterilir.
- Hesap bakiyesi 1200 EUR artar.

**Geçti mi? [ ]**

---

## TC-003: Yeni transfer ekleme
**Ekran:** Transactions > Daily tab > Add Transaction
**Önkoşul:** En az iki hesap mevcut (ör. "Nakit" ve "Banka").
**Adımlar:**
1. "+" FAB butonuna dokun.
2. Type seçicide "Transfer" seçeneğine dokun.
3. Category alanının ekrandan kaybolduğunu doğrula.
4. "To Account" alanının göründüğünü doğrula.
5. Amount alanına "200.00" yaz.
6. Account seçiciden "Nakit" seç.
7. To Account seçiciden "Banka" seç.
8. "Save" butonuna dokun.

**Beklenen sonuç:**
- Daily View'da transfer kaydı görünür.
- Günlük başlık satırında transfer tutarı income veya expense sayılmaz (income ve expense sütunları etkilenmez).
- "Nakit" bakiyesi 200 EUR azalır, "Banka" bakiyesi 200 EUR artar.

**Geçti mi? [ ]**

---

## TC-004: Transaction düzenleme
**Ekran:** Transactions > Daily tab
**Önkoşul:** En az bir transaction mevcut.
**Adımlar:**
1. Daily View'da var olan bir transaction satırına dokun.
2. Edit ekranı açılır; mevcut type, amount, category ve account değerlerinin dolu geldiğini doğrula.
3. Amount alanını "99.99" olarak güncelle.
4. "Save" butonuna dokun.

**Beklenen sonuç:**
- Edit ekranı kapanır.
- Daily View'da aynı transaction yeni tutarla (99.99) listelenir.
- Hesap bakiyesi farka göre güncellenir.

**Geçti mi? [ ]**

---

## TC-005: Transaction silme (swipe)
**Ekran:** Transactions > Daily tab
**Önkoşul:** En az bir transaction mevcut.
**Adımlar:**
1. Daily View'da bir transaction satırını sola kaydır (swipe left).
2. Silme butonu görünür.
3. Silme butonuna dokun.

**Beklenen sonuç:**
- Transaction listeden kalkar.
- O güne ait başka transaction yoksa gün grubu da kaybolur.
- Hesap bakiyesi tutara göre güncellenir.

**Geçti mi? [ ]**

---

## TC-006: Transaction silme (edit ekranından)
**Ekran:** Transactions > Daily tab > Edit Transaction
**Önkoşul:** En az bir transaction mevcut.
**Adımlar:**
1. Bir transaction satırına dokun, edit ekranı açılır.
2. Sağ üst köşedeki çöp kutusu (delete) ikonuna dokun.
3. Onay dialogu açılır; "Delete" butonuna dokun.

**Beklenen sonuç:**
- Transaction silinir, Daily View'a döner.
- Listede artık o kayıt görünmez.

**Geçti mi? [ ]**

---

## TC-007: Boş ay görünümü (hiç transaction yok)
**Ekran:** Transactions > Daily tab
**Önkoşul:** Yeni bir ay (ör. gelecek ay veya hiç kayıt girilmemiş geçmiş bir ay) seçili.
**Adımlar:**
1. Transactions ekranında ay navigatörünü kullanarak transaction bulunmayan bir aya geç.
2. Daily View içeriğine bak.

**Beklenen sonuç:**
- Büyük bir ikon ve "No transactions" benzeri mesaj görünür (boş state).
- IncomeSummaryBar'da income ve expense sıfır gösterilir.

**Geçti mi? [ ]**

---

## TC-008: isExcluded transaction başlıkta gösterilmemeli
**Ekran:** Transactions > Daily tab
**Önkoşul:** `isExcluded = true` olarak işaretlenmiş bir transaction mevcut. (Veritabanında manuel olarak eklenebilir ya da bu özelliği destekleyen bir test verisi kullanılabilir.)
**Adımlar:**
1. isExcluded olan transaction'ın bulunduğu günün Daily View başlık satırına bak.
2. IncomeSummaryBar toplamlarına bak.

**Beklenen sonuç:**
- isExcluded transaction'ın tutarı günlük başlık satırındaki income/expense hesabına dahil edilmez.
- IncomeSummaryBar'daki aylık toplama da dahil edilmez.

**Geçti mi? [ ]**

---

## TC-009: Transfer transaction başlık satırında income/expense sayılmamalı
**Ekran:** Transactions > Daily tab
**Önkoşul:** Aynı güne ait bir transfer ve bir expense mevcut.
**Adımlar:**
1. Daily View'da transfer ve expense olan günün başlık satırına bak.

**Beklenen sonuç:**
- Başlık satırındaki income sütununda yalnızca gerçek income toplamı görünür.
- Başlık satırındaki expense sütununda yalnızca gerçek expense toplamı görünür.
- Transfer tutarı bu iki sütunun hiçbirine dahil edilmez.

**Geçti mi? [ ]**

---

## TC-010: Ay ileri navigasyonu
**Ekran:** Transactions
**Önkoşul:** Uygulamada en az iki farklı aya ait transaction var.
**Adımlar:**
1. Transactions ekranındaki ay navigatöründe sağ ok (ileri) butonuna dokun.

**Beklenen sonuç:**
- Bir sonraki ay gösterilir.
- Daily View, Calendar View ve IncomeSummaryBar yeni aya ait verileri yükler.

**Geçti mi? [ ]**

---

## TC-011: Ay geri navigasyonu
**Ekran:** Transactions
**Önkoşul:** Mevcut ay Nisan 2026.
**Adımlar:**
1. Ay navigatöründe sol ok (geri) butonuna dokun.

**Beklenen sonuç:**
- Mart 2026 gösterilir.
- Tüm sub-view'lar Mart verilerini yükler.

**Geçti mi? [ ]**

---

## TC-012: Bugün highlight — Daily View
**Ekran:** Transactions > Daily tab
**Önkoşul:** Bugüne ait en az bir transaction mevcut.
**Adımlar:**
1. Daily View'da bugünün tarih satırını incele.

**Beklenen sonuç:**
- Bugünün gün numarası daire içinde (bgTertiary arka planı) görünür; diğer günlerin daire yoktur.

**Geçti mi? [ ]**

---

## TC-013: Cumartesi günü başlık rengi
**Ekran:** Transactions > Daily tab
**Önkoşul:** Cumartesi olan bir gün'e ait transaction var.
**Adımlar:**
1. Cumartesi olan bir günün başlık satırındaki gün-kısaltma rozetine bak.

**Beklenen sonuç:**
- "Sat" rozeti yeşil (income rengi) arka plan ile gösterilir.

**Geçti mi? [ ]**

---

## TC-014: Pazar günü başlık rengi
**Ekran:** Transactions > Daily tab
**Önkoşul:** Pazar olan bir güne ait transaction var.
**Adımlar:**
1. Pazar olan bir günün başlık satırındaki gün-kısaltma rozetine bak.

**Beklenen sonuç:**
- "Sun" rozeti kırmızı (expense rengi) arka plan ile gösterilir.

**Geçti mi? [ ]**

---

## TC-015: "Save & Continue" — aynı ekranda kalıp yeni kayıt ekleme
**Ekran:** Add Transaction ekranı
**Önkoşul:** Add mode (yeni kayıt).
**Adımlar:**
1. "+" FAB butonuna dokun.
2. Geçerli bir expense gir (amount, category, account doldur).
3. "Save & Continue" butonuna dokun.

**Beklenen sonuç:**
- Kayıt kaydedilir.
- Ekran kapanmaz; amount ve category alanları temizlenir, account seçili kalır.
- Yeni bir kayıt girmeye hazır durumda olunur.

**Geçti mi? [ ]**

---

## Transactions — Calendar Tab

---

## TC-016: Calendar View — ay takvimi görünümü
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Aktif ay seçili.
**Adımlar:**
1. "Calendar" sekmesine dokun.

**Beklenen sonuç:**
- 7 sütunlu takvim ızgarası (Mon-Sun) açılır.
- Haftanın başı Pazartesi'dir.
- Sat ve Sun sütun başlıkları farklı renkte (yeşil / kırmızı) gösterilir.

**Geçti mi? [ ]**

---

## TC-017: Calendar View — Bugün highlight
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Aktif ay seçili.
**Adımlar:**
1. Calendar View'da bugünün hücresine bak.

**Beklenen sonuç:**
- Bugünün hücresi marka rengi (brandPrimary) ile tinted arka plana sahiptir.
- Gün numarası brandPrimary renkli daire içinde gösterilir.

**Geçti mi? [ ]**

---

## TC-018: Calendar View — Transaction olan gün hücresi
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Seçili ayda transaction bulunan günler var.
**Adımlar:**
1. Bir transaction bulunan günün hücresini incele.

**Beklenen sonuç:**
- Hücre içinde income varsa yeşil, expense varsa kırmızı kompakt tutar gösterilir.
- Hem income hem expense varsa her ikisi de gösterilir.

**Geçti mi? [ ]**

---

## TC-019: Calendar View — Transaction olmayan gün hücresi
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Seçili ayda transaction bulunmayan günler var.
**Adımlar:**
1. Hiç transaction olmayan bir günün hücresini incele.

**Beklenen sonuç:**
- Hücrede yalnızca gün numarası görünür; tutar bilgisi yoktur.

**Geçti mi? [ ]**

---

## TC-020: Calendar View — Gelecek günler tutar göstermemeli
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Mevcut ay seçili; ay henüz bitmemiş.
**Adımlar:**
1. Bugünden sonraki (gelecek) günlerin hücrelerini incele.

**Beklenen sonuç:**
- Gelecek gün hücrelerinde tutar bilgisi görünmez (income/expense gösterilmez).
- Gün numarası textTertiary (soluk) renkte gösterilir.

**Geçti mi? [ ]**

---

## TC-021: Calendar View — Gün tıklama / Bottom Sheet açılması
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Transaction olan bir gün var.
**Adımlar:**
1. Transaction bulunan bir güne dokun.

**Beklenen sonuç:**
- Ekranın altından bir bottom sheet kayar (max ekranın %50 yüksekliği).
- Sheet'in başlığında tıklanan günün tam adı (ör. "Thursday, 24 April 2025") görünür.
- O güne ait transaction'lar listeli biçimde gösterilir.

**Geçti mi? [ ]**

---

## TC-022: Calendar View — Gün tıklama / Hiç transaction yok
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Mevcut ayda transaction bulunmayan geçmiş bir gün var.
**Adımlar:**
1. Transaction bulunmayan bir geçmiş güne dokun.

**Beklened sonuç:**
- Bottom sheet açılır, "No transactions" benzeri mesaj görünür.

**Geçti mi? [ ]**

---

## TC-023: Calendar View — Önceki aya geçme
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Mevcut ay Nisan 2026.
**Adımlar:**
1. Ay navigatörünün sol okuna dokun.

**Beklenen sonuç:**
- Takvim Mart 2026 olarak yenilenir.
- Mart'a ait veri hücrelerinde gösterilir.

**Geçti mi? [ ]**

---

## TC-024: Calendar View — Önceki ayın taşan günleri soluk görünmeli
**Ekran:** Transactions > Calendar tab
**Önkoşul:** Ayın ilk günü Pazartesi değil.
**Adımlar:**
1. Calendar View'da birinci haftanın solundaki gri hücreleri (önceki aydan taşan günler) incele.

**Beklened sonuç:**
- Bu günler textTertiary (soluk) renkte gün numarasıyla gösterilir, tıklanamaz.

**Geçti mi? [ ]**

---

## TC-025: Calendar View — Bottom sheet drag handle ile kapatma
**Ekran:** Transactions > Calendar tab > Day Bottom Sheet
**Önkoşul:** Bottom sheet açık.
**Adımlar:**
1. Bottom sheet'in üstündeki drag handle'ı aşağı kaydır.

**Beklenen sonuç:**
- Bottom sheet kapanır, takvim ekranı görünür.

**Geçti mi? [ ]**

---

## Transactions — Monthly Tab

---

## TC-026: Monthly View — 12 aylık accordion listesi
**Ekran:** Transactions > Monthly tab
**Önkoşul:** Mevcut yıl seçili.
**Adımlar:**
1. "Monthly" sekmesine dokun.

**Beklenen sonuç:**
- 12 ay kartı listelenir (Ocak - Aralık).
- Her kartta income, expense ve net toplamlar görünür.
- Mevcut ay bir brandPrimary dikey çubuk ile işaretlidir.

**Geçti mi? [ ]**

---

## TC-027: Monthly View — Ay kartını genişletme / daraltma
**Ekran:** Transactions > Monthly tab
**Önkoşul:** Mevcut yıl seçili, mevcut ay başlangıçta genişletilmiş.
**Adımlar:**
1. Genişletilmiş ay kartına dokun — daraltılır.
2. Daraltılmış bir ay kartına dokun — genişletilir.

**Beklenen sonuç:**
- Genişletilen kart haftalık satırları (week rows) gösterir.
- Mevcut hafta koyu pembe/coral arka planla vurgulanır.
- Chevron animasyonla döner (0° ↔ 90°).

**Geçti mi? [ ]**

---

## TC-028: Monthly View — Yıl navigasyonu ileri
**Ekran:** Transactions > Monthly tab
**Önkoşul:** MonthNavigator "year-only" modunda gösterilmeli (Monthly sekmesi seçiliyken).
**Adımlar:**
1. Monthly sekmesini seç.
2. Ay navigatöründe sağ ok ile ileri git.

**Beklenen sonuç:**
- Gösterilen yıl bir ileri gider (ör. 2026 → 2027).
- 12 ay kartı yeni yılın verisiyle yüklenir.
- Mevcut yıl değilse hiçbir ay mevcut ay olarak işaretlenmez.

**Geçti mi? [ ]**

---

## TC-029: Monthly View — Haftalık tutarlar doğru hesaplanmalı
**Ekran:** Transactions > Monthly tab
**Önkoşul:** Belirli bir haftada en az iki transaction var.
**Adımlar:**
1. Monthly sekmesine git, ilgili ayı genişlet.
2. İlgili haftanın satırındaki income ve expense değerlerine bak.

**Beklenen sonuç:**
- Haftalık satırdaki income ve expense tutarları o haftaya ait transaction'ların toplamıdır.
- Sıfır olan tutar soluk renkte gösterilir.

**Geçti mi? [ ]**

---

## TC-030: Monthly View — Transaction olmayan ay kartı
**Ekran:** Transactions > Monthly tab
**Önkoşul:** Mevcut yılda hiç transaction girilmemiş aylar var.
**Adımlar:**
1. Monthly sekmesinde transaction bulunmayan bir ayı genişlet.

**Beklenen sonuç:**
- "No transactions" benzeri bir mesaj içeren satır görünür.
- Income ve expense sıfır gösterilir.

**Geçti mi? [ ]**

---

## Stats Ekranı

---

## TC-031: Stats ekranı açılışı — varsayılan durum
**Ekran:** Stats
**Önkoşul:** Herhangi bir ay için expense transaction mevcut.
**Adımlar:**
1. Alt menüden "Stats" sekmesine git.

**Beklenen sonuç:**
- "Stats / Budget / Note" sub-tab bar görünür.
- "Stats" sub-tab'ı aktif ve altında mavi çizgi var.
- Period seçici sağ üstte "M ▼" olarak görünür (varsayılan Monthly).
- Income/Expense toggle'da "Expense" aktif.
- Pie chart ve kategori listesi yüklenir.

**Geçti mi? [ ]**

---

## TC-032: Stats — Period W/M/Y toggle
**Ekran:** Stats
**Önkoşul:** Uygulama açık.
**Adımlar:**
1. Sağ üstteki "M ▼" butonuna dokun.
2. Açılan sheet'te "Week (W)" seçeneğini seç.
3. Tekrar butona dokun, "Year (Y)" seç.

**Beklenen sonuç:**
- W seçilince ay navigatörü gizlenir; chart bu haftaya ait verileri gösterir.
- Y seçilince navigatör görünür, yıllık veriler gösterilir.
- Her seçimde buton etiketi güncellenir ("W ▼", "M ▼", "Y ▼").

**Geçti mi? [ ]**

---

## TC-033: Stats — Income/Expense toggle
**Ekran:** Stats
**Önkoşul:** Hem income hem expense transaction mevcut.
**Adımlar:**
1. Income/Expense toggle'da "Income" seçeneğine dokun.
2. "Expense" seçeneğine geri dön.

**Beklenen sonuç:**
- "Income" seçilince pie chart income kategorilerini gösterir.
- "Expense" seçilince expense kategorilerini gösterir.
- Toggle'ın aktif seçeneğinin altında mavi çizgi görünür.

**Geçti mi? [ ]**

---

## TC-034: Stats — Pie chart — veri var durumu
**Ekran:** Stats
**Önkoşul:** Seçili ay/dönem için birden fazla kategoride expense var.
**Adımlar:**
1. Stats ekranını aç, Expense görünümünde olduğundan emin ol.

**Beklenen sonuç:**
- Donut pie chart kategorilere göre renkli dilimler halinde gösterilir.
- Altındaki listede her kategori için isim, tutar ve yüzde görünür.

**Geçti mi? [ ]**

---

## TC-035: Stats — Pie chart — veri yok durumu
**Ekran:** Stats
**Önkoşul:** Seçili dönem için hiç expense girilmemiş.
**Adımlar:**
1. Stats ekranında, transaction bulunmayan bir aya/döneme geç.
2. Expense görünümünde kal.

**Beklened sonuç:**
- Pie chart gösterilmez.
- "No data for this period" benzeri bir mesaj ve "Add transactions for breakdown" açıklaması görünür.

**Geçti mi? [ ]**

---

## TC-036: Stats — Kategori tıklaması Transactions ekranına yönlendirmeli
**Ekran:** Stats > Kategori listesi
**Önkoşul:** Pie chart altında kategori satırları görünüyor.
**Adımlar:**
1. Listede herhangi bir kategori satırına dokun.

**Beklenen sonuç:**
- Transactions ekranının Daily View'ına yönlendirilir.
- (Uygulamada kategori filtresi provider'a set edilir; TC-037'de bağımsızlık kontrol edilir.)

**Geçti mi? [ ]**

---

## TC-037: Stats ve Transactions ayları birbirinden bağımsız olmalı
**Ekran:** Stats + Transactions
**Önkoşul:** Birden fazla ay verisi var.
**Adımlar:**
1. Transactions ekranında Mart 2026'ya geç.
2. Stats ekranına geç.
3. Stats'ta Şubat 2026'ya geç.
4. Transactions ekranına geri dön.

**Beklenen sonuç:**
- Transactions ekranı hâlâ Mart 2026'yı gösterir (Stats'ta yapılan navigasyon Transactions'ı etkilemez).

**Geçti mi? [ ]**

---

## TC-038: Stats — Ay navigasyonu
**Ekran:** Stats
**Önkoşul:** Period "M" (Monthly) modunda.
**Adımlar:**
1. Stats ekranında ay navigatörünün sol okuna dokun.

**Beklenen sonuç:**
- Bir önceki ay gösterilir.
- Pie chart ve kategori listesi yeni aya göre yenilenir.

**Geçti mi? [ ]**

---

## TC-039: Stats — %3 altı kategoriler "Other" olarak gruplandırılmalı
**Ekran:** Stats
**Önkoşul:** Toplam içinde %3'ten az payı olan en az bir kategori mevcut ve toplam kategori sayısı 3'ten fazla.
**Adımlar:**
1. Stats ekranını aç, Expense görünümünde kal.

**Beklenen sonuç:**
- %3'ün altındaki kategoriler pie chart'ta ayrı dilim olarak gösterilmez.
- Listede "Other" (veya "Uncategorized") olarak birleştirilmiş bir satır görünür.

**Geçti mi? [ ]**

---

## TC-040: Stats — Budget sub-tab'a geçiş
**Ekran:** Stats
**Önkoşul:** Budget tanımlanmamış.
**Adımlar:**
1. Stats ekranında "Budget" sub-tab'ına dokun.

**Beklenen sonuç:**
- Budget View açılır; tasarruf ikonu ve "No budgets configured" mesajı ile "Set up budgets" butonu görünür.

**Geçti mi? [ ]**

---

## TC-041: Stats — Note sub-tab'a geçiş
**Ekran:** Stats
**Önkoşul:** Uygulama açık.
**Adımlar:**
1. Stats ekranında "Note" sub-tab'ına dokun.

**Beklenen sonuç:**
- Note View açılır (içerik Sprint 5 kapsamında ne ise o gösterilir).

**Geçti mi? [ ]**

---

## TC-042: Stats — Pie chart segment sayısı maksimum 8 olmalı
**Ekran:** Stats
**Önkoşul:** 10+ farklı kategoride expense mevcut ve hepsi %3'ün üzerinde.
**Adımlar:**
1. Stats ekranını aç, Expense görünümünde kal.

**Beklenen sonuç:**
- Pie chart'ta maksimum 8 ayrı renkli dilim gösterilir.
- Geri kalanlar "Other" altında toplanır.

**Geçti mi? [ ]**

---

## TC-043: Stats — Income görünümünde yalnızca income kategorileri
**Ekran:** Stats
**Önkoşul:** Hem income hem expense transaction mevcut.
**Adımlar:**
1. Income/Expense toggle'da "Income" seç.

**Beklenen sonuç:**
- Listede yalnızca income kategorileri gösterilir (ör. "Salary", "Freelance").
- Expense kategorileri (ör. "Food", "Transport") görünmez.

**Geçti mi? [ ]**

---

## TC-044: Stats — Hata durumu ve "Retry" butonu
**Ekran:** Stats
**Önkoşul:** Bozuk veri veya simüle edilmiş hata durumu. (Provider'ı zorlamak gerekirse bu senaryo geçilebilir; uygulama erişilebilirse doğrula.)
**Adımlar:**
1. Stats ekranında veri yüklenemezse hata ekranı görünür.
2. "Retry" butonuna dokun.

**Beklenen sonuç:**
- Hata ekranında uyarı ikonu, açıklama ve "Retry" butonu görünür.
- Butona dokunulunca provider invalidate edilir ve yeniden yükleme denenir.

**Geçti mi? [ ]**

---

## TC-045: Stats — W modu seçilince ay navigatörü gizlenmeli
**Ekran:** Stats
**Önkoşul:** Period "M" modunda, ay navigatörü görünüyor.
**Adımlar:**
1. Period seçiciden "Week (W)" seç.

**Beklenen sonuç:**
- Ay navigatörü ekrandan kaybolur.
- Yalnızca bu haftaya ait veriler gösterilir.

**Geçti mi? [ ]**

---

## Budget

---

## TC-046: Budget — Tanımsız durumda boş state
**Ekran:** Stats > Budget sub-tab
**Önkoşul:** Hiçbir kategori için budget tanımlanmamış.
**Adımlar:**
1. Stats ekranında "Budget" sub-tab'ına dokun.

**Beklenen sonuç:**
- Tasarruf (savings) ikonu görünür.
- "No budgets" başlığı ve açıklama metni görünür.
- "Set up budgets" butonu görünür.

**Geçti mi? [ ]**

---

## TC-047: Budget — "Set up budgets" butonu Budget Settings'e götürmeli
**Ekran:** Stats > Budget sub-tab (boş state)
**Önkoşul:** Hiçbir budget tanımlanmamış.
**Adımlar:**
1. "Set up budgets" butonuna dokun.

**Beklenen sonuç:**
- Budget Setting ekranı açılır.
- Başlığında ay navigatörü ve kategori listesi görünür.

**Geçti mi? [ ]**

---

## TC-048: Budget — Yeni budget oluşturma (More > Budget Settings)
**Ekran:** More > Budget Settings
**Önkoşul:** En az bir expense kategorisi mevcut.
**Adımlar:**
1. Alt menüden "More" > "Budget Settings" ekranına git.
2. Bir expense kategorisine (ör. "Food") dokun.
3. Budget Edit Modal açılır.
4. Amount alanına "500.00" yaz.
5. "Only this month" checkbox'ını işaretsiz bırak.
6. "Save" butonuna dokun.

**Beklenen sonuç:**
- Modal kapanır.
- Budget Settings listesinde "Food" kategorisinin yanında "500.00" tutarı görünür.
- Stats > Budget sub-tab'ında "Food" için progress bar gösterilir.

**Geçti mi? [ ]**

---

## TC-049: Budget — Mevcut budget'ı düzenleme
**Ekran:** More > Budget Settings
**Önkoşul:** "Food" kategorisinde 500.00 budget tanımlı.
**Adımlar:**
1. Budget Settings'te "Food" kategorisine dokun.
2. Modal açılır; amount alanında "500.00" değerinin dolu geldiğini doğrula.
3. Tutarı "750.00" olarak değiştir.
4. "Save" butonuna dokun.

**Beklenen sonuç:**
- Modal kapanır.
- "Food" için yeni tutar "750.00" olarak listelenir.
- Budget View'daki "Food" satırının progress bar'ı güncellenir.

**Geçti mi? [ ]**

---

## TC-050: Budget — Budget silme
**Ekran:** More > Budget Settings > Budget Edit Modal
**Önkoşul:** "Food" kategorisinde budget tanımlı.
**Adımlar:**
1. Budget Settings'te "Food" kategorisine dokun.
2. Modal'da "Clear budget" (kırmızı) butonuna dokun.
3. Onay dialogunda "Remove" butonuna dokun.

**Beklenen sonuç:**
- Modal kapanır.
- "Food" kategorisinin budget tutarı sıfır olarak (veya boş) gösterilir.
- Budget View'da "Food" satırı varsa "No budget set" etiketiyle gösterilir veya listeden kalkar.

**Geçti mi? [ ]**

---

## TC-051: Budget — Harcama budget'ı aşınca renk değişimi
**Ekran:** Stats > Budget sub-tab
**Önkoşul:** "Food" için 100.00 budget var; bu kategori için 120.00 expense girilmiş.
**Adımlar:**
1. Stats > Budget sub-tab'ına git.
2. "Food" satırının progress bar'ına ve uyarı ikonuna bak.

**Beklenen sonuç:**
- Progress bar kırmızı (error veya expense rengi) gösterilir.
- Satırın sağında uyarı (warning) ikonu görünür.
- Özet kartındaki "Remaining" tutarı negatif ve kırmızı renkte gösterilir.

**Geçti mi? [ ]**

---

## TC-052: Budget — Carry-over (önceki aydan devreden overspend)
**Ekran:** Stats > Budget sub-tab
**Önkoşul:** Önceki ayda bir kategori için budget aşımı olmuş.
**Adımlar:**
1. Stats ekranında önceki aşımın gerçekleştiği ayın bir sonraki ayına geç.
2. Budget sub-tab'ına bak.

**Beklenen sonuç:**
- Özet kartında "Includes carry-over from previous month: X.XX" bilgisi görünür (carryOver > 0 ise).
- Efektif budget tutarı carry-over dahil olarak hesaplanır.

**Geçti mi? [ ]**

---

## TC-053: Budget — "Only this month" checkbox ile tek ay geçerli budget
**Ekran:** More > Budget Settings > Budget Edit Modal
**Önkoşul:** Budget Edit Modal açık.
**Adımlar:**
1. Amount alanına "300.00" yaz.
2. "Only this month (Apr 2026)" checkbox'ını işaretle.
3. "Save" butonuna dokun.
4. Ay navigatöründe bir sonraki aya geç.

**Beklenen sonuç:**
- Nisan 2026'da budget 300.00 gösterilir.
- Mayıs 2026'da o kategori için budget görünmez (veya sıfır gösterilir).

**Geçti mi? [ ]**

---

## TC-054: Budget — Dirty state / Modal kapatma onayı
**Ekran:** More > Budget Settings > Budget Edit Modal
**Önkoşul:** Budget Edit Modal açık, amount alanı dolu.
**Adımlar:**
1. Amount alanına bir değer gir (formu kirlet / _isDirty = true).
2. Modal'ı aşağı kaydırarak veya geri tuşuyla kapatmaya çalış.

**Beklenen sonuç:**
- "Discard changes?" onay dialogu açılır.
- "Keep editing" seçilirse modal açık kalır.
- "Discard" seçilirse modal kapanır, değişiklikler kaydedilmez.

**Geçti mi? [ ]**

---

## TC-055: Budget — Amount = 0 validasyonu
**Ekran:** More > Budget Settings > Budget Edit Modal
**Önkoşul:** Budget Edit Modal açık.
**Adımlar:**
1. Amount alanına "0" yaz.
2. "Save" butonuna dokun.

**Beklenen sonuç:**
- Hata mesajı görünür: "Amount must be greater than zero" benzeri.
- Modal kapanmaz.

**Geçti mi? [ ]**

---

## TC-056: Budget — Amount negatif validasyonu
**Ekran:** More > Budget Settings > Budget Edit Modal
**Önkoşul:** Budget Edit Modal açık (klavye yalnızca rakam ve nokta kabul ediyor).
**Adımlar:**
1. Amount alanına negatif değer girmeye çalış (ör. "-100").

**Beklened sonuç:**
- Negatif işareti ("-") klavyede kabul edilmez; yalnızca rakam ve nokta girilebilir.

**Geçti mi? [ ]**

---

## TC-057: Budget — Çok büyük tutar validasyonu (999,999,999 üzeri)
**Ekran:** More > Budget Settings > Budget Edit Modal
**Önkoşul:** Budget Edit Modal açık.
**Adımlar:**
1. Amount alanına "9999999999" (10 basamaklı) gir.
2. "Save" butonuna dokun.

**Beklenen sonuç:**
- Hata mesajı görünür: "Amount too large" benzeri.
- Modal kapanmaz.

**Geçti mi? [ ]**

---

## TC-058: Budget — Budget Settings'te TOTAL satırı hesaplanmış gösterilmeli
**Ekran:** More > Budget Settings
**Önkoşul:** Birden fazla kategoride budget tanımlı.
**Adımlar:**
1. Budget Settings ekranını aç.
2. Listenin en üstündeki "TOTAL" satırını incele.

**Beklened sonuç:**
- TOTAL satırı tüm kategori budgetlarının toplamını gösterir.
- TOTAL satırına dokunulsa da modal açılmaz (read-only).

**Geçti mi? [ ]**

---

## TC-059: Budget — Budget View özet kartında "Budget Setting" linki
**Ekran:** Stats > Budget sub-tab
**Önkoşul:** En az bir budget tanımlı.
**Adımlar:**
1. Budget View'da özet kartının sağ üstündeki "Budget Setting >" linkine dokun.

**Beklened sonuç:**
- Budget Setting ekranı açılır.

**Geçti mi? [ ]**

---

## TC-060: Budget — Kategori satırına tıklama Budget Settings'e götürmeli
**Ekran:** Stats > Budget sub-tab
**Önkoşul:** En az bir budget tanımlı, kategori satırları görünüyor.
**Adımlar:**
1. Budget View'da bir kategori satırına dokun.

**Beklened sonuç:**
- Budget Setting ekranı açılır (tüm kategoriler ve budgetlar listelenir).

**Geçti mi? [ ]**

---

## Add/Edit Transaction Ekranı

---

## TC-061: Validasyon — Amount boş bırakılırsa kayıt yapılamamalı
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Amount alanını boş bırak.
2. Category ve Account seç.
3. "Save" butonuna dokun.

**Beklened sonuç:**
- Kayıt gerçekleşmez.
- Form validasyonu hatası gösterilir ("amount" veya "required" içerikli mesaj).

**Geçti mi? [ ]**

---

## TC-062: Validasyon — Amount = 0 girildiğinde kayıt yapılamamalı
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Amount alanına "0" gir.
2. Category ve Account seç.
3. "Save" butonuna dokun.

**Beklened sonuç:**
- Kayıt gerçekleşmez.
- "Invalid balance" veya "amount must be greater than zero" hata mesajı görünür.

**Geçti mi? [ ]**

---

## TC-063: Validasyon — Negatif amount girişi
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Amount alanına "-50" girmeye çalış.

**Beklened sonuç:**
- Negatif işareti klavye tarafından filtrelenir (yalnızca rakam, nokta ve virgüle izin verilir).
- "-50" girilemez.

**Geçti mi? [ ]**

---

## TC-064: Validasyon — Account seçilmeden kayıt yapılamamalı
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Amount alanına "50.00" gir.
2. Category seç.
3. Account seçmeden "Save" butonuna dokun.

**Beklened sonuç:**
- Kayıt gerçekleşmez.
- "Account is required" içerikli bir snackbar veya hata mesajı görünür.

**Geçti mi? [ ]**

---

## TC-065: Validasyon — Kategori seçmeden expense kaydedilebilmeli (opsiyonel alan)
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Type: "Expense" seçili.
2. Amount: "30.00" gir.
3. Category seçme (boş bırak).
4. Account seç.
5. "Save" butonuna dokun.

**Beklened sonuç:**
- Kayıt başarıyla kaydedilir (category opsiyonel).
- Transaction "Uncategorized" olarak listelenir.

**Geçti mi? [ ]**

---

## TC-066: Transfer type seçilince "To Account" alanı görünmeli
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Type seçicide "Transfer" seç.

**Beklened sonuç:**
- "Category" alanı ekrandan kaybolur.
- "To Account" alanı görünür hale gelir.
- "Account" alanı kaynak hesap olarak kalır.

**Geçti mi? [ ]**

---

## TC-067: Transfer — To Account seçilmeden kayıt yapılamamalı
**Ekran:** Add Transaction
**Önkoşul:** "Transfer" type seçili.
**Adımlar:**
1. Amount: "100.00" gir.
2. Account seç (kaynak hesap).
3. To Account seçme (boş bırak).
4. "Save" butonuna dokun.

**Beklened sonuç:**
- Kayıt gerçekleşmez.
- "To Account is required" içerikli hata mesajı görünür.

**Geçti mi? [ ]**

---

## TC-068: Transfer — Aynı hesap kaynak ve hedef seçilememeli
**Ekran:** Add Transaction
**Önkoşul:** "Transfer" type seçili, en az iki hesap mevcut.
**Adımlar:**
1. Account seçiciden "Nakit" seç.
2. To Account seçicini aç.

**Beklened sonuç:**
- To Account listesinde "Nakit" devre dışı (disabled) gösterilir; seçilemez.

**Geçti mi? [ ]**

---

## TC-069: Tarih seçici
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Tarih alanına (takvim ikonu) dokun.
2. Geçmiş bir tarihi seç (ör. 1 Ocak 2026).
3. "OK" butonuna dokun.

**Beklened sonuç:**
- Tarih alanı seçilen tarihi gösterir ("1 Jan 2026" formatında).
- Kaydedilen transaction seçilen tarihte listelenir.

**Geçti mi? [ ]**

---

## TC-070: Tarih seçici — Gelecek tarih seçilememeli
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Tarih alanına dokun.
2. Takvimde yarınki tarihi seçmeye çalış.

**Beklened sonuç:**
- Yarın ve sonrası tarihler devre dışıdır (lastDate: DateTime.now()).

**Geçti mi? [ ]**

---

## TC-071: Edit modunda mevcut değerler dolu gelmeli
**Ekran:** Transactions > Daily tab > Edit Transaction
**Önkoşul:** Kategori ve account seçilmiş bir transaction mevcut.
**Adımlar:**
1. Var olan bir transaction'a dokun.
2. Edit ekranı açılır.

**Beklened sonuç:**
- Type seçicide doğru type (expense/income/transfer) seçili.
- Amount alanı doğru değerle dolu (ör. "75.50").
- Category seçici doğru kategoriyi gösteriyor.
- Account seçici doğru hesabı gösteriyor.
- Tarih orijinal tarihle dolu.

**Geçti mi? [ ]**

---

## TC-072: Edit modunda delete butonu görünmeli
**Ekran:** Edit Transaction
**Önkoşul:** Var olan bir transaction düzenleniyor.
**Adımlar:**
1. Edit ekranının AppBar'ına bak.

**Beklened sonuç:**
- Sağ üstte kırmızı çöp kutusu (delete) ikonu görünür.
- Add modunda bu ikon görünmez.

**Geçti mi? [ ]**

---

## TC-073: Dirty state — değişiklik yapılıp geri gidilince onay sorulmalı
**Ekran:** Add/Edit Transaction
**Önkoşul:** Ekran açık; Amount alanına değer girilmiş.
**Adımlar:**
1. Amount alanına bir değer gir.
2. Sağ üstteki "X" (close) butonuna dokun.

**Beklened sonuç:**
- "Discard changes?" onay dialogu açılır.
- "Cancel" seçilirse ekran açık kalır.
- "Discard" seçilirse ekran kapanır, kayıt yapılmaz.

**Geçti mi? [ ]**

---

## TC-074: Type değişince kategori sıfırlanmalı
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık; Expense seçili ve bir kategori seçilmiş.
**Adımlar:**
1. Category seçiciden "Food" seç.
2. Type seçicide "Income" seçeneğine geç.

**Beklened sonuç:**
- Kategori seçici sıfırlanır (boş gösterilir).
- Önceki expense kategorisi seçili kalmaz.

**Geçti mi? [ ]**

---

## TC-075: Note alanı opsiyoneldir; kayıt yapılabilmeli
**Ekran:** Add Transaction
**Önkoşul:** Ekran açık.
**Adımlar:**
1. Amount, Category ve Account doldur.
2. Note alanını boş bırak.
3. "Save" butonuna dokun.

**Beklened sonuç:**
- Kayıt başarıyla kaydedilir.
- Transaction listesinde description/note boş görünür.

**Geçti mi? [ ]**

---

## Accounts Ekranı

---

## TC-076: Hesap bakiyesi — income transaction bakiyeyi artırmalı
**Ekran:** Accounts
**Önkoşul:** "Nakit" hesabı 500.00 EUR başlangıç bakiyesiyle mevcut.
**Adımlar:**
1. "Nakit" hesabına 200.00 EUR income ekle.
2. Accounts ekranına git.

**Beklened sonuç:**
- "Nakit" bakiyesi 700.00 EUR gösterilir.

**Geçti mi? [ ]**

---

## TC-077: Hesap bakiyesi — expense transaction bakiyeyi azaltmalı
**Ekran:** Accounts
**Önkoşul:** "Nakit" hesabı 500.00 EUR bakiyeyle mevcut.
**Adımlar:**
1. "Nakit" hesabından 150.00 EUR expense ekle.
2. Accounts ekranına git.

**Beklened sonuç:**
- "Nakit" bakiyesi 350.00 EUR gösterilir.

**Geçti mi? [ ]**

---

## TC-078: Hesap bakiyesi — transfer sonrası kaynak ve hedef güncellenmeli
**Ekran:** Accounts
**Önkoşul:** "Nakit" 500.00 EUR, "Banka" 300.00 EUR.
**Adımlar:**
1. "Nakit" → "Banka" 100.00 EUR transfer ekle.
2. Accounts ekranına git.

**Beklened sonuç:**
- "Nakit" bakiyesi 400.00 EUR.
- "Banka" bakiyesi 400.00 EUR.

**Geçti mi? [ ]**

---

## TC-079: Hesap bakiyesi — transaction silinince bakiye geri gelmeli
**Ekran:** Accounts + Transactions
**Önkoşul:** TC-077'den devam; "Nakit" 350.00 EUR.
**Adımlar:**
1. Transactions'ta 150.00 EUR expense'i sil (swipe veya edit ekranından).
2. Accounts ekranına git.

**Beklened sonuç:**
- "Nakit" bakiyesi 500.00 EUR'ya döner.

**Geçti mi? [ ]**

---

## TC-080: isExcluded transaction bakiyeye dahil edilmemeli
**Ekran:** Accounts
**Önkoşul:** isExcluded = true olan bir transaction veritabanında mevcut.
**Adımlar:**
1. isExcluded transaction'ın bağlı olduğu hesabın bakiyesini kontrol et.

**Beklened sonuç:**
- isExcluded transaction tutarı hesap bakiyesine yansımaz.

**Geçti mi? [ ]**

---

## TC-081: Hesap ekleme
**Ekran:** Accounts
**Önkoşul:** Accounts ekranı açık.
**Adımlar:**
1. "+" FAB butonuna dokun.
2. Account Add/Edit ekranını doldur (ad: "Kredi Kartı", başlangıç bakiyesi: -200.00).
3. Kaydet.

**Beklened sonuç:**
- Accounts listesinde yeni "Kredi Kartı" hesabı görünür.
- Bakiyesi -200.00 gösterilir.

**Geçti mi? [ ]**

---

## TC-082: Hesap düzenleme
**Ekran:** Accounts
**Önkoşul:** En az bir hesap mevcut.
**Adımlar:**
1. Var olan bir hesap satırına dokun.
2. Hesap adını değiştir.
3. Kaydet.

**Beklened sonuç:**
- Accounts listesinde hesap adı güncellenir.

**Geçti mi? [ ]**

---

## TC-083: Hesaplar gruplara göre listelenmeli
**Ekran:** Accounts
**Önkoşul:** Farklı gruplarda (ör. Wallet, Bank Account) hesaplar mevcut.
**Adımlar:**
1. Accounts ekranını aç.

**Beklened sonuç:**
- Hesaplar grup başlıkları (büyük harfli) altında gruplandırılmış biçimde listelenir.
- Boş grup başlıkları gösterilmez.

**Geçti mi? [ ]**

---

## TC-084: Bakiye boş olduğunda başlangıç bakiyesi gösterilmeli
**Ekran:** Accounts
**Önkoşul:** Yeni oluşturulmuş, hiç transaction girilmemiş bir hesap.
**Adımlar:**
1. Hesabı oluştur, başlangıç bakiyesi: 250.00.
2. Accounts ekranını aç.

**Beklened sonuç:**
- Hesap satırında 250.00 gösterilir (provider yüklenmeden önce initialBalance gösterilir).

**Geçti mi? [ ]**

---

## TC-085: Hesap bakiyesi Transactions Daily header ile tutarlı olmalı
**Ekran:** Accounts + Transactions
**Önkoşul:** Birden fazla transaction girilmiş.
**Adımlar:**
1. Transactions ekranında IncomeSummaryBar'da gösterilen income ve expense toplamlarını not et.
2. Accounts ekranındaki ilgili hesabın bakiyesini not et.

**Beklened sonuç:**
- Hesap bakiyesi = başlangıç bakiyesi + tüm income - tüm expense (ilgili transaction'lar için).
- Hesapta tutarsızlık yok.

**Geçti mi? [ ]**

---

## More / Category Management

---

## TC-086: Kategori listesi — Gelir ve gider sekmeleri
**Ekran:** More > Categories
**Önkoşul:** Uygulama açık.
**Adımlar:**
1. Alt menü "More" > "Categories" ekranına git.
2. "Income" ve "Expense" sekmelerini ayrı ayrı incele.

**Beklened sonuç:**
- "Income" sekmesinde yalnızca income kategorileri listelenir.
- "Expense" sekmesinde yalnızca expense kategorileri listelenir.
- Her satırda emoji ve kategori adı görünür.

**Geçti mi? [ ]**

---

## TC-087: Yeni expense kategorisi ekleme
**Ekran:** More > Categories
**Önkoşul:** Categories ekranı açık.
**Adımlar:**
1. "Expense" sekmesine geç.
2. "+" FAB butonuna dokun.
3. Sheet açılır; Type seçicide "Expense" seçili.
4. İsim alanına "Hobbies" yaz.
5. Emoji alanına "🎮" yaz.
6. "Save" butonuna dokun.

**Beklened sonuç:**
- Sheet kapanır.
- "Expense" listesinde "🎮 Hobbies" görünür.

**Geçti mi? [ ]**

---

## TC-088: Yeni income kategorisi ekleme
**Ekran:** More > Categories
**Önkoşul:** Categories ekranı açık.
**Adımlar:**
1. "Income" sekmesine geç.
2. "+" FAB butonuna dokun.
3. Type seçicide "Income" seçili olduğunu doğrula.
4. İsim: "Rental Income", Emoji: "🏠".
5. "Save" butonuna dokun.

**Beklened sonuç:**
- "Income" listesinde "🏠 Rental Income" görünür.

**Geçti mi? [ ]**

---

## TC-089: Kategori düzenleme
**Ekran:** More > Categories
**Önkoşul:** En az bir kategori mevcut.
**Adımlar:**
1. Var olan bir kategori satırına dokun.
2. Sheet açılır; mevcut isim ve emoji alanları dolu.
3. İsim alanını değiştir.
4. "Save" butonuna dokun.

**Beklened sonuç:**
- Sheet kapanır.
- Kategori listesinde güncellenmiş isim görünür.

**Geçti mi? [ ]**

---

## TC-090: Düzenleme modunda type seçici kilitli olmalı
**Ekran:** More > Categories > Edit
**Önkoşul:** Var olan bir expense kategorisi düzenleniyor.
**Adımlar:**
1. Bir expense kategorisine dokun.
2. Sheet açılır; Type seçiciye bak.

**Beklened sonuç:**
- Type seçici (Income / Expense segmented button) devre dışı (disabled); dokunulsa değişmez.
- Mevcut type korunur.

**Geçti mi? [ ]**

---

## TC-091: Kategori silme (long press)
**Ekran:** More > Categories
**Önkoşul:** Silinebilir özel bir kategori mevcut (varsayılan kategoriler silinemiyor olabilir).
**Adımlar:**
1. Bir kategori satırına uzun bas (long press).
2. Onay dialogu açılır; "Delete Category" butonuna dokun.

**Beklened sonuç:**
- Kategori listeden kalkar.
- Transactions listesinde bu kategoriye atanmış kayıtlar "Uncategorized" veya boş kategori ile görünür.

**Geçti mi? [ ]**

---

## TC-092: Kategori silme — onay dialogu iptal edilebilmeli
**Ekran:** More > Categories
**Önkoşul:** Var olan bir kategori mevcut.
**Adımlar:**
1. Bir kategoriye uzun bas.
2. Onay dialogunda "Cancel" butonuna dokun.

**Beklened sonuç:**
- Kategori silinmez, listede kalır.

**Geçti mi? [ ]**

---

## TC-093: Kategori — İsim boş bırakılırsa kayıt yapılamamalı
**Ekran:** More > Categories > Add
**Önkoşul:** Add Category sheet açık.
**Adımlar:**
1. İsim alanını boş bırak.
2. "Save" butonuna dokun.

**Beklened sonuç:**
- "Category name is required" hatası görünür.
- Sheet kapanmaz.

**Geçti mi? [ ]**

---

## TC-094: Kategori — Emoji opsiyonel; emoji olmadan kayıt yapılabilmeli
**Ekran:** More > Categories > Add
**Önkoşul:** Add Category sheet açık.
**Adımlar:**
1. İsim alanına "Diğer" yaz.
2. Emoji alanını boş bırak.
3. "Save" butonuna dokun.

**Beklened sonuç:**
- Kayıt başarıyla kaydedilir.
- Listede "Diğer" adıyla (emoji olmadan, varsayılan "•" gösterilebilir) görünür.

**Geçti mi? [ ]**

---

## TC-095: Kategori eklendikten sonra Add Transaction ekranında görünmeli
**Ekran:** More > Categories → Add Transaction
**Önkoşul:** TC-087'den devam; "Hobbies" kategorisi eklendi.
**Adımlar:**
1. Transactions ekranında "+" FAB butonuna dokun.
2. Category seçiciye dokun.
3. Category picker sheet'ini incele.

**Beklened sonuç:**
- "🎮 Hobbies" expense kategori listesinde görünür.
- Picker, doğru type'a göre filtreler (Expense görünümünde yalnızca expense kategorileri).

**Geçti mi? [ ]**

---

## Ek — Genel ve Regression Kontrolleri

---

## TC-096: Summary tab — Swipeable kartlar
**Ekran:** Transactions > Summary tab
**Önkoşul:** Uygulama açık.
**Adımlar:**
1. "Summary" sekmesine git.
2. Kartları sola/sağa swipe ederek geç (Stats, Accounts, Budget, Export kartları).

**Beklened sonuç:**
- 4 kart mevcut; sayfa göstergesi (dot indicator) aktif kartı vurgular.
- Her kart doğru içeriği gösterir.

**Geçti mi? [ ]**

---

## TC-097: Summary tab — Budget kartı "Budget not configured" mesajı
**Ekran:** Transactions > Summary tab > Budget kartı
**Önkoşul:** Hiçbir budget tanımlanmamış.
**Adımlar:**
1. Summary sekmesine git, Budget kartına swipe et.

**Beklened sonuç:**
- "Budget not configured" mesajı görünür.
- İlerleme çubuğu boş/gri; Today işareti günün konumuna göre çubukta belirir.

**Geçti mi? [ ]**

---

## TC-098: Summary tab — Export kartı "Coming soon" snackbar
**Ekran:** Transactions > Summary tab > Export kartı
**Önkoşul:** Uygulama açık.
**Adımlar:**
1. Summary sekmesine git, "Export to Excel" kartına swipe et.
2. Karta dokun.

**Beklened sonuç:**
- "Export coming soon" benzeri bir snackbar görünür ve 2 saniye sonra kaybolur.

**Geçti mi? [ ]**

---

## TC-099: Description tab — "Coming soon" metni
**Ekran:** Transactions > Description tab
**Önkoşul:** Uygulama açık.
**Adımlar:**
1. "Description" sekmesine git.

**Beklened sonuç:**
- "Coming soon" metni ekranda görünür.

**Geçti mi? [ ]**

---

## TC-100: IncomeSummaryBar — Monthly tab seçilince yıllık toplamlar gösterilmeli
**Ekran:** Transactions > Monthly tab
**Önkoşul:** Birden fazla aya ait transaction var.
**Adımlar:**
1. "Monthly" sekmesine geç.
2. Ekranın üstündeki IncomeSummaryBar'a bak.

**Beklened sonuç:**
- IncomeSummaryBar seçili yılın toplam income ve expense'ini gösterir (aylık değil).
- Diğer sekmelerde ise seçili ayın toplamları gösterilir.

**Geçti mi? [ ]**

---

*Toplam: 100 test senaryosu*
