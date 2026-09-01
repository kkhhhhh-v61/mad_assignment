import 'package:flutter_test/flutter_test.dart';

import 'package:mad_assignment/main.dart';

void main() {
  testWidgets('missing Supabase configuration is explained', (tester) async {
    await tester.pumpWidget(const MissingSupabaseConfigurationApp());

    expect(
      find.textContaining('Supabase configuration is missing'),
      findsOneWidget,
    );
  });
}
