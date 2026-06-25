import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/app.dart';

void main() {
  testWidgets('CloudStrollOfficeApp can be instantiated',
      (WidgetTester tester) async {
    // 验证 CloudStrollOfficeApp 可以正常创建且不抛出异常
    await tester.pumpWidget(const CloudStrollOfficeApp());
    expect(find.byType(CloudStrollOfficeApp), findsOneWidget);
  });
}
