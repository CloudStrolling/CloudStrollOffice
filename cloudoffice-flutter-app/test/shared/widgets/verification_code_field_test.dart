import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/shared/widgets/verification_code_field.dart';

void main() {
  group('VerificationCodeField', () {
    testWidgets('显示手机号和验证码输入框', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
            ),
          ),
        ),
      );

      // 两个 TextFormField
      expect(find.byType(TextFormField), findsNWidgets(2));

      // 标签文字
      expect(find.text('手机号'), findsOneWidget);
      expect(find.text('验证码'), findsOneWidget);

      phoneController.dispose();
      codeController.dispose();
    });

    testWidgets('显示获取验证码按钮', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
            ),
          ),
        ),
      );

      expect(find.text('获取验证码'), findsOneWidget);

      phoneController.dispose();
      codeController.dispose();
    });

    testWidgets('倒计时中显示倒计时文本', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
              isCountingDown: true,
              countdownSeconds: 58,
            ),
          ),
        ),
      );

      expect(find.text('58s后重新获取'), findsOneWidget);
      expect(find.text('获取验证码'), findsNothing);

      phoneController.dispose();
      codeController.dispose();
    });

    testWidgets('发送验证码按钮点击触发 onSendCode', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();
      bool sendCodeTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
              onSendCode: () {
                sendCodeTriggered = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('获取验证码'));
      await tester.pump();

      expect(sendCodeTriggered, true);

      phoneController.dispose();
      codeController.dispose();
    });

    testWidgets('倒计时中发送按钮禁用', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();
      bool sendCodeTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
              isCountingDown: true,
              countdownSeconds: 55,
              onSendCode: () {
                sendCodeTriggered = true;
              },
            ),
          ),
        ),
      );

      // 倒计时中的按钮为禁用状态
      final textButton = tester.widget<TextButton>(
        find.byType(TextButton),
      );
      expect(textButton.onPressed, isNull);

      expect(sendCodeTriggered, false);

      phoneController.dispose();
      codeController.dispose();
    });

    testWidgets('手机号输入框显示图标', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.phone_android_outlined), findsOneWidget);
      expect(find.byIcon(Icons.sms_outlined), findsOneWidget);

      phoneController.dispose();
      codeController.dispose();
    });

    testWidgets('校验函数传递给 TextFormField', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
              phoneValidator: (value) => '手机号格式错误',
              codeValidator: (value) => '验证码格式错误',
            ),
          ),
        ),
      );

      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(textFields[0].validator, isNotNull);
      expect(textFields[1].validator, isNotNull);

      phoneController.dispose();
      codeController.dispose();
    });

    testWidgets('完整输入流程验证', (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final codeController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              phoneController: phoneController,
              codeController: codeController,
            ),
          ),
        ),
      );

      // 输入手机号
      await tester.enterText(find.byType(TextFormField).first, '13800138000');
      await tester.pump();

      expect(phoneController.text, '13800138000');

      phoneController.dispose();
      codeController.dispose();
    });
  });
}
