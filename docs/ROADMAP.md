# MoneyWise — Roadmap

> **Owner:** pm
> **Last updated:** 2026-04-28 (initial)

This document tracks the long-term roadmap for MoneyWise. Detailed sprint plans live in `sprints/`.

---

## Phase 1 — MVP (16 weeks, 8 sprints)

**Goal:** Ship a fully functional offline-first personal finance app to App Store + Play Store.

| Sprint | Theme | Status |
|--------|-------|--------|
| 1 | Project skeleton & foundation | Planning |
| 2 | Account & Category management | Not started |
| 3 | Transaction CRUD (core feature) | Not started |
| 4 | Trans. tab views (Daily/Calendar/Monthly/Summary) | Not started |
| 5 | Stats & Budget | Not started |
| 6 | More tab & Settings | Not started |
| 7 | Recurring & Bookmark | Not started |
| 8 | Backup, Passcode, Polish — MVP Release | Not started |

**MVP Release Target:** ~16 weeks from project start
**Target version:** 1.0.0

See `SPEC.md` Section 16.1 for detailed sprint scope.

---

## Phase 2 — Cloud Sync (8 weeks, 4 sprints)

**Goal:** Add user accounts, cloud sync, and the recurring sync subscription tier.

- Sprint 9: Supabase setup + Auth + RLS
- Sprint 10: Sync engine (offline-first, conflict resolution)
- Sprint 11: Sync UI + iCloud/Google Drive backup
- Sprint 12: Sync subscription IAP + polish — Release 1.5

**Target version:** 1.5.0

---

## Phase 3 — Advanced Features (12 weeks, 6 sprints)

**Goal:** Differentiate from competitors with bank integration and family sharing.

- Bank integration (Open Banking — Turkey first)
- OCR receipt scanning (Google ML Kit)
- Family / group budget sharing
- Web / PWA companion
- Advanced backup (multi-cloud)

**Target version:** 2.0.0

---

## Phase 4 — Continuous Innovation

**Goal:** Maintain market relevance via AI and new platforms.

- AI category suggestions (TF Lite or server-side)
- Investment / crypto tracking
- Apple Watch + Wear OS
- Voice command integration (Siri / Google Assistant)
- Smart notifications based on spending patterns

---

## Decision Log

Major roadmap changes are tracked here:

- **2026-04-28** — Initial roadmap created based on SPEC.md Section 16.

---

## Open Questions for Sponsor

- Brand name and logo design timeline
- Final brand color (currently coral #FF6B5C — open to alternatives)
- App Store / Play Store regional launch (Turkey only first, or simultaneous global?)
- Pricing for Lifetime Premium (suggested ₺149,99 but TBD)
- Pricing for Sync subscription (suggested ₺29/month, ₺199/year but TBD)
