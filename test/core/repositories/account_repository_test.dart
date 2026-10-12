import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/repositories/account_repository.dart';

class MockAccountRepository implements AccountRepository {
  bool reauthCalled = false;
  bool reauthShouldFail = false;
  bool deletionRequested = false;
  String? lastOperationId;

  String? lastPassword;

  @override
  Future<void> reauthenticate({String? password}) async {
    reauthCalled = true;
    lastPassword = password;
    if (reauthShouldFail) {
      throw StateError('User cancelled re-authentication.');
    }
  }

  @override
  Future<String> requestDeletion({
    required String operationId,
    required String expectedUid,
  }) async {
    if (!reauthCalled || reauthShouldFail) {
      throw StateError(
        'Cannot request deletion without successful reauthentication.',
      );
    }
    deletionRequested = true;
    lastOperationId = operationId;
    return 'del_success';
  }
}

void main() {
  group('Account Deletion & Reauthentication Flow Tests', () {
    test(
      'rejected or cancelled reauthentication aborts deletion without touching data',
      () async {
        final mockRepo = MockAccountRepository();
        mockRepo.reauthShouldFail = true;

        expect(() async {
          await mockRepo.reauthenticate();
          await mockRepo.requestDeletion(operationId: 'op_1', expectedUid: 'u');
        }, throwsA(isA<StateError>()));

        expect(mockRepo.reauthCalled, isTrue);
        expect(mockRepo.deletionRequested, isFalse);
      },
    );

    test(
      'successful reauthentication allows deletion request with operationId',
      () async {
        final mockRepo = MockAccountRepository();
        mockRepo.reauthShouldFail = false;

        await mockRepo.reauthenticate();
        final result = await mockRepo.requestDeletion(
          operationId: 'op_123',
          expectedUid: 'u',
        );

        expect(mockRepo.reauthCalled, isTrue);
        expect(mockRepo.deletionRequested, isTrue);
        expect(mockRepo.lastOperationId, 'op_123');
        expect(result, 'del_success');
      },
    );

    test('reauthenticate with password records supplied password', () async {
      final mockRepo = MockAccountRepository();
      await mockRepo.reauthenticate(password: 'securePass123');
      expect(mockRepo.reauthCalled, isTrue);
      expect(mockRepo.lastPassword, 'securePass123');
    });
  });
}
