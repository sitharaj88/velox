// ignore_for_file: avoid_redundant_argument_values
import 'package:test/test.dart';
import 'package:velox_logger/velox_logger.dart';

void main() {
  LogRecord makeRecord({
    LogLevel level = LogLevel.info,
    String? tag,
  }) => LogRecord(
    level: level,
    message: 'test',
    timestamp: DateTime.now(),
    tag: tag,
  );

  group('LevelFilter', () {
    test('allows records at minimum level', () {
      final filter = LevelFilter(LogLevel.warning);

      expect(filter.shouldLog(makeRecord(level: LogLevel.warning)), isTrue);
    });

    test('allows records above minimum level', () {
      final filter = LevelFilter(LogLevel.warning);

      expect(filter.shouldLog(makeRecord(level: LogLevel.error)), isTrue);
      expect(filter.shouldLog(makeRecord(level: LogLevel.fatal)), isTrue);
    });

    test('blocks records below minimum level', () {
      final filter = LevelFilter(LogLevel.warning);

      expect(filter.shouldLog(makeRecord(level: LogLevel.info)), isFalse);
      expect(filter.shouldLog(makeRecord(level: LogLevel.debug)), isFalse);
      expect(filter.shouldLog(makeRecord(level: LogLevel.trace)), isFalse);
    });

    test('trace level allows everything', () {
      final filter = LevelFilter(LogLevel.trace);

      for (final level in LogLevel.values) {
        expect(filter.shouldLog(makeRecord(level: level)), isTrue);
      }
    });
  });

  group('TagFilter', () {
    test('allows all tags by default', () {
      final filter = TagFilter();

      expect(filter.shouldLog(makeRecord(tag: 'Anything')), isTrue);
      expect(filter.shouldLog(makeRecord()), isTrue);
    });

    test('allowedTags restricts to specified tags', () {
      final filter = TagFilter(allowedTags: {'Auth', 'DB'});

      expect(filter.shouldLog(makeRecord(tag: 'Auth')), isTrue);
      expect(filter.shouldLog(makeRecord(tag: 'DB')), isTrue);
      expect(filter.shouldLog(makeRecord(tag: 'Network')), isFalse);
    });

    test('blockedTags blocks specified tags', () {
      final filter = TagFilter(blockedTags: {'Verbose', 'Spam'});

      expect(filter.shouldLog(makeRecord(tag: 'Verbose')), isFalse);
      expect(filter.shouldLog(makeRecord(tag: 'Spam')), isFalse);
      expect(filter.shouldLog(makeRecord(tag: 'Auth')), isTrue);
    });

    test('blockedTags takes precedence over allowedTags', () {
      final filter = TagFilter(
        allowedTags: {'Auth', 'DB'},
        blockedTags: {'Auth'},
      );

      expect(filter.shouldLog(makeRecord(tag: 'Auth')), isFalse);
      expect(filter.shouldLog(makeRecord(tag: 'DB')), isTrue);
    });

    test('allows null tags by default', () {
      final filter = TagFilter(allowedTags: {'Auth'});

      // Records with no tag pass through when requireTag is false
      expect(filter.shouldLog(makeRecord()), isTrue);
    });

    test('requireTag blocks null tags', () {
      final filter = TagFilter(requireTag: true);

      expect(filter.shouldLog(makeRecord()), isFalse);
      expect(filter.shouldLog(makeRecord(tag: 'Any')), isTrue);
    });
  });

  group('CompositeFilter', () {
    test('passes when all filters pass', () {
      final filter = CompositeFilter([
        LevelFilter(LogLevel.info),
        TagFilter(allowedTags: {'Auth'}),
      ]);

      expect(
        filter.shouldLog(makeRecord(level: LogLevel.info, tag: 'Auth')),
        isTrue,
      );
    });

    test('blocks when any filter blocks', () {
      final filter = CompositeFilter([
        LevelFilter(LogLevel.warning),
        TagFilter(allowedTags: {'Auth'}),
      ]);

      // Level too low
      expect(
        filter.shouldLog(makeRecord(level: LogLevel.info, tag: 'Auth')),
        isFalse,
      );

      // Wrong tag
      expect(
        filter.shouldLog(makeRecord(level: LogLevel.error, tag: 'Network')),
        isFalse,
      );
    });

    test('empty filters allows everything', () {
      final filter = CompositeFilter([]);

      expect(filter.shouldLog(makeRecord()), isTrue);
    });

    test('works with single filter', () {
      final filter = CompositeFilter([LevelFilter(LogLevel.error)]);

      expect(filter.shouldLog(makeRecord(level: LogLevel.error)), isTrue);
      expect(filter.shouldLog(makeRecord(level: LogLevel.info)), isFalse);
    });
  });
}
