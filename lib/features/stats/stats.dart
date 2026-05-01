// Public barrel for the stats feature.
// StatsScreen is not mounted in the navigation shell (EPIC8A-01/02).
// Providers (stats_provider) are still consumed by budget and transactions features.
// TODO(EPIC8A-08): re-export chart widgets once moved to HomeScreen.
export 'presentation/providers/stats_provider.dart';
