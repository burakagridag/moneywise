# MoneyWise — Turkish (TR) Wording List
## Sponsor Pre-Approval Request — EPIC8C-01 Pre-PR Gate

**Date:** 2026-05-08  
**Branch:** `sprint/8c-insight-rules-budget-ui`  
**Prepared by:** QA Engineer  
**Source:** `lib/core/i18n/arb/app_tr.arb` (364 lines, 264 keys)

---

> **Sponsor action required:** Please review all strings below and confirm:
> - ✅ Approved as-is
> - 📝 Change requested (add comment with desired wording)
>
> Strings are grouped by screen. Only user-visible strings are listed
> (Semantics/accessibility labels are in the Accessibility section).

---

## 1. Navigation Tabs

| ARB Key | TR String | Screen |
|---------|-----------|--------|
| `tabHome` | Ana Sayfa | Bottom nav |
| `tabTransactions` | İşlemler | Bottom nav |
| `tabBudget` | Bütçe | Bottom nav |
| `tabMore` | Daha Fazla | Bottom nav |

---

## 2. Home Screen

### 2a. Greetings
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `homeGreetingMorning` | Günaydın | Morning greeting (before 12:00) |
| `homeGreetingAfternoon` | İyi günler | Afternoon greeting (12:00–18:00) |
| `homeGreetingEvening` | İyi akşamlar | Evening greeting (after 18:00) |

### 2b. Total Balance Card
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `homeTotalBalanceLabel` | Toplam Bakiye | Card title |
| `homeTrendSinceLastMonth` | geçen aydan bu yana | Trend subtitle |

### 2c. Budget Pulse Card
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `homeBudgetPulseTitle` | Bütçe nabzı | Section title |
| `homeBudgetPulseViewLink` | Görüntüle | Link to Budget tab |
| `homeBudgetPulseSetCta` | Aylık bütçe belirle | Empty state CTA title |
| `homeBudgetPulseSetCtaSubtitle` | Harcamalarınızın üstünde kalın | Empty state CTA subtitle |
| `homeBudgetPulseSetBudgetButton` | Bütçe belirle | Empty state button |
| `homeBudgetPulseOverBudget` | Bütçe aşıldı | Badge when over budget |
| `homeBudgetPulseLeftOf` | kaldı (toplam {budget}) | Remaining label (e.g. "€150 kaldı (toplam €300)") |
| `homeBudgetPulseDailyPace` | Günlük harcama: | Daily spend label |
| `homeBudgetPulseCanSpend` | · Harcayabilirsiniz | Can-spend suffix |
| `homeBudgetPulsePerDay` | /gün | Per-day suffix (e.g. "€10/gün") |
| `homeBudgetPulseOverBudgetSuffix` | · Bütçe aşıldı | Over-budget inline suffix |
| `homeBudgetPulseOnBudget` | · Bütçede | On-budget inline suffix |
| `homeBudgetPulseOnBudgetLabel` | Bütçede | On-budget badge |
| `homeBudgetPulseUnavailable` | Bütçe verisi kullanılamıyor | Error state |

### 2d. Recent Transactions
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `homeRecentTitle` | Son İşlemler | Section title |
| `homeRecentAll` | Tümü | "All" filter chip |
| `homeRecentCouldNotLoad` | İşlemler yüklenemedi | Error state |

### 2e. This Week (Insights)
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `homeThisWeekTitle` | Bu hafta | Section title |
| `homeInsightsUnavailable` | İçgörüler kullanılamıyor | Error state |

### 2f. Empty State
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `homeEmptyStateAddTransactionTitle` | İlk işleminizi ekleyin | Empty prompt title |
| `homeEmptyStateAddTransactionSubtitle` | Gelir, gider ve transferleri takip edin | Empty prompt subtitle |
| `homeEmptyStateManageAccountsTitle` | Hesaplarınızı yönetin | Empty prompt title |
| `homeEmptyStateManageAccountsSubtitle` | Nakit, banka veya kart hesabı ekleyin | Empty prompt subtitle |
| `homeEmptyStateSetBudgetTitle` | Aylık bütçe belirleyin | Empty prompt title |
| `homeEmptyStateSetBudgetSubtitle` | Harcamalarınızın üstünde kalın | Empty prompt subtitle |

---

## 3. Budget Screen (EPIC8C-01) ⭐ NEW

### 3a. Hero Card
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `budgetScreenTitle` | Bütçe | Screen / AppBar title |
| `budgetHeroLabelRemaining` | KALAN BU AY | Hero card title (uppercase) |
| `budgetHeroDaysLeft` | {n} gün kaldı | Subtitle (e.g. "12 gün kaldı") |
| `budgetHeroSpentOf` | {budget} bütçeden {spent} | Spent-of label (e.g. "€300 bütçeden €150") |
| `budgetHeroIdealPace` | İdeal hız: {amount} | Ideal daily pace (e.g. "İdeal hız: €10") |

### 3b. Metric Cards
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `budgetMetricDailyTitle` | GÜNLÜK | Daily metric card title (uppercase) |
| `budgetMetricDailySafe` | {amount} harcayabilirsin | Daily safe-to-spend subtitle |
| `budgetMetricLastMonthTitle` | GEÇEN AY | Last month metric card title (uppercase) |
| `budgetMetricDeltaDecrease` | ↓ %{pct} daha az | Delta label (e.g. "↓ %15 daha az") |
| `budgetMetricDeltaIncrease` | ↑ %{pct} daha fazla | Delta label (e.g. "↑ %10 daha fazla") |
| `budgetMetricDeltaSame` | = Geçen ayla aynı | No change label |
| `budgetMetricDeltaNoData` | Geçen ay verisi yok | No previous data label |

### 3c. Categories Section
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `budgetCategoriesTitle` | KATEGORİLER | Section header (uppercase) |
| `budgetCategoriesEditLink` | Düzenle › | Edit link button |
| `budgetCategoriesCollapsedCount` | {n} kategori daha | Collapsed row (e.g. "3 kategori daha") |
| `budgetCategoriesCollapsedSubtitle` | Bütçesi yok | Subtitle for categories with no budget |

### 3d. Distribution Section
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `budgetDistributionTitle` | DAĞILIM | Section header (uppercase) |
| `budgetDistributionFooter` | Bu ay {amount} | Donut footer (e.g. "Bu ay €425") |

### 3e. Empty State
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `budgetEmptyTitle` | Aylık bütçeni belirle | Empty state title |
| `budgetEmptySubtitle` | Kategorilere göre harcamalarını takip et | Empty state subtitle |
| `budgetEmptyCTA` | Bütçeyi başlat | Primary CTA button |
| `budgetEmptySkip` | Sonra ayarla | Secondary skip link |

---

## 4. Insight Cards (Home + Budget screens)

| ARB Key | TR String | Surface | Context |
|---------|-----------|---------|---------|
| `insightConcentrationTitle` | Harcama yoğunlaşması | Budget | Card title |
| `insightConcentrationBody` | Harcamanın %{pct}'i tek kategoride. | Budget | Card body (e.g. "Harcamanın %80'i tek kategoride.") |
| `insightSavingsGoalTitle` | Düşük tasarruf oranı | Home | Card title |
| `insightSavingsGoalBody` | Bu ay %10'dan az birikim. | Home | Card body |
| `insightDailyOverpacingTitle` | Aşırı harcama | Home | Card title |
| `insightDailyOverpacingBody` | Bu hızda bütçenizi aşacaksınız. | Home | Card body |
| `insightBigTransactionTitle` | Büyük işlem | Home | Card title |
| `insightBigTransactionBodyNormal` | {amount} (bütçenin %{pct}'i) | Home | Card body (e.g. "€700 (bütçenin %35'i)") |
| `insightBigTransactionBodyExceeds` | Aylık bütçenizi aşan işlem | Home | Card body when tx > budget |
| `insightWeekendSpendingTitle` | Hafta sonu harcaması yüksek | Home | Card title |
| `insightWeekendSpendingBody` | Hafta sonu hafta içinden %{pct} yüksek. | Home | Card body (e.g. "Hafta sonu hafta içinden %120 yüksek.") |

---

## 5. Transactions Screen

### 5a. Tab Labels
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `tabDaily` | Günlük | Daily sub-tab |
| `tabCalendar` | Takvim | Calendar sub-tab |
| `tabMonthly` | Aylık | Monthly sub-tab |
| `tabSummary` | Özet | Summary sub-tab |
| `tabDescription` | Açıklama | Description sub-tab |

### 5b. Daily Tab
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `dailyEmptyTitle` | Henüz işlem eklenmedi | Empty state title |
| `dailyEmptySubtitle` | Gelir, gider veya transfer eklemek için + butonuna dokunun. | Empty state subtitle |
| `dailyEmptyCta` | İşlem Ekle | Empty state button |
| `calendarNoTransactions` | İşlem yok | Calendar empty cell |
| `calendarDayPanelNoTransactions` | Bu gün için işlem yok.\nEklemek için + butonuna dokunun. | Day panel empty |
| `monthlyNoTransactions` | Bu ayda işlem yok. | Monthly tab empty |
| `monthlyCurrentWeekLabel` | Bu hafta | This week label |
| `noTransactionsThisMonth` | Bu ay işlem yok | General empty |
| `tapPlusToAddFirst` | İlk işleminizi eklemek için + tuşuna basın. | Add first prompt |
| `failedToLoadTransactions` | İşlemler yüklenemedi. | Error state |

### 5c. Transaction Summary Row
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `summaryIncome` | Gelir | Summary bar |
| `summaryExpense` | Gider | Summary bar |
| `summaryTotal` | Toplam | Summary bar |
| `expenseLabel` | Gider | Row type label |
| `totalLabel` | Toplam | Row total label |
| `today` | Bugün | Date grouping header |

### 5d. Add/Edit Transaction
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `addTransaction` | İşlem Ekle | Screen title / FAB tooltip |
| `editTransaction` | İşlemi Düzenle | Screen title |
| `saveAndContinue` | Kaydet ve Devam Et | Secondary button |
| `deleteTransaction` | İşlemi Sil | Action |
| `deleteTransactionConfirm` | Bu işlemi silmek istediğinizden emin misiniz? | Confirm dialog |
| `deleteTransactionTitle` | İşlemi Sil? | Dialog title |
| `deleteTransactionMessage` | Bu işlem kalıcı olarak silinecek. Bu işlem geri alınamaz. | Dialog message |
| `toAccount` | Hedef Hesap | Transfer target field |
| `errorDeletingTransaction` | İşlem silinemedi. Lütfen tekrar deneyin. | Error toast |
| `errorSavingTransaction` | İşlem kaydedilemedi. Lütfen tekrar deneyin. | Error toast |

### 5e. Search
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `searchHint` | İşlem ara... | Search bar placeholder |
| `clearSearch` | Aramayı temizle | Clear button tooltip |
| `searchNoResults` | İşlem bulunamadı | Empty search result |

### 5f. Filter
| ARB Key | TR String | Context |
|---------|-----------|---------|
| `filterTitle` | Filtrele | Filter sheet title |
| `filterTypes` | Tür | Type filter section |
| `filterCategory` | Kategori | Category filter section |
| `filterNoCategory` | Tüm kategoriler | All-categories chip |
| `filterDateRange` | Tarih Aralığı | Date range section |
| `filterReset` | Sıfırla | Reset button |
| `filterApply` | Uygula | Apply button |

---

## 6. Budget Setting Screen

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `budgetSettingTitle` | Bütçe Ayarı | Screen / AppBar title |
| `budgetSettingTotal` | TOPLAM | Total row label |
| `budgetSettingNoBudget` | Bütçe ayarlanmadı | No budget row |
| `budgetSettingClearBudget` | Bütçeyi temizle | Clear action |
| `budgetSettingOnlyThisMonth` | Yalnızca bu ay | Checkbox label |
| `budgetSettingAmountHint` | 0,00 | Amount field hint |
| `budgetSettingAmountGreaterThanZero` | Lütfen sıfırdan büyük bir tutar girin. | Validation error |
| `budgetSettingAmountTooLarge` | Tutar çok büyük. | Validation error |
| `budgetSettingRemoveConfirmTitle` | Bütçe kaldırılsın mı? | Dialog title |
| `budgetSettingRemoveConfirmMessage` | 'Yalnızca bu ay' seçili değilse tüm gelecek aylar etkilenir. | Dialog message |
| `budgetSettingRemoveAction` | Kaldır | Dialog action |
| `budgetSettingDiscardTitle` | Değişiklikler iptal edilsin mi? | Dialog title |
| `budgetSettingDiscardMessage` | Kaydedilmemiş değişiklikler kaybolacak. | Dialog message |
| `budgetSettingDiscardAction` | İptal Et | Dialog action |
| `budgetSettingKeepEditing` | Düzenlemeye Devam Et | Dialog cancel |
| `budgetSetting` | Bütçe Ayarı | Legacy route label |
| `budgetViewCouldNotLoad` | Bütçe verileri yüklenemedi | Error state |
| `budgetViewNoBudgetSet` | Bütçe yok | No budget label |
| `budgetViewIncludesCarryOver` | Geçen aydan {amount} devir dahil | Carry-over note |

---

## 7. Category Budget (per-category budget rows)

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `budgetOf` | Bütçe | Budget amount label |
| `budgetSpent` | Harcanan | Spent amount label |
| `budgetRemaining` | Kalan | Remaining amount label |
| `budgetOverBy` | Aşım | Over-budget label |
| `budgetCarryOver` | Devreden | Carry-over label |
| `budgetEffective` | Efektif bütçe | Effective budget label |
| `budgetAddNew` | Bütçe Ekle | Add new budget action |
| `budgetEditExisting` | Bütçeyi Düzenle | Edit budget action |
| `budgetDeleteConfirm` | Bu bütçe silinsin mi? | Confirm dialog |
| `budgetDeleteAction` | Bütçeyi Sil | Delete action |
| `budgetSavedSuccess` | Bütçe kaydedildi | Success toast |
| `budgetDeletedSuccess` | Bütçe silindi | Success toast |
| `budgetErrorSaving` | Bütçe kaydedilemedi. Lütfen tekrar deneyin. | Error toast |
| `budgetErrorDeleting` | Bütçe silinemedi. Lütfen tekrar deneyin. | Error toast |
| `budgetEffectiveFrom` | Başlangıç ayı | Date picker label |
| `budgetEffectiveTo` | Bitiş ayı (boş bırakılırsa süresiz) | Date picker label |
| `budgetAmountRequired` | Tutar zorunludur | Validation error |
| `budgetCategoryRequired` | Kategori zorunludur | Validation error |
| `noBudgetThisMonth` | Bu dönem için bütçe yok. | Empty state |
| `setBudgetCta` | Bütçe Ayarla | CTA button |
| `budgetNotConfigured` | Henüz bütçe ayarlanmadı. | Not configured |
| `budgetCategoryPickerTitle` | Kategorileri seç | Picker title |
| `budgetCategoryPickerCTA` | Devam et ({n}) | Picker CTA (e.g. "Devam et (3)") |

---

## 8. More Screen

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `settings` | Ayarlar | Menu item |
| `categories` | Kategoriler | Menu item |
| `accounts` | Hesaplar | Menu item |
| `bookmarks` | Yer İşaretleri | Menu item |

---

## 9. Settings Screen

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `appearance` | Görünüm | Settings section / tile |
| `themeLight` | Açık Tema | Theme option |
| `themeDark` | Koyu Tema | Theme option |
| `themeSystem` | Sistem | Theme option |
| `language` | Dil | Settings tile |
| `currency` | Para Birimi | Settings tile |

---

## 10. Accounts Screen

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `addAccount` | Hesap Ekle | FAB tooltip / screen title |
| `editAccount` | Hesap Düzenle | Screen title |
| `accountName` | Hesap Adı | Form field label |
| `accountGroup` | Hesap Grubu | Form field label |
| `initialBalance` | Başlangıç Bakiyesi | Form field label |
| `includeInTotals` | Toplamda Göster | Toggle label |
| `includeInTotalDescription` | Bu hesabın bakiyesini toplam net değerinize dahil edin | Toggle description |
| `accountNameRequired` | Hesap adı zorunludur | Validation error |
| `invalidBalance` | Lütfen geçerli bir sayı girin | Validation error |
| `errorSavingAccount` | Hesap kaydedilemedi. Lütfen tekrar deneyin. | Error toast |
| `emptyAccountsMessage` | Henüz hesap yok.\nİlk hesabınızı eklemek için + tuşuna basın. | Empty state |
| `currentBalance` | Mevcut Bakiye | Balance label |

---

## 11. Categories Screen

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `addCategory` | Kategori Ekle | FAB tooltip / screen title |
| `editCategory` | Kategori Düzenle | Screen title |
| `categoryName` | Kategori Adı | Form field label |
| `categoryNameRequired` | Kategori adı zorunludur | Validation error |
| `categoryIcon` | İkon (emoji) | Form field label |
| `emptyCategoriesMessage` | Henüz kategori yok. | Empty state |
| `deleteCategory` | Kategori Sil | Action |
| `deleteCategoryConfirm` | Bu kategoriyi silmek istediğinizden emin misiniz? | Confirm dialog |
| `errorDeletingCategory` | Kategori silinemedi. Lütfen tekrar deneyin. | Error toast |
| `errorUpdatingCategory` | Kategori güncellenemedi. Lütfen tekrar deneyin. | Error toast |
| `errorSavingCategory` | Kategori kaydedilemedi. Lütfen tekrar deneyin. | Error toast |
| `defaultBadge` | Varsayılan | Default category badge |

---

## 12. Bookmarks Screen

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `addBookmark` | Yer İşareti Ekle | Screen title / action |
| `editBookmark` | Yer İşareti Düzenle | Screen title |
| `bookmarkDeleteAction` | Yer İşaretini Sil | Action |
| `bookmarkDeleteConfirm` | Bu yer işareti silinsin mi? | Confirm dialog |
| `bookmarkEmptyTitle` | Henüz yer işareti yok | Empty state title |
| `bookmarkEmptySubtitle` | Sık kullandığın işlemleri yer işareti olarak kaydet. | Empty state subtitle |
| `bookmarkName` | Yer İşareti Adı | Form field label |
| `bookmarkNameHint` | ör. Sabah Kahvesi | Form field hint |
| `bookmarkNameRequired` | Ad zorunludur | Validation error |
| `bookmarkPickerTitle` | Yer İşareti Seç | Picker title |
| `bookmarkPickerEmpty` | Henüz yer işareti yok | Picker empty |
| `bookmarkPickerGoToBookmarks` | Yer İşaretlerini Yönet | Picker link |
| `errorSavingBookmark` | Yer işareti kaydedilemedi. Lütfen tekrar deneyin. | Error toast |
| `errorDeletingBookmark` | Yer işareti silinemedi. Lütfen tekrar deneyin. | Error toast |
| `bookmarkSavedSuccess` | Yer işareti kaydedildi | Success toast |
| `bookmarkDeletedSuccess` | Yer işareti silindi | Success toast |

---

## 13. Notes Tab (Stats)

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `noteViewNoNotes` | Not yok | Empty state title |
| `noteViewNoNotesSubtitle` | Notlu işlemler burada görünecek. | Empty state subtitle |
| `noteViewNoNote` | (not yok) | Row label when no note |
| `noteViewSortAmount` | Tutar | Sort option |
| `noteViewSortCount` | Sayı | Sort option |
| `noteViewDeleteConfirmTitle` | İşlem Silinsin Mi? | Dialog title |
| `noteViewDeleteConfirmMessage` | Bu işlem kalıcı olarak silinecek. | Dialog message |
| `noteViewCouldNotLoad` | Notlar yüklenemedi. | Error state |
| `noteColumnLabel` | Not | Table column header |
| `amountColumnLabel` | Tutar | Table column header |

---

## 14. Accessibility Labels (Semantics — Screen Reader)

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `semanticAmountPositive` | +{amount} | Screen reader: positive amount |
| `semanticAmountNegative` | -{amount} | Screen reader: negative amount |
| `homeRecentSemanticContainerLabel` | Son işlemler. {count} gösteriliyor. | Recent list container |
| `homeRecentSeeAllSemanticLabel` | Tüm işlemleri görüntüle | See all link |
| `semanticTransactionRowHint` | Detaylar için dokunun. | Transaction row hint |
| `homeBudgetPulseViewSemanticLabel` | Bütçe detaylarını görüntüle | Budget pulse View link |
| `budgetHeroSemanticOverBudget` | bütçe aşıldı | Hero card: over-budget suffix |
| `budgetHeroSemanticRemaining` | kalan | Hero card: remaining suffix |
| `budgetCategorySemanticCategory` | kategorisi | Category row: category word |
| `budgetCategorySemanticSpent` | harcandı | Category row: spent word |
| `budgetCategorySemanticBudget` | bütçe | Category row: budget word |
| `budgetCategorySemanticOverBudget` | Bütçe aşıldı. | Category row: over-budget suffix |

---

## 15. Common / Shared

| ARB Key | TR String | Context |
|---------|-----------|---------|
| `save` | Kaydet | Button |
| `cancel` | İptal | Button |
| `loading` | Yükleniyor... | Loading indicator |
| `retry` | Yeniden Dene | Retry button |
| `retryButton` | Tekrar Dene | Retry button (alt) |
| `comingSoon` | Yakında | Coming soon badge |
| `seeAllButton` | Tümünü Gör | See all link |
| `deleteAction` | Sil | Delete action |
| `editAction` | Düzenle | Edit action |
| `noDataForPeriod` | Bu dönem için veri yok | Chart empty state |
| `addTransactionsForBreakdown` | Harcama dağılımını görmek için işlem ekleyin. | Chart empty subtitle |
| `couldNotLoadStatistics` | İstatistikler yüklenemedi. | Stats error |
| `pleaseRetryStatistics` | Lütfen tekrar deneyin. | Stats error subtitle |
| `errorLoadTitle` | Veriler yüklenemedi | Generic error title |
| `errorLoadSubtitle` | Lütfen tekrar deneyin. | Generic error subtitle |
| `savingsRateLabel` | Tasarruf Oranı | Stats label |
| `noExpensesThisMonth` | Bu ay gider yok. | Empty state |
| `income` | Gelir | Transaction type |
| `expense` | Gider | Transaction type |
| `transfer` | Transfer | Transaction type |
| `amount` | Tutar | Field label |
| `category` | Kategori | Field label |
| `account` | Hesap | Field label |
| `note` | Not | Field label |
| `description` | Açıklama | Field label |
| `date` | Tarih | Field label |
| `exportToExcelTitle` | Excel'e Aktar | Export option |
| `exportComingSoon` | Dışa aktarma özelliği yakında | Coming soon |

---

## Summary

| Section | Key Count |
|---------|-----------|
| Navigation | 4 |
| Home Screen | 24 |
| Budget Screen (EPIC8C-01) ⭐ NEW | 26 |
| Insight Cards | 10 |
| Transactions Screen | 30 |
| Budget Setting | 19 |
| Category Budget Rows | 20 |
| More Screen | 4 |
| Settings | 6 |
| Accounts | 12 |
| Categories | 13 |
| Bookmarks | 14 |
| Notes Tab | 9 |
| Accessibility (Semantics) | 12 |
| Common / Shared | 31 |
| **TOTAL** | **264** |

---

## Sponsor Sign-Off

| Item | Status |
|------|--------|
| Budget Screen TR strings (26 keys) reviewed | ⬜ Pending |
| Insight card TR strings reviewed | ⬜ Pending |
| Accessibility label TR strings reviewed | ⬜ Pending |
| All other screen strings reviewed | ⬜ Pending |
| **Overall TR wording approved** | ⬜ Pending |

---

*Generated: 2026-05-08 — QA Pre-PR Full Regression Smoke Gate*
