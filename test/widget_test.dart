import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_app/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WallpaperApp());

    // Verify that our main title is found.
    expect(find.text('Wallpaper Inc.'), findsOneWidget);
  });
}
