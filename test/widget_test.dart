// Unit tests for the pure attendance-math helpers in BunkCalculator.
// These don't touch Firebase/Hive, so they run without any platform setup.

import 'package:flutter_test/flutter_test.dart';
import 'package:campustrack/core/utils/bunk_calculator.dart';

void main() {
  group('BunkCalculator.percentage', () {
    test('returns 0 when total is 0', () {
      expect(BunkCalculator.percentage(0, 0), 0);
    });

    test('computes attended/total * 100', () {
      expect(BunkCalculator.percentage(18, 24), 75.0);
    });
  });

  group('BunkCalculator.classesCanMiss', () {
    test('returns 0 when already below target', () {
      expect(BunkCalculator.classesCanMiss(10, 20, 75), 0);
    });

    test('returns how many more classes can be missed and stay at target', () {
      // 30 attended / 30 total = 100%. Target 75%: attended*100/target - total
      // = 30*100/75 - 30 = 40 - 30 = 10
      expect(BunkCalculator.classesCanMiss(30, 30, 75), 10);
    });
  });

  group('BunkCalculator.classesNeededToReach', () {
    test('returns 0 when already at or above target', () {
      expect(BunkCalculator.classesNeededToReach(18, 24, 75), 0);
    });

    test('computes consecutive classes needed to reach target', () {
      // 10 attended / 20 total = 50%. Needs to reach 75%.
      final needed = BunkCalculator.classesNeededToReach(10, 20, 75);
      final projectedPct = BunkCalculator.percentage(10 + needed, 20 + needed);
      expect(projectedPct, greaterThanOrEqualTo(75));
    });
  });

  group('BunkCalculator.isBelowTarget', () {
    test('flags a subject under its target', () {
      expect(BunkCalculator.isBelowTarget(10, 20, 75), isTrue);
    });

    test('does not flag a subject at or above its target', () {
      expect(BunkCalculator.isBelowTarget(18, 24, 75), isFalse);
    });
  });
}
