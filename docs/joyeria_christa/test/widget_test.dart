import 'package:flutter_test/flutter_test.dart';
import 'package:joyeria_christa/main.dart';

void main() {
  testWidgets('Carga de pantalla principal', (WidgetTester tester) async {
    // Carga el widget principal
    await tester.pumpWidget(const MyApp());

    // Busca texto visible
    expect(find.text('Joyería Christa'), findsOneWidget);
  });
}
