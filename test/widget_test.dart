import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/features/auth/ui/auth_form.dart';

void main() {
  test('email validation', () {
    expect(validateEmail('a@b.com'), isNull);
    expect(validateEmail('nope'), isNotNull);
  });

  test('password validation', () {
    expect(validatePassword('123456'), isNull);
    expect(validatePassword('123'), isNotNull);
  });
}
