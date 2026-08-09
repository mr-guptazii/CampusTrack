/// Pure attendance-math helpers used by the Bunk Calculator screen and
/// dashboard percentage widgets. Kept dependency-free so it is trivially
/// unit-testable.
class BunkCalculator {
  BunkCalculator._();

  /// Current attendance percentage, 0-100. Returns 0 when [total] is 0.
  static double percentage(int attended, int total) {
    if (total <= 0) return 0;
    return (attended / total) * 100;
  }

  /// How many *more* classes the student can skip in a row while the
  /// percentage stays at or above [target] (0-100).
  ///
  /// Derived from: attended / (total + x) >= target/100
  /// => x <= attended * 100 / target - total
  static int classesCanMiss(int attended, int total, double target) {
    if (target <= 0) return 1 << 30; // no target => effectively unlimited
    if (total == 0) return 0;
    final currentPct = percentage(attended, total);
    if (currentPct < target) return 0;
    final maxTotal = (attended * 100 / target);
    final canMiss = (maxTotal - total).floor();
    return canMiss < 0 ? 0 : canMiss;
  }

  /// How many *consecutive* classes must be attended (assuming no more are
  /// missed) to bring the percentage up to [target].
  ///
  /// Derived from: (attended + x) / (total + x) >= target/100
  /// => x >= (target*total - 100*attended) / (100 - target)
  static int classesNeededToReach(int attended, int total, double target) {
    if (target >= 100) return 1 << 30; // impossible to guarantee, treat as large
    final currentPct = percentage(attended, total);
    if (currentPct >= target) return 0;
    final numerator = (target * total) - (100 * attended);
    final denominator = 100 - target;
    if (denominator <= 0) return 0;
    final needed = (numerator / denominator);
    return needed <= 0 ? 0 : needed.ceil();
  }

  /// Convenience: is the subject currently below its own [target]?
  static bool isBelowTarget(int attended, int total, double target) {
    return percentage(attended, total) < target;
  }
}
