import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/shared/widgets/loading_button.dart';

void main() {
  group('LoadingButton', () {
    testWidgets('显示文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(text: '登 录'),
          ),
        ),
      );

      expect(find.text('登 录'), findsOneWidget);
    });

    testWidgets('加载中显示 CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              text: '登 录',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // 文本不应该显示
      expect(find.text('登 录'), findsNothing);
    });

    testWidgets('加载中按钮不可点击', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              text: '登 录',
              isLoading: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // 找到 ElevatedButton 并点击
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, false);
    });

    testWidgets('加载完成可点击', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              text: '登 录',
              isLoading: false,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('禁用状态下按钮不可点击', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              text: '登 录',
              disabled: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, false);
    });

    testWidgets('主按钮样式为实心填充', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              text: '登 录',
              type: ButtonType.primary,
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('登 录'), findsOneWidget);
    });

    testWidgets('文字按钮渲染正确', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              text: '取消',
              type: ButtonType.text,
            ),
          ),
        ),
      );

      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('SizedBox 设置正确的宽高', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(text: '登 录'),
          ),
        ),
      );

      // 验证 SizedBox 宽度和高度约束
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, double.infinity);
      expect(sizedBox.height, 48);
    });
  });
}
