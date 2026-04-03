import 'package:flutter_test/flutter_test.dart';
import 'package:campus_connect/utils/validators.dart';
import 'package:campus_connect/utils/helpers.dart';

void main() {
  group('Validators', () {
    test('validateEmail rejects non-college email', () {
      expect(Validators.validateEmail('test@gmail.com'), isNotNull);
    });

    test('validateEmail accepts .edu email', () {
      expect(Validators.validateEmail('test@university.edu'), isNull);
    });

    test('validatePassword requires 6+ chars', () {
      expect(Validators.validatePassword('abc'), isNotNull);
      expect(Validators.validatePassword('abc123'), isNull);
    });

    test('validateBudget requires minimum \$5', () {
      expect(Validators.validateBudget('3'), isNotNull);
      expect(Validators.validateBudget('10'), isNull);
    });
  });

  group('Helpers', () {
    test('getInitials returns correct initials', () {
      expect(Helpers.getInitials('John Doe'), 'JD');
      expect(Helpers.getInitials('Alice'), 'A');
    });

    test('formatCurrency formats correctly', () {
      expect(Helpers.formatCurrency(10.5), '\$10.50');
    });
  });
}
