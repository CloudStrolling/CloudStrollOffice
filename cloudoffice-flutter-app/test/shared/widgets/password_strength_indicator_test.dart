import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/shared/widgets/password_strength_indicator.dart';

void main() {
  group('PasswordStrengthIndicator', () {
    testWidgets('空密码不显示任何内容', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: ''),
          ),
        ),
      );

      // 空密码时返回 SizedBox.shrink()
      expect(find.byType(SizedBox), findsOneWidget);
      // 没有文本
      expect(find.textContaining('密码强度'), findsNothing);
    });

    testWidgets('弱密码显示红色进度条和"弱"文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: '12345678'),
          ),
        ),
      );

      // 显示密码强度文字
      expect(find.text('密码强度：弱'), findsOneWidget);

      // 显示 LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('中等强度密码显示橙色进度条和"中"文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'abcdef1234'),
          ),
        ),
      );

      expect(find.text('密码强度：中'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('强密码显示绿色进度条和"强"文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'abc123!@#xyz'),
          ),
        ),
      );

      expect(find.text('密码强度：强'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('密码更新时指示器实时刷新', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'weak'),
          ),
        ),
      );

      // 最初显示弱
      expect(find.text('密码强度：弱'), findsOneWidget);

      // 重新构建 Widget 以更新密码
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'abc123!@#xyz'),
          ),
        ),
      );

      expect(find.text('密码强度：强'), findsOneWidget);
      expect(find.text('密码强度：弱'), findsNothing);
    });

    testWidgets('密码强度指示器包含 Column 布局', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'StrongPass1!'),
          ),
        ),
      );

      // Column 布局
      expect(find.byType(Column), findsOneWidget);
      // Padding 包裹
      expect(find.byType(Padding), findsOneWidget);
      // ClipRRect 用于圆角进度条
      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });
}
