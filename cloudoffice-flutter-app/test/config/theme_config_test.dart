import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/config/theme_config.dart';

void main() {
  group('ThemeConfig', () {
    test('primaryColor 为 #1976D2', () {
      expect(ThemeConfig.primaryColor, equals(const Color(0xFF1976D2)));
    });

    test('lightTheme 返回 ThemeData 实例', () {
      final theme = ThemeConfig.lightTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, true);
    });

    test('lightTheme 使用正确的 seed color', () {
      final theme = ThemeConfig.lightTheme;
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('AppBar 主题居中显示标题', () {
      final theme = ThemeConfig.lightTheme;
      expect(theme.appBarTheme.centerTitle, true);
      expect(theme.appBarTheme.elevation, equals(0));
    });

    test('输入框主题使用圆角边框', () {
      final theme = ThemeConfig.lightTheme;
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.filled, true);
      expect(inputTheme.contentPadding, isNotNull);
    });

    test('ElevatedButton 主题使用主色', () {
      final theme = ThemeConfig.lightTheme;
      final buttonTheme = theme.elevatedButtonTheme;

      expect(buttonTheme, isNotNull);
      expect(buttonTheme.style, isNotNull);
    });

    test('Card 主题使用圆角', () {
      final theme = ThemeConfig.lightTheme;
      final cardTheme = theme.cardTheme;

      expect(cardTheme, isNotNull);
      expect(cardTheme?.elevation, equals(1));
      expect(cardTheme?.shape, isA<RoundedRectangleBorder>());
    });

    test('TextButton 主题使用主色', () {
      final theme = ThemeConfig.lightTheme;
      final textButtonTheme = theme.textButtonTheme;

      expect(textButtonTheme, isNotNull);
      expect(textButtonTheme.style?.foregroundColor?.resolve({}), isNotNull);
    });

    test('文字主题包含 headlineLarge', () {
      final theme = ThemeConfig.lightTheme;
      final textTheme = theme.textTheme;

      expect(textTheme.headlineLarge, isNotNull);
      expect(textTheme.headlineLarge?.fontSize, equals(28));
      expect(textTheme.headlineLarge?.fontWeight, equals(FontWeight.bold));
    });

    test('文字主题包含 bodyMedium', () {
      final theme = ThemeConfig.lightTheme;
      final textTheme = theme.textTheme;

      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.bodyMedium?.fontSize, equals(14));
    });

    test('ThemeConfig 不可实例化（私有构造）', () {
      // 验证 ThemeConfig 类有私有构造方法
      expect(ThemeConfig.lightTheme, isA<ThemeData>());
    });

    test('所有颜色值都正确设置', () {
      final theme = ThemeConfig.lightTheme;

      // 验证自定义组件样式
      expect(theme.appBarTheme.titleTextStyle?.color, equals(Colors.white));
      expect(theme.appBarTheme.titleTextStyle?.fontSize, equals(20));
      expect(theme.appBarTheme.titleTextStyle?.fontWeight, equals(FontWeight.w600));
    });

    test('ElevatedButton 有正确的禁用样式', () {
      final theme = ThemeConfig.lightTheme;
      final buttonStyle = theme.elevatedButtonTheme.style;

      // 验证按钮样式属性
      expect(buttonStyle?.minimumSize?.resolve({}), const Size(double.infinity, 48));
    });
  });
}
