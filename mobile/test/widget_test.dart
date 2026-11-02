import 'package:flutter_test/flutter_test.dart';
import 'package:rivalrooms_latest/main.dart';

void main() {
  testWidgets('launch screen shows RivalRooms identity', (tester) async {
    await tester.pumpWidget(const RivalRoomsApp());
    expect(find.text('RIVALROOMS'), findsOneWidget);
    expect(find.text('Play together. Anywhere.'), findsOneWidget);
  });
}
