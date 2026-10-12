import 'dart:async';
import 'dart:convert';
import 'package:efteqad/features/admin/presentation/widgets/assign_makhdomeen_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/auth_service.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import 'package:efteqad/core/services/visit_draft_store.dart';
import 'package:efteqad/features/tasks/presentation/widgets/add_task_dialog.dart';
import 'package:efteqad/features/common/widgets/record_visit_sheet.dart';
import 'package:efteqad/features/admin/presentation/widgets/add_edit_makhdom_dialog.dart';
import '../core/services/auth_lifecycle_test.dart'
    show AuthSdk, UserSdk, GoogleSdk, DeviceStore;

AuthService auth({AuthSdk? sdk}) => AuthService(
  auth: sdk ?? AuthSdk(),
  googleSignIn: GoogleSdk(),
  devices: DeviceRegistrationService(
    store: DeviceStore(),
    tokenGetter: () async => 't',
    tokenDeleter: () async {},
    tokenRefreshStream: const Stream.empty(),
  ),
  clearNotificationIntents: () {},
);

class OtherUserSdk extends UserSdk {
  @override
  String get uid => 'B';
}

class DraftReadGate extends VisitDraftStore {
  final result = Completer<List<Map<String, dynamic>>>();
  @override
  Future<List<Map<String, dynamic>>> getDrafts(String uid) => result.future;
}

Widget app(Widget Function(BuildContext) dialog) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog(context: context, builder: dialog),
        child: const Text('Open'),
      ),
    ),
  ),
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'delayed visit draft load cannot display A content to replacement B',
    (tester) async {
      final sdk = AuthSdk(), drafts = DraftReadGate();
      final sent = <Map<String, dynamic>>[];
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            sent.add(p);
            return {'visitId': 'saved'};
          },
        ),
      );
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Child',
        phone: '01000000000',
        grade: '1st',
        createdAt: DateTime(2026),
      );
      await tester.pumpWidget(
        app(
          (_) => Material(
            child: RecordVisitSheet(
              makhdom: child,
              firestoreService: service,
              authService: auth(sdk: sdk),
              draftStore: drafts,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      sdk.replacement = OtherUserSdk();
      drafts.result.complete([
        {
          'makhdomId': 'm',
          'operationId': 'prior',
          'notes': 'A private draft',
          'visitType': 'home',
          'visitDate': '2026-10-08',
        },
      ]);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty,
      );
      expect(sent, isEmpty);
    },
  );
  testWidgets(
    'assignment confirmation cannot transfer A intent to replacement account B',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var uid = 'A';
      final sent = <Map<String, dynamic>>[];
      final service = FirestoreService(
        mutations: TrustedMutations(
          userId: () => uid,
          transport: (name, p) async {
            sent.add(p);
            return {
              'assignedCount': 1,
              'results': [
                {'id': 'm', 'status': 'assigned'},
              ],
            };
          },
        ),
      );
      final servant = KhademModel(
        id: 's',
        name: 'New owner',
        email: '',
        phone: '',
        colorHex: '',
        role: 'servant',
        grade: '1st',
        status: 'active',
        createdAt: DateTime(2026),
      );
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Child',
        phone: '01000000000',
        grade: '1st',
        assignedKhademId: 'old',
        assignedKhademName: 'Old owner',
        createdAt: DateTime(2026),
      );
      await tester.pumpWidget(
        app(
          (_) => Material(
            child: AssignMakhdomeenModal(
              targetKhadem: servant,
              allMakhdomeen: [child],
              firestoreService: service,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      uid = 'B';
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      expect(find.byType(AssignMakhdomeenModal), findsOneWidget);
      uid = 'A';
      await tester.tap(find.byWidgetPredicate((w) => w is ElevatedButton));
      await tester.pumpAndSettle();
      expect(sent.single['expectedUid'], 'A');
      expect(find.byType(AssignMakhdomeenModal), findsNothing);
    },
  );
  testWidgets(
    'profile continuation remains owned by A after pending save and replacement login',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var uid = 'A';
      final response = Completer<Map<String, dynamic>>();
      final sent = <Map<String, dynamic>>[];
      final service = FirestoreService(
        mutations: TrustedMutations(
          userId: () => uid,
          transport: (name, p) async {
            sent.add(p);
            if (name == 'saveMakhdomProfile' && sent.length == 1) {
              return response.future;
            }
            return name == 'saveMakhdomProfile'
                ? {'makhdomId': 'created'}
                : {
                    'assignedCount': 1,
                    'results': [
                      {'id': 'created', 'status': 'assigned'},
                    ],
                  };
          },
        ),
      );
      final servant = KhademModel(
        id: 's',
        name: 'Servant',
        email: '',
        phone: '',
        colorHex: '',
        role: 'servant',
        grade: '1st',
        status: 'active',
        createdAt: DateTime(2026),
      );
      final child = MakhdomModel(
        id: '',
        fullName: 'Child',
        phone: '01000000000',
        grade: '1st',
        assignedKhademId: 's',
        assignedKhademName: 'Servant',
        createdAt: DateTime(2026),
      );
      await tester.pumpWidget(
        app(
          (_) => AddEditMakhdomDialog(
            initialMakhdom: child,
            khodamList: [servant],
            firestoreService: service,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(sent.single['expectedUid'], 'A');
      uid = 'B';
      response.complete({'makhdomId': 'created'});
      await tester.pumpAndSettle();
      expect(sent.length, 1);
      expect(find.byType(AddEditMakhdomDialog), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(sent.length, 1);
      uid = 'A';
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(sent.length, 3);
      expect(sent[1]['operationId'], sent.first['operationId']);
      expect(sent.last['expectedUid'], 'A');
      expect(find.byType(AddEditMakhdomDialog), findsNothing);
    },
  );
  testWidgets(
    'task dialog retries its actual callable with the same operation and waits for confirmation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final sent = <Map<String, dynamic>>[];
      bool fail = true;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (name, p) async {
            expect(name, 'createTask');
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'taskId': 'actual-task'};
          },
        ),
      );
      final khadem = KhademModel(
        id: 's',
        name: 'Servant',
        email: '',
        phone: '',
        colorHex: '',
        role: 'servant',
        grade: '1st',
        status: 'active',
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        app(
          (ctx) => AddTaskDialog(
            availableKhodam: [khadem],
            grade: '1st',
            firestoreService: service,
            authService: auth(),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'My task');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AddTaskDialog), findsOneWidget);
      expect(sent.length, 1);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        false,
      );
      fail = false;
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AddTaskDialog), findsNothing);
      expect(sent.last, sent.first);
      expect(sent.first['operationId'], isNotEmpty);
    },
  );
  testWidgets(
    'create profile dialog preserves selected grade and stable create intent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final sent = <Map<String, dynamic>>[];
      bool fail = true;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (name, p) async {
            expect(name, 'saveMakhdomProfile');
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'makhdomId': 'created'};
          },
        ),
      );
      final initial = MakhdomModel(
        id: '',
        fullName: 'Name',
        phone: '01000000000',
        grade: '3rd',
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        app(
          (ctx) => AddEditMakhdomDialog(
            initialMakhdom: initial,
            khodamList: const [],
            firestoreService: service,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditMakhdomDialog), findsOneWidget);
      expect((sent.first['patch'] as Map)['grade'], '3rd');
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        false,
      );
      fail = false;
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(sent.last, sent.first);
      expect(find.byType(AddEditMakhdomDialog), findsNothing);
    },
  );
  testWidgets(
    'assignment modal resumes two removals after the second loses its response',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final received = <Map<String, dynamic>>[],
          receipts = <String, Map<String, dynamic>>{},
          owners = {'a': 's', 'b': 's'};
      var lose = true;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (name, p) async {
            expect(name, 'assignMakhdoms');
            received.add(p);
            final op = p['operationId'] as String;
            if (receipts.containsKey(op)) return receipts[op]!;
            final id = (p['ids'] as List).single as String;
            if (owners[id] != (p['expectedAssignments'] as Map)[id]) {
              return {
                'assignedCount': 0,
                'results': [
                  {'id': id, 'status': 'conflict'},
                ],
              };
            }
            owners[id] = '';
            final result = {
              'assignedCount': 1,
              'results': [
                {'id': id, 'status': 'assigned'},
              ],
            };
            receipts[op] = result;
            if (id == 'b' && lose) {
              lose = false;
              throw StateError('response lost after commit');
            }
            return result;
          },
        ),
      );
      final servant = KhademModel(
        id: 's',
        name: 'Servant',
        email: '',
        phone: '',
        colorHex: '',
        role: 'servant',
        grade: '1st',
        status: 'active',
        createdAt: DateTime(2026),
      );
      final children = ['a', 'b']
          .map(
            (id) => MakhdomModel(
              id: id,
              fullName: 'Child $id',
              phone: '01000000000',
              grade: '1st',
              assignedKhademId: 's',
              createdAt: DateTime(2026),
            ),
          )
          .toList();
      await tester.pumpWidget(
        app(
          (ctx) => Material(
            child: AssignMakhdomeenModal(
              targetKhadem: servant,
              allMakhdomeen: children,
              firestoreService: service,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Child a'));
      await tester.tap(find.text('Child b'));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(AssignMakhdomeenModal), findsOneWidget);
      await tester.tap(find.text('Child a'));
      await tester.pumpAndSettle(); // uncertain selection must stay frozen
      await tester.tap(find.byWidgetPredicate((w) => w is ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(AssignMakhdomeenModal), findsNothing);
      expect(received.where((p) => (p['ids'] as List).single == 'a').length, 1);
      final b = received
          .where((p) => (p['ids'] as List).single == 'b')
          .toList();
      expect(b.length, 2);
      expect(b.last, b.first);
    },
  );
  testWidgets(
    'edit profile resumes lost reassignment without repeating confirmed profile progress',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final calls = <Map<String, dynamic>>[],
          receipts = <String, Map<String, dynamic>>{};
      var owner = 'old';
      var lose = true;
      var profileCalls = 0;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (name, p) async {
            if (name == 'saveMakhdomProfile') {
              profileCalls++;
              return {'makhdomId': 'm'};
            }
            expect(name, 'assignMakhdoms');
            calls.add(p);
            final op = p['operationId'] as String;
            if (receipts.containsKey(op)) return receipts[op]!;
            if ((p['expectedAssignments'] as Map)['m'] != owner) {
              return {
                'assignedCount': 0,
                'results': [
                  {'id': 'm', 'status': 'conflict'},
                ],
              };
            }
            owner = p['targetKhademId'] as String;
            final result = {
              'assignedCount': 1,
              'results': [
                {'id': 'm', 'status': 'assigned'},
              ],
            };
            receipts[op] = result;
            if (lose) {
              lose = false;
              throw StateError('response lost after commit');
            }
            return result;
          },
        ),
      );
      KhademModel khadem(String id, String name) => KhademModel(
        id: id,
        name: name,
        email: '',
        phone: '',
        colorHex: '',
        role: 'servant',
        grade: '1st',
        status: 'active',
        createdAt: DateTime(2026),
      );
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Child',
        phone: '01000000000',
        grade: '1st',
        assignedKhademId: 'old',
        assignedKhademName: 'Old owner',
        createdAt: DateTime(2026),
      );
      await tester.pumpWidget(
        app(
          (ctx) => AddEditMakhdomDialog(
            initialMakhdom: child,
            khodamList: [
              khadem('old', 'Old owner'),
              khadem('new', 'New owner'),
            ],
            firestoreService: service,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final dropdown = find
          .byWidgetPredicate((w) => w is DropdownButtonFormField<String>)
          .last;
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('New owner').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditMakhdomDialog), findsOneWidget);
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditMakhdomDialog), findsNothing);
      expect(profileCalls, 1);
      expect(calls.length, 2);
      expect(calls.last, calls.first);
    },
  );
  testWidgets(
    'reopened pending visit replays the persisted exact notes without trimming them',
    (tester) async {
      final payload = {
        'makhdomId': 'm',
        'visitDate': '2026-10-08T00:00:00.000',
        'visitType': 'home',
        'notes': ' original ',
        'operationId': 'prior',
      };
      SharedPreferences.setMockInitialValues({
        'visit_drafts_u': jsonEncode([
          {'id': 'm', ...payload, 'submittedPayload': payload},
        ]),
      });
      final sent = <Map<String, dynamic>>[];
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            sent.add(p);
            return {'visitId': 'confirmed'};
          },
        ),
      );
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Child',
        phone: '01000000000',
        grade: '1st',
        createdAt: DateTime(2026),
      );
      await tester.pumpWidget(
        app(
          (ctx) => Material(
            child: RecordVisitSheet(
              makhdom: child,
              firestoreService: service,
              authService: auth(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Visit'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordVisitSheet), findsNothing);
      expect(sent.single, {...payload, 'expectedUid': 'u'});
    },
  );
  testWidgets(
    'unreadable persisted draft blocks sending and reports the load failure',
    (tester) async {
      SharedPreferences.setMockInitialValues({'visit_drafts_u': 'broken-json'});
      var requests = 0;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (name, p) async {
            requests++;
            return {'visitId': 'v'};
          },
        ),
      );
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Student',
        phone: '01000000000',
        grade: '1st',
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        app(
          (ctx) => Material(
            child: RecordVisitSheet(
              makhdom: child,
              firestoreService: service,
              authService: auth(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Could not load data'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save Visit'),
      );
      expect(button.onPressed, isNull);
      expect(requests, 0);
    },
  );
  testWidgets(
    'visit sheet saves draft before sending, retains it on failure and reuses the operation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final drafts = VisitDraftStore(), sent = <Map<String, dynamic>>[];
      bool fail = true;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (name, p) async {
            expect(name, 'recordVisit');
            expect(
              (await drafts.getDrafts('u')).single['operationId'],
              p['operationId'],
            );
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'visitId': 'actual-visit'};
          },
        ),
      );
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Student',
        phone: '01000000000',
        grade: '1st',
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        app(
          (ctx) => Material(
            child: RecordVisitSheet(
              makhdom: child,
              firestoreService: service,
              authService: auth(),
              draftStore: drafts,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'User text');
      await tester.tap(find.text('Save Visit'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordVisitSheet), findsOneWidget);
      expect((await drafts.getDrafts('u')).single['notes'], 'User text');
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      fail = false;
      await tester.tap(find.text('Save Visit'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordVisitSheet), findsNothing);
      expect(sent.last, sent.first);
      expect(sent.first['visitType'], 'home');
      expect(await drafts.getDrafts('u'), isEmpty);
    },
  );
}
