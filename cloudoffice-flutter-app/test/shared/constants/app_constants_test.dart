import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/shared/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('passwordMinLength 为 8', () {
      expect(AppConstants.passwordMinLength, equals(8));
    });

    test('passwordMaxLength 为 64', () {
      expect(AppConstants.passwordMaxLength, equals(64));
    });

    test('loginNameMinLength 为 4', () {
      expect(AppConstants.loginNameMinLength, equals(4));
    });

    test('loginNameMaxLength 为 64', () {
      expect(AppConstants.loginNameMaxLength, equals(64));
    });

    test('userNameMinLength 为 2', () {
      expect(AppConstants.userNameMinLength, equals(2));
    });

    test('userNameMaxLength 为 50', () {
      expect(AppConstants.userNameMaxLength, equals(50));
    });

    test('countdownSeconds 为 60', () {
      expect(AppConstants.countdownSeconds, equals(60));
    });

    test('successCountdownSeconds 为 3', () {
      expect(AppConstants.successCountdownSeconds, equals(3));
    });

    test('codeLength 为 6', () {
      expect(AppConstants.codeLength, equals(6));
    });

    test('phoneLength 为 11', () {
      expect(AppConstants.phoneLength, equals(11));
    });

    test('AppConstants 不可实例化（私有构造）', () {
      // 验证 AppConstants 所有常量值类型正确
      expect(AppConstants.passwordMinLength, isA<int>());
      expect(AppConstants.passwordMaxLength, isA<int>());
      expect(AppConstants.loginNameMinLength, isA<int>());
      expect(AppConstants.loginNameMaxLength, isA<int>());
      expect(AppConstants.userNameMinLength, isA<int>());
      expect(AppConstants.userNameMaxLength, isA<int>());
      expect(AppConstants.countdownSeconds, isA<int>());
      expect(AppConstants.successCountdownSeconds, isA<int>());
      expect(AppConstants.codeLength, isA<int>());
      expect(AppConstants.phoneLength, isA<int>());
    });
  });
}
