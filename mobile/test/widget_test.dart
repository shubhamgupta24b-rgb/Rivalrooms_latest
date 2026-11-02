import 'package:flutter_test/flutter_test.dart';
import 'package:rivalrooms_latest/main.dart';

void main() {
  testWidgets('launch screen shows RivalRooms home and first playable game', (tester) async {
    await tester.pumpWidget(const RivalRoomsApp());
    expect(find.text('RIVALROOMS'), findsOneWidget);
    expect(find.text('YOUR NEXT MATCH STARTS HERE'), findsOneWidget);
    expect(find.text('Tic Tac Toe'), findsOneWidget);
    expect(find.text('CREATE OR JOIN ONLINE ROOM'), findsOneWidget);
  });
}
