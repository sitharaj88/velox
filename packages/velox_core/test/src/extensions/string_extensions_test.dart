import 'package:test/test.dart';
import 'package:velox_core/velox_core.dart';

void main() {
  group('VeloxStringExtension', () {
    group('isBlank / isNotBlank', () {
      test('empty string is blank', () {
        expect(''.isBlank, isTrue);
        expect(''.isNotBlank, isFalse);
      });

      test('whitespace-only string is blank', () {
        expect('   '.isBlank, isTrue);
        expect('\t\n'.isBlank, isTrue);
      });

      test('non-empty string is not blank', () {
        expect('hello'.isBlank, isFalse);
        expect('hello'.isNotBlank, isTrue);
      });
    });

    group('orNullIfBlank', () {
      test('returns null for blank string', () {
        expect(''.orNullIfBlank, isNull);
        expect('   '.orNullIfBlank, isNull);
      });

      test('returns string for non-blank', () {
        expect('hello'.orNullIfBlank, 'hello');
      });
    });

    group('capitalized', () {
      test('capitalizes first letter', () {
        expect('hello'.capitalized, 'Hello');
      });

      test('handles empty string', () {
        expect(''.capitalized, '');
      });

      test('handles single character', () {
        expect('h'.capitalized, 'H');
      });
    });

    group('case conversions', () {
      test('toCamelCase', () {
        expect('hello world'.toCamelCase, 'helloWorld');
        expect('hello_world'.toCamelCase, 'helloWorld');
        expect('hello-world'.toCamelCase, 'helloWorld');
        expect('HelloWorld'.toCamelCase, 'helloWorld');
      });

      test('toSnakeCase', () {
        expect('helloWorld'.toSnakeCase, 'hello_world');
        expect('hello world'.toSnakeCase, 'hello_world');
        expect('HelloWorld'.toSnakeCase, 'hello_world');
      });

      test('toKebabCase', () {
        expect('helloWorld'.toKebabCase, 'hello-world');
        expect('hello_world'.toKebabCase, 'hello-world');
      });

      test('toPascalCase', () {
        expect('hello world'.toPascalCase, 'HelloWorld');
        expect('hello_world'.toPascalCase, 'HelloWorld');
        expect('helloWorld'.toPascalCase, 'HelloWorld');
      });
    });

    group('truncate', () {
      test('truncates long strings', () {
        expect('hello world'.truncate(8), 'hello...');
      });

      test('returns original for short strings', () {
        expect('hi'.truncate(10), 'hi');
      });

      test('supports custom ellipsis', () {
        expect(
          'hello world'.truncate(9, ellipsis: '~'),
          'hello wo~',
        );
      });
    });

    group('validation', () {
      test('isEmail validates correctly', () {
        expect('test@example.com'.isEmail, isTrue);
        expect('invalid'.isEmail, isFalse);
        expect('a@b.c'.isEmail, isFalse);
        expect('test@example.co.uk'.isEmail, isTrue);
      });

      test('isUrl validates correctly', () {
        expect('https://example.com'.isUrl, isTrue);
        expect('http://localhost'.isUrl, isTrue);
        expect('not a url'.isUrl, isFalse);
      });

      test('isNumeric validates correctly', () {
        expect('12345'.isNumeric, isTrue);
        expect('12.34'.isNumeric, isFalse);
        expect('abc'.isNumeric, isFalse);
      });
    });

    test('reversed', () {
      expect('hello'.reversed, 'olleh');
      expect(''.reversed, '');
    });

    test('removeWhitespace', () {
      expect('h e l l o'.removeWhitespace, 'hello');
      expect('hello\tworld\n'.removeWhitespace, 'helloworld');
    });
  });

  group('VeloxNullableStringExtension', () {
    test('isNullOrBlank', () {
      expect((null as String?).isNullOrBlank, isTrue);
      expect(''.isNullOrBlank, isTrue);
      expect('   '.isNullOrBlank, isTrue);
      expect('hello'.isNullOrBlank, isFalse);
    });

    test('isNotNullOrBlank', () {
      expect((null as String?).isNotNullOrBlank, isFalse);
      expect('hello'.isNotNullOrBlank, isTrue);
    });

    test('orEmpty', () {
      expect((null as String?).orEmpty, '');
      expect('hello'.orEmpty, 'hello');
    });
  });
}
