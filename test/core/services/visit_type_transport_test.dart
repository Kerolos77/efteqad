import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';

void main() {
  test(
    'decorated legacy visit labels map to canonical codes while custom user text survives',
    () {
      const fixtures = {
        '🏠 زيارة منزلية': 'home',
        '📞 مكالمة تليفونية': 'phone',
        '⛪ لقاء في الكنيسة': 'church',
        '💬 رسالة / أخرى': 'other',
        '🏠 Home Visit': 'home',
        '📞 Phone Call': 'phone',
        '⛪ Church Meeting': 'church',
        '💬 Message / Other': 'other',
        'custom user text': 'custom user text',
      };
      for (final entry in fixtures.entries) {
        expect(canonicalVisitType(entry.key), entry.value);
      }
    },
  );
}
