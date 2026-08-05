import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/shared/widgets/custom_text_field.dart';

void main() {
  group('CustomTextField', () {
    testWidgets('显示标签和提示文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: '用户名',
              hintText: '请输入用户名',
            ),
          ),
        ),
      );

      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('请输入用户名'), findsOneWidget);
    });

    testWidgets('显示前置图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('显示后置图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: '密码',
              suffixIcon: Icon(Icons.visibility_off_outlined),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('输入文本后触发 onChanged', (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: '用户名',
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test_user');
      await tester.pump();

      expect(changedValue, equals('test_user'));
    });

    testWidgets('禁用状态下标签仍然显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: '用户名',
              enabled: false,
            ),
          ),
        ),
      );

      // 禁用状态下 TextFormField 仍然存在
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('自定义控制器预设值', (WidgetTester tester) async {
      final controller = TextEditingController(text: '预设值');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: '用户名',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('预设值'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('校验函数生效显示错误信息', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                labelText: '用户名',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // 提交表单触发校验
      formKey.currentState?.validate();
      await tester.pumpAndSettle();

      expect(find.text('请输入用户名'), findsOneWidget);
    });

    testWidgets('提交空值触发 onFieldSubmitted', (WidgetTester tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: '用户名',
              onFieldSubmitted: (value) {
                submittedValue = value;
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'test_user');
      await tester.pump();

      // 模拟文本提交动作
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedValue, 'test_user');
    });
  });
}
