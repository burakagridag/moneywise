# Recent Transactions — Engineer Redlines

**Reads:** `spec.md`, `tokens.json`
**Target widget:** `lib/features/home/presentation/widgets/recent_transactions_list.dart`
**Check first:** `lib/features/transactions/presentation/widgets/transaction_row.dart` — reuse if compact prop exists

---

## Dimension Map

| Visual element | Value | Token / constant |
|----------------|-------|-----------------|
| Container border radius | 14dp | `AppRadius.lg` |
| Container border width | 1dp | explicit 1 |
| Container horizontal margin | 16dp | `AppSpacing.lg` |
| Row height | 60dp | `AppHeights.listItem` |
| Row padding vertical | 12dp | `AppSpacing.md` |
| Row padding horizontal | 14dp | explicit 14 |
| Icon container size | 32×32dp | explicit 32 |
| Icon container radius | 6dp | `AppRadius.sm` |
| Icon size | 16×16dp | explicit 16 |
| Icon → name gap | 8dp | `AppSpacing.sm` |
| Name → amount gap | 8dp | `AppSpacing.sm` |
| Divider left inset | 54dp | explicit 54 (14 + 32 + 8) |
| Divider height | 1dp | explicit 1 |
| Section header top margin | 18dp | explicit 18 |
| Section header bottom margin | 10dp | explicit 10 |

---

## Color Map

| Element | Light | Dark |
|---------|-------|------|
| Container background | `AppColors.bgElevatedLight` | `AppColors.bgSecondary` |
| Container border | `AppColors.borderLight` | `AppColors.border` |
| Section header text | `AppColors.textSecondaryLight` | `AppColors.textSecondary` |
| "All →" link | `AppColors.brandPrimary` | `AppColors.brandPrimary` |
| Row name | `AppColors.textPrimaryLight` | `AppColors.textPrimary` |
| Income amount | `AppColors.income` | `AppColors.income` |
| Expense amount | `AppColors.expense` | `AppColors.expenseDark` |
| Transfer amount | `AppColors.transfer` | `AppColors.transfer` |
| Divider | `AppColors.bgTertiaryLight` | `AppColors.divider` |
| Row ripple | `AppColors.brandPrimaryGlow` | `AppColors.brandPrimaryGlow` |

---

## Typography Map

| Element | AppTypography | Override |
|---------|--------------|---------|
| Section header "RECENT" | `AppTypography.caption2` | `.toUpperCase()` on string |
| "All →" link | `AppTypography.caption1` | none |
| Row transaction name | `AppTypography.bodyMedium` | none |
| Row amount | `AppTypography.moneySmall` | none (already tabular, 17pt/600) |

---

## Amount Formatting

```
String formatAmount(TransactionEntity tx) {
  final formatted = currencyFormatter.format(tx.amount.abs());
  return switch (tx.type) {
    TransactionType.income   => '+$formatted',
    TransactionType.expense  => '−$formatted',  // U+2212 minus sign
    TransactionType.transfer => formatted,
  };
}

Color amountColor(TransactionEntity tx, bool isDark) {
  return switch (tx.type) {
    TransactionType.income   => AppColors.income,
    TransactionType.expense  => isDark ? AppColors.expenseDark : AppColors.expense,
    TransactionType.transfer => AppColors.transfer,
  };
}
```

---

## Layout Structure

```
Column(children: [
  // Section header
  Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, 18, AppSpacing.lg, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('RECENT', style: caption2 + secondaryColor),
        GestureDetector(
          onTap: onSeeAllTap,
          child: Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg, top: 16, bottom: 16),
            child: Text('All →', style: caption1.copyWith(color: brandPrimary)),
          ),
        ),
      ],
    ),
  ),
  // List container
  Container(
    margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: containerBg,
      border: Border.all(color: containerBorder, width: 1),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: isDark ? [] : [BoxShadow(...)],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(children: [
        RecentTransactionRow(transaction: transactions[0]),
        if (transactions.length > 1) ...[
          _InsetDivider(leftInset: 54),
          RecentTransactionRow(transaction: transactions[1]),
        ],
      ]),
    ),
  ),
])
```

---

## Inset Divider Widget

```
class _InsetDivider extends StatelessWidget {
  const _InsetDivider({required this.leftInset});
  final double leftInset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(left: leftInset),
      height: 1,
      color: isDark ? AppColors.divider : AppColors.bgTertiaryLight,
    );
  }
}
```

---

## Row Tap — Bottom Sheet

```
InkWell(
  onTap: () => showModalBottomSheet(
    context: context,
    builder: (_) => TransactionDetailSheet(transaction: transaction),
  ),
  splashColor: AppColors.brandPrimaryGlow,
  child: rowContent,
)
```

Use the existing `TransactionDetailSheet` — do not build a new one.

---

## Reuse Decision

Before creating `RecentTransactionRow`, check if `TransactionRow` in `lib/features/transactions/presentation/widgets/transaction_row.dart` accepts a `compact` parameter. If it does:
- Pass `compact: true`
- Do not create a new widget

If `compact` param does not exist:
- Create `RecentTransactionRow` as a private widget inside `recent_transactions_list.dart`
- Do NOT modify the existing `TransactionRow` (risk of regression in Transactions tab)

---

## Light Shadow

```
BoxShadow(
  color: Colors.black.withOpacity(0.04),
  blurRadius: 8,
  offset: Offset(0, 2),
)
```

Light mode only.

---

## Accessibility

```
Semantics(
  label: 'Recent transactions. ${transactions.length} shown.',
  child: Column(children: [
    // header with separate semantics for "All" button
    Semantics(
      label: 'View all transactions',
      button: true,
      child: ExcludeSemantics(child: allLinkWidget),
    ),
    // each row
    for (final tx in transactions.take(2))
      Semantics(
        label: '${tx.name}. ${formatSemanticAmount(tx)}. ${tx.type.name}. Tap for details.',
        button: true,
        child: ExcludeSemantics(child: RecentTransactionRow(transaction: tx)),
      ),
  ]),
)
```

---

## No New Tokens Required

All values map to existing AppColors, AppTypography, AppRadius, AppSpacing, and AppHeights tokens.
