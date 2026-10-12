import 'package:flutter_test/flutter_test.dart';
import '../integration_test/demo_environment.dart';

void main() {
  test(
    'integration bootstrap rejects missing explicit demo opt-in before Firebase initialization',
    () async {
      await expectLater(
        DemoEnvironment.initialize(),
        throwsA(isA<StateError>()),
      );
    },
  );
}
