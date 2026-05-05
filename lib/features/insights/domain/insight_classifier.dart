// Insight surface classifier — determines which screen an insight is visible on.
// EPIC8C-01: mapper-level filter; rule classes are NOT modified.
// See ADR-013 §Insight Klasifikasyon Tablosu for the authoritative rule table.

/// Identifies which surface an [InsightViewModel] should be rendered on.
///
/// Surfaces are mutually exclusive in V1:
/// - [home]: rendered in [ThisWeekSection] on the Home tab.
/// - [budget]: rendered in the insight slot on the Budget screen.
enum InsightSurface { home, budget }

/// Returns `true` if the insight with [insightId] should be visible on [surface].
///
/// Classification (ADR-013 addendum, Sponsor-approved 2026-05-07):
/// | Rule ID           | Surface       | Notes                          |
/// |-------------------|---------------|-------------------------------|
/// | concentration     | budget only   | Hidden on Home in V1           |
/// | big_transaction   | home only     | Hidden on Budget               |
/// | savings_goal      | home only     | Hidden on Budget               |
/// | daily_overpacing  | home only     | Hidden on Budget               |
/// | weekend_spending  | home only     | Hidden on Budget               |
bool insightVisibleOn(String insightId, InsightSurface surface) =>
    switch (surface) {
      InsightSurface.budget => insightId == 'concentration',
      InsightSurface.home => insightId != 'concentration',
    };
