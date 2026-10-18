// Mini-Jira uygulaması için temel widget (smoke) testi.

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_jira_app/main.dart';

void main() {
  testWidgets('Uygulama açılışta giriş ekranını gösterir',
      (WidgetTester tester) async {
    // Uygulamayı inşa et ve bir kare çiz.
    await tester.pumpWidget(const MyApp());

    // Giriş ekranına ait başlık ve kart metinleri görünmeli.
    expect(find.text('Mini-Jira Workspace'), findsOneWidget);
    expect(find.text('Hesabınıza Giriş Yapın'), findsOneWidget);
  });
}
