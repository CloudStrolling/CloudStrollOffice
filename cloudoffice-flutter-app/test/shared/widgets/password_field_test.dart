import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/shared/widgets/password_field.dart';

void main() {
  group('PasswordField', () {
    testWidgets('显示标签和提示文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(
              labelText: '密码',
              hintText: '请输入密码',
            ),
          ),
        ),
      );

      expect(find.text('密码'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('显示锁图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('初始显示可见性关闭图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(),
          ),
        ),
      );

      // 初始显示 visibility_off 图标
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('点击可见性图标切换为显示图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(),
          ),
        ),
      );

      // 点击可见性切换按钮
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // 图标变为 visibility
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('再次点击可见性图标恢复为关闭图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(),
          ),
        ),
      );

      // 第一次点击：显示
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // 第二次点击：隐藏
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('输入文本触发 onChanged', (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordField(
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'my_password');
      await tester.pump();

      expect(changedValue, equals('my_password'));
    });

    testWidgets('未指定标签时使用默认文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(),
          ),
        ),
      );

      // 默认标签为 '密码'
      expect(find.text('密码'), findsOneWidget);
    });

    testWidgets('未指定提示文本时使用默认文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(),
          ),
        ),
      );

      // 默认提示文本为 '请输入密码'
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('密码输入框渲染正常', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordField(),
          ),
        ),
      );

      // TextFormField 渲染正常
      expect(find.byType(TextFormField), findsOneWidget);
      // IconButton 存在
      expect(find.byType(IconButton), findsOneWidget);
    });
  });
}
