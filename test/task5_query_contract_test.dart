import 'package:efteqad/core/repositories/notification_repository.dart';
import 'dart:async';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: subtype_of_sealed_class, must_be_immutable
class QueryProbe
    implements
        FirebaseFirestore,
        Query<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>> {
  final calls = <String>[];
  final dateBounds = <Symbol, Object?>{};
  final Stream<QuerySnapshot<Map<String, dynamic>>> events;
  Future<QuerySnapshot<Map<String, dynamic>>> Function(String)? read;
  WriteBatch Function()? batchFactory;
  String _child = '';
  QueryProbe(this.events);
  @override
  dynamic noSuchMethod(Invocation i) {
    final name = i.memberName.toString();
    calls.add('$name ${i.positionalArguments} ${i.namedArguments}');
    if (name.contains('where') && i.positionalArguments.first == 'date') {
      dateBounds.addAll(
        Map.fromEntries(i.namedArguments.entries.where((e) => e.value != null)),
      );
    }
    if (name.contains('where') && i.positionalArguments.first == 'makhdomId') {
      _child = i.namedArguments[#isEqualTo] as String;
    }
    if (name == 'Symbol("get")') return read!(_child);
    if (name == 'Symbol("batch")') return batchFactory!();
    if (name.contains('snapshots')) return events;
    return this;
  }
}

class Meta implements SnapshotMetadata {
  @override
  final bool isFromCache;
  @override
  final bool hasPendingWrites;
  const Meta(this.isFromCache, this.hasPendingWrites);
}

class QueryEvent implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final SnapshotMetadata metadata;
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  QueryEvent(this.metadata, {this.docs = const []});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class Ref implements DocumentReference<Map<String, dynamic>> {
  @override
  final String id;
  Ref(this.id);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ignore: subtype_of_sealed_class
class ReadDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  ReadDoc(this.id);
  @override
  DocumentReference<Map<String, dynamic>> get reference => Ref(id);
  @override
  Map<String, dynamic> data() => {'recipientId': 's', 'isRead': false};
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class Batch implements WriteBatch {
  final Future<void> Function(List<String>) commitUpdates;
  final ids = <String>[];
  Batch(this.commitUpdates);
  @override
  WriteBatch update(DocumentReference document, Map<String, dynamic> data) {
    ids.add(document.id);
    return this;
  }

  @override
  Future<void> commit() => commitUpdates(ids);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('mark all read resumes remaining unread chunks after failure', () async {
    final unread = {for (var i = 0; i < 250; i++) '$i'};
    final chunks = <int>[];
    var commits = 0;
    final probe = QueryProbe(const Stream.empty())
      ..read = ((_) async => QueryEvent(
        const Meta(false, false),
        docs: unread.take(200).map(ReadDoc.new).toList(),
      ))
      ..batchFactory = () => Batch((ids) async {
        chunks.add(ids.length);
        if (++commits == 2) {
          throw FirebaseException(plugin: 'firestore', code: 'unavailable');
        }
        unread.removeAll(ids);
      });
    final repository = FirestoreNotificationRepository(firestore: probe);
    await expectLater(
      repository.markAllNotificationsAsRead('s'),
      throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'network-error')),
    );
    expect(unread.length, 50);
    await repository.markAllNotificationsAsRead('s');
    expect(unread, isEmpty);
    expect(chunks, [200, 50, 50]);
    expect(probe.calls.join(), contains('isRead'));
    expect(probe.calls.join(), contains('limit'));
  });
  test(
    'assigned child analysis cancels future batches with at most four in flight',
    () async {
      final gates = <Completer<QuerySnapshot<Map<String, dynamic>>>>[];
      final probe = QueryProbe(const Stream.empty())
        ..read = (id) {
          final gate = Completer<QuerySnapshot<Map<String, dynamic>>>();
          gates.add(gate);
          return gate.future;
        };
      final subscription = FirestoreService(firestore: probe)
          .watchVisitsForChildrenWindow(
            ['a', 'b', 'c', 'd', 'e', 'f'],
            from: DateTime(2026, 7, 19),
            to: DateTime(2026, 10, 16),
          )
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(gates.length, 4);
      await subscription.cancel();
      for (final gate in gates) {
        gate.complete(QueryEvent(const Meta(false, false)));
      }
      await Future<void>.delayed(Duration.zero);
      expect(gates.length, 4);
      expect(probe.calls.join(), contains('visitDate'));
      expect(probe.calls.join(), contains('createdAt'));
    },
  );
  test(
    'one assigned child permission failure rejects combined analysis',
    () async {
      final probe = QueryProbe(const Stream.empty())
        ..read = (id) async {
          if (id == 'c') {
            throw FirebaseException(
              plugin: 'firestore',
              code: 'permission-denied',
            );
          }
          return QueryEvent(const Meta(false, false));
        };
      await expectLater(
        FirestoreService(
          firestore: probe,
        ).watchVisitsForChildrenWindow(['a', 'b', 'c']).first,
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'permission-denied'),
        ),
      );
    },
  );
  test(
    'trusted profile serialization preserves user custom label and migration estimate',
    () {
      final m = MakhdomModel.fromMap({
        'secondaryType': 'other',
        'secondaryTypeCustomLabel': 'My school',
        'trackingStartDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'trackingStartEstimated': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      }, 'm');
      final profile = TrustedMutations.profileFields(m);
      expect(profile['secondaryTypeCustomLabel'], 'My school');
      expect(profile.containsKey('trackingStartDate'), isFalse);
    },
  );
  test(
    'grade analytics requests server range and SDK metadata changes',
    () async {
      final probe = QueryProbe(
        Stream.value(QueryEvent(const Meta(true, false))),
      );
      final repository = FirestoreAttendanceRepository(firestore: probe);
      final dynamic emitted = await repository
          .watchGradeAttendance(
            grade: '2nd',
            from: DateTime(2026, 7, 18),
            to: DateTime(2026, 10, 16),
          )
          .first;
      expect(probe.calls.join('\n'), contains('collectionGroup'));
      expect(probe.calls.join('\n'), contains('2nd'));
      expect(
        probe.dateBounds[#isGreaterThanOrEqualTo],
        Timestamp.fromDate(DateTime.utc(2026, 7, 18)),
      );
      expect(
        probe.dateBounds[#isLessThan],
        Timestamp.fromDate(DateTime.utc(2026, 10, 17)),
      );
      expect(probe.dateBounds.containsKey(#isLessThanOrEqualTo), isFalse);
      expect(
        probe.calls.join('\n'),
        contains('Symbol("includeMetadataChanges"): true'),
      );
      expect(emitted.isFromCache, isTrue);
    },
  );
  test('stage attendance uses Timestamp calendar-day bounds', () async {
    final probe = QueryProbe(
      Stream.value(QueryEvent(const Meta(false, false))),
    );
    await FirestoreService(firestore: probe)
        .watchAttendanceWindow(
          from: DateTime(2026, 10, 29, 18),
          to: DateTime(2026, 10, 30, 18),
        )
        .first;
    expect(
      probe.dateBounds[#isGreaterThanOrEqualTo],
      Timestamp.fromDate(DateTime.utc(2026, 10, 29)),
    );
    expect(
      probe.dateBounds[#isLessThan],
      Timestamp.fromDate(DateTime.utc(2026, 10, 31)),
    );
  });
  test('materialized estimated tracking marker survives copy and map', () {
    final m = MakhdomModel.fromMap({
      'trackingStartDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'trackingStartEstimated': true,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    }, 'm');
    expect(
      MakhdomModel.fromMap(
        m.copyWith(fullName: 'updated').toMap(),
        'm',
      ).isTrackingEstimated,
      isTrue,
    );
    expect(
      m.copyWith(trackingStartDate: DateTime(2026, 2, 1)).isTrackingEstimated,
      isFalse,
    );
    expect(
      m.copyWith(clearTrackingStartDate: true).isTrackingEstimated,
      isTrue,
    );
  });
}
