import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/core/utils/validators.dart';
import 'package:cloudoffice_flutter_app/shared/constants/app_constants.dart';

void main() {
  group('Validators', () {
    // ========== validateLoginName ==========

    group('validateLoginName', () {
      test('值为 null 时应返回错误提示', () {
        expect(Validators.validateLoginName(null), equals('请输入用户名'));
      });

      test('值为空字符串时应返回错误提示', () {
        expect(Validators.validateLoginName(''), equals('请输入用户名'));
      });

      test('值为仅空格字符串时应返回错误提示', () {
        expect(Validators.validateLoginName('   '), equals('请输入用户名'));
      });

      test('长度小于最小值时应返回长度错误提示', () {
        final short = 'a' * (AppConstants.loginNameMinLength - 1);
        expect(
          Validators.validateLoginName(short),
          equals('用户名不能少于${AppConstants.loginNameMinLength}个字符'),
        );
      });

      test('长度大于最大值时应返回长度错误提示', () {
        final long = 'a' * (AppConstants.loginNameMaxLength + 1);
        expect(
          Validators.validateLoginName(long),
          equals('用户名不能超过${AppConstants.loginNameMaxLength}个字符'),
        );
      });

      test('包含非法字符时应返回格式错误提示', () {
        expect(
          Validators.validateLoginName('user name'),
          equals('用户名仅允许字母、数字和下划线'),
        );
      });

      test('包含中文时应返回格式错误提示', () {
        expect(
          Validators.validateLoginName('用户名1'),
          equals('用户名仅允许字母、数字和下划线'),
        );
      });

      test('有效用户名应返回 null', () {
        expect(Validators.validateLoginName('test_user_123'), isNull);
      });

      test('有效用户名含前后空格时应通过（自动 trim）', () {
        expect(Validators.validateLoginName('  valid_user  '), isNull);
      });
    });

    // ========== validatePassword ==========

    group('validatePassword', () {
      test('值为 null 时应返回错误提示', () {
        expect(Validators.validatePassword(null), equals('请输入密码'));
      });

      test('值为空字符串时应返回错误提示', () {
        expect(Validators.validatePassword(''), equals('请输入密码'));
      });

      test('长度小于最小值时应返回长度错误提示', () {
        expect(
          Validators.validatePassword('Ab1' * 2 + 'a'),
          equals('密码不能少于${AppConstants.passwordMinLength}位'),
        );
      });

      test('长度大于最大值时应返回长度错误提示', () {
        expect(
          Validators.validatePassword('A' * (AppConstants.passwordMaxLength + 1)),
          equals('密码不能超过${AppConstants.passwordMaxLength}位'),
        );
      });

      test('有效密码应返回 null', () {
        expect(Validators.validatePassword('Abc12345'), isNull);
      });
    });

    // ========== validateConfirmPassword ==========

    group('validateConfirmPassword', () {
      test('确认密码为 null 时应返回错误提示', () {
        expect(
          Validators.validateConfirmPassword('Abc12345', null),
          equals('请再次输入密码'),
        );
      });

      test('确认密码为空时应返回错误提示', () {
        expect(
          Validators.validateConfirmPassword('Abc12345', ''),
          equals('请再次输入密码'),
        );
      });

      test('两次密码不一致时应返回错误提示', () {
        expect(
          Validators.validateConfirmPassword('Abc12345', 'Different1'),
          equals('两次输入的密码不一致'),
        );
      });

      test('两次密码一致时应返回 null', () {
        expect(Validators.validateConfirmPassword('Abc12345', 'Abc12345'), isNull);
      });
    });

    // ========== validatePhone ==========

    group('validatePhone', () {
      test('值为 null 时应返回错误提示', () {
        expect(Validators.validatePhone(null), equals('请输入手机号'));
      });

      test('值为空字符串时应返回错误提示', () {
        expect(Validators.validatePhone(''), equals('请输入手机号'));
      });

      test('值为仅空格字符串时应返回错误提示', () {
        expect(Validators.validatePhone('   '), equals('请输入手机号'));
      });

      test('长度不足11位时应返回格式错误提示', () {
        expect(
          Validators.validatePhone('1380013800'),
          equals('请输入正确的手机号格式'),
        );
      });

      test('以 1 开头但第二位非法时应返回格式错误提示', () {
        // 1[0-2] 不属于 1[3-9]
        expect(Validators.validatePhone('12012345678'), equals('请输入正确的手机号格式'));
      });

      test('包含非数字字符时应返回格式错误提示', () {
        expect(
          Validators.validatePhone('1380013800a'),
          equals('请输入正确的手机号格式'),
        );
      });

      test('有效手机号应返回 null', () {
        expect(Validators.validatePhone('13800138000'), isNull);
      });

      test('有效手机号 159 开头应返回 null', () {
        expect(Validators.validatePhone('15912345678'), isNull);
      });
    });

    // ========== validateVerificationCode ==========

    group('validateVerificationCode', () {
      test('值为 null 时应返回错误提示', () {
        expect(Validators.validateVerificationCode(null), equals('请输入验证码'));
      });

      test('值为空字符串时应返回错误提示', () {
        expect(Validators.validateVerificationCode(''), equals('请输入验证码'));
      });

      test('值为仅空格时应返回错误提示', () {
        expect(Validators.validateVerificationCode('   '), equals('请输入验证码'));
      });

      test('少于6位时应返回格式错误提示', () {
        expect(
          Validators.validateVerificationCode('12345'),
          equals('验证码为6位数字'),
        );
      });

      test('多于6位时应返回格式错误提示', () {
        expect(
          Validators.validateVerificationCode('1234567'),
          equals('验证码为6位数字'),
        );
      });

      test('包含非数字字符时应返回格式错误提示', () {
        expect(
          Validators.validateVerificationCode('12345a'),
          equals('验证码为6位数字'),
        );
      });

      test('有效6位数字验证码应返回 null', () {
        expect(Validators.validateVerificationCode('123456'), isNull);
      });
    });

    // ========== validateUserName ==========

    group('validateUserName', () {
      test('值为 null 时应返回错误提示', () {
        expect(Validators.validateUserName(null), equals('请输入真实姓名'));
      });

      test('值为空字符串时应返回错误提示', () {
        expect(Validators.validateUserName(''), equals('请输入真实姓名'));
      });

      test('值为仅空格时应返回错误提示', () {
        expect(Validators.validateUserName('   '), equals('请输入真实姓名'));
      });

      test('长度小于最小值时应返回长度错误提示', () {
        expect(
          Validators.validateUserName('张'),
          equals('真实姓名不能少于${AppConstants.userNameMinLength}个字'),
        );
      });

      test('长度大于最大值时应返回长度错误提示', () {
        final long = '张' * (AppConstants.userNameMaxLength + 1);
        expect(
          Validators.validateUserName(long),
          equals('真实姓名不能超过${AppConstants.userNameMaxLength}个字'),
        );
      });

      test('有效真实姓名应返回 null', () {
        expect(Validators.validateUserName('张三'), isNull);
      });

      test('有效真实姓名含前后空格时应通过（自动 trim）', () {
        expect(Validators.validateUserName('  李四  '), isNull);
      });
    });

    // ========== validateEmail ==========

    group('validateEmail', () {
      test('值为 null 时应返回 null（非必填）', () {
        expect(Validators.validateEmail(null), isNull);
      });

      test('值为空字符串时应返回 null（非必填）', () {
        expect(Validators.validateEmail(''), isNull);
      });

      test('值为仅空格时应返回 null（非必填）', () {
        expect(Validators.validateEmail('   '), isNull);
      });

      test('缺少 @ 符号时应返回格式错误提示', () {
        expect(
          Validators.validateEmail('zhangsanexample.com'),
          equals('请输入正确的邮箱格式'),
        );
      });

      test('缺少域名时应返回格式错误提示', () {
        expect(
          Validators.validateEmail('zhangsan@.com'),
          equals('请输入正确的邮箱格式'),
        );
      });

      test('有效邮箱应返回 null', () {
        expect(Validators.validateEmail('zhangsan@example.com'), isNull);
      });

      test('有效邮箱含连字符应返回 null', () {
        expect(Validators.validateEmail('test-user@my-company.com.cn'), isNull);
      });

      test('有效邮箱含下划线应返回 null', () {
        expect(Validators.validateEmail('test_user@example.com'), isNull);
      });
    });

    // ========== calculatePasswordStrength ==========

    group('calculatePasswordStrength', () {
      test('空密码应返回 0（弱）', () {
        expect(Validators.calculatePasswordStrength(''), equals(0));
      });

      test('仅含字母的密码应返回 0（弱）', () {
        expect(Validators.calculatePasswordStrength('abcdefgh'), equals(0));
      });

      test('仅含数字的密码应返回 0（弱）', () {
        expect(Validators.calculatePasswordStrength('12345678'), equals(0));
      });

      test('字母+数字但不足10位应返回 0（弱）', () {
        expect(Validators.calculatePasswordStrength('abc12345'), equals(0));
      });

      test('字母+数字 10 位应返回 1（中）', () {
        expect(Validators.calculatePasswordStrength('abcdef1234'), equals(1));
      });

      test('字母+特殊字符 10 位应返回 1（中）', () {
        expect(Validators.calculatePasswordStrength('abcdef!@#('), equals(1));
      });

      test('数字+特殊字符 10 位应返回 1（中）', () {
        expect(Validators.calculatePasswordStrength('123456!@#('), equals(1));
      });

      test('字母+数字+特殊字符 12 位应返回 2（强）', () {
        expect(Validators.calculatePasswordStrength('abc123!@#xyz'), equals(2));
      });

      test('字母+数字+特殊字符超过12位应返回 2（强）', () {
        expect(Validators.calculatePasswordStrength('Abc12345!@#xyz'), equals(2));
      });

      test('字母+数字但不足 10 位不应返回 1（中）', () {
        expect(Validators.calculatePasswordStrength('abc12345'), equals(0));
      });

      test('仅特殊字符应返回 0（弱）', () {
        expect(Validators.calculatePasswordStrength(r'!@#$%^&*('), equals(0));
      });
    });

    // ========== getPasswordStrengthLabel ==========

    group('getPasswordStrengthLabel', () {
      test('等级 0 应返回"弱"', () {
        expect(Validators.getPasswordStrengthLabel(0), equals('弱'));
      });

      test('等级 1 应返回"中"', () {
        expect(Validators.getPasswordStrengthLabel(1), equals('中'));
      });

      test('等级 2 应返回"强"', () {
        expect(Validators.getPasswordStrengthLabel(2), equals('强'));
      });

      test('未知等级应返回空字符串', () {
        expect(Validators.getPasswordStrengthLabel(-1), equals(''));
      });

      test('超出范围等级应返回空字符串', () {
        expect(Validators.getPasswordStrengthLabel(99), equals(''));
      });
    });
  });
}
