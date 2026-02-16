import 'package:test/test.dart';
import 'package:velox_core/velox_core.dart';

void main() {
  group('VeloxNumExtension', () {
    test('duration getters', () {
      expect(500.milliseconds, const Duration(milliseconds: 500));
      expect(5.seconds, const Duration(seconds: 5));
      expect(10.minutes, const Duration(minutes: 10));
      expect(2.hours, const Duration(hours: 2));
      expect(7.days, const Duration(days: 7));
    });

    test('isBetween', () {
      expect(5.isBetween(1, 10), isTrue);
      expect(1.isBetween(1, 10), isTrue);
      expect(10.isBetween(1, 10), isTrue);
      expect(11.isBetween(1, 10), isFalse);
      expect(0.isBetween(1, 10), isFalse);
    });

    test('coerceIn', () {
      expect(5.coerceIn(1, 10), 5);
      expect(0.coerceIn(1, 10), 1);
      expect(15.coerceIn(1, 10), 10);
    });

    test('sign checks', () {
      expect((-1).isNegative, isTrue);
      expect(1.isPositive, isTrue);
      expect(0.isZero, isTrue);
    });
  });

  group('VeloxIntExtension', () {
    test('isEvenNumber / isOddNumber', () {
      expect(2.isEvenNumber, isTrue);
      expect(3.isOddNumber, isTrue);
    });

    test('ordinal', () {
      expect(1.ordinal, '1st');
      expect(2.ordinal, '2nd');
      expect(3.ordinal, '3rd');
      expect(4.ordinal, '4th');
      expect(11.ordinal, '11th');
      expect(12.ordinal, '12th');
      expect(13.ordinal, '13th');
      expect(21.ordinal, '21st');
      expect(22.ordinal, '22nd');
      expect(23.ordinal, '23rd');
      expect(101.ordinal, '101st');
      expect(111.ordinal, '111th');
    });

    test('times executes correct number of iterations', () {
      var count = 0;
      5.times((i) => count++);
      expect(count, 5);
    });
  });

  group('VeloxDoubleExtension', () {
    test('roundToPlaces', () {
      expect(3.14159.roundToPlaces(2), 3.14);
      expect(3.14159.roundToPlaces(3), 3.142);
      expect(3.14159.roundToPlaces(0), 3.0);
    });
  });
}
