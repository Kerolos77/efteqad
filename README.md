# Efteqad — الراعي الصالح

Flutter application for secondary-stage pastoral care: child profiles, assignments, visits, service/mass attendance, tasks and localized notifications. Features remain under `lib/features`; shared repositories, session, routing, settings and localization live under `lib/core`.

## Roles and session

| Trusted profile | Scope |
| --- | --- |
| `stageAdmin`, active | All three grades; approvals and grade administrators |
| `gradeAdmin`, active | Own grade's children, assignments, tasks and attendance |
| `servant`, active | Assigned children in own grade; assigned attendance task and minimal roster |
| `pending` | Waiting/profile/preferences; no business mutations |
| `deleting` | Restricted deletion progress and device cleanup |

Auth establishes identity; live `khodam/{uid}` establishes role/status/grade. `SessionCubit` drives one GoRouter with identity/scope-specific branches. Resource ID routes require fresh authorized data; notification navigation follows the same gate. Logout/device cleanup errors are visible and retryable. Auth email constants never grant privileges.

Business writes use trusted Cloud Functions, including profile/visit/import/assignment/attendance/task and deletion operations. **A new client needs those backend callables deployed together in a compatible environment before it can save.** This checkout does not prove they are deployed. Direct business writes are denied by Rules.

## Development and checks

Use the repository's Flutter SDK constraints and **Node 22**. Package and lockfile declare the same runtime; existing CommonJS and Firebase SDK versions are retained. Firebase lists Node 22 in [supported Functions runtimes](https://firebase.google.com/docs/functions/manage-functions#set_nodejs_version). The CLI still warns that firebase-functions is outdated; that notice is not a verified reason to upgrade every dependency.

```text
flutter pub get
npm --prefix functions ci
flutter gen-l10n
dart run tool/audit_localization.dart
flutter analyze --no-pub
flutter test --no-pub
firebase emulators:exec --only auth,firestore,functions --project demo-efteqad-rules --config firebase.json "npm --prefix functions test"
```

The full backend command needs Java; on this Windows host, set process-local `JAVA_HOME` to `C:/Program Files/Android/Android Studio/jbr` and prepend its `bin` to `PATH`. Tests invoke real Admin transactions, Rules clients, Auth emulator and callable HTTP transport. The test script serializes files to protect shared demo fixtures from Rules cleanup. Google identity and FCM delivery remain fenced/injected. Pub/Sub is absent from this command, so scheduled workers are tested through their business functions, not actual timer dispatch.

For local development run `firebase emulators:start --only auth,firestore,functions --project demo-efteqad-rules`. Backend tests receive emulator hosts from `emulators:exec`. **Normal `flutter run` initializes the registered Firebase configuration; it is not an emulator mode.** The dedicated `integration_test/app_flows_test.dart` requires both `--dart-define=DEMO_EMULATORS=true` and `--dart-define=FIREBASE_PROJECT_ID=demo-efteqad-rules` before any Firebase initialization; it configures Auth/Firestore/Functions on localhost and fences Google/FCM. Android emulator uses `--dart-define=EMULATOR_HOST=10.0.2.2`. Start the demo emulators first, then run `flutter test integration_test/app_flows_test.dart -d YOUR_DEVICE` with those defines. Browser acceptance uses `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_flows_test.dart -d web-server --headless` with the same defines and an available compatible WebDriver on port4444. Never use real credentials/accounts to substitute for a demo test.

Arabic and English come from ARB catalogs and generated `GeneratedAppLocalizations`; use `context.tr` and `DomainLabels`. User notes/custom labels remain user text. Localization audit checks generated references, placeholders and legacy UI literals. Settings persist before the first application frame.

## Data, queries and retries

Canonical attendance IDs are `YYYY-MM-DD_type_scope`, with types `khedma`/`qoddas`, scope `1st`/`2nd`/`3rd`/`all`, and actual-grade parts under `attendance/{sessionId}/grades/{grade}`. Only mass can span `all`; there is no `grades/all` document. Root/part dates use Firestore **Timestamp**, matching the backend. Grade/stage range readers use Timestamp calendar-day lower bounds and exclusive next-day upper bounds; the model reads the trusted UTC session-day key. Real callable finalization followed by a Rules-authorized Cairo-day range query is covered locally. Legacy string dates remain readable in unbounded/model reads but require the reviewed migration before canonical Timestamp range queries can include them. Coordinate backend/readers/migration rollout. Stage analytics uses grade parts; a partially finalized root does not finalize another grade.

An active own-grade administrator can reopen a finalized own-grade session from its completed attendance task. Only a stage administrator can reopen an `all` mass session. A required reason and stable operation ID produce one immutable audit containing the actor, server time and prior root/parts/task finalization. Reopen atomically moves the stored scope and linked task to draft/active while retaining presence; draft sessions leave analytics until finalized again. Cancelled tasks and inconsistent links/parts are rejected.

Analysis defaults to 90 inclusive local dates, has explicit custom/all-time scopes, and excludes draft/unknown/future attendance or unknown tracking origins. Service and mass metrics are separate; no eligible history is insufficient, not zero attendance. Visits use visitDate/createdAt/document ID descending; timeline and inbox use 50-row cursors. Servant comparison makes one authorized query per assigned child, at most four concurrently. Analysis reads the selected window separately from paged display.

Retry keeps the original operation/import/visit intent IDs and payload. Confirmed chunks/receipts are not repeated; assignment conflicts must be inspected. Changed intent needs a new operation ID after resolving the old one. Attendance saves wait for server confirmation; errors must not appear as successful empty data. Cached/pending snapshots say they await server confirmation.

Firestore's 100 MB cache bounds storage use. It does not guarantee shared-phone privacy. Auth/scope changes dispose protected listeners and UI state; offline cached reads cannot establish current access. Trusted mutations need connectivity/server confirmation; persisted visit/import intents support retry, not unrestricted offline writes.

## Migration and local recovery

The CLI defaults to dry-run and requires `--project`. For a local demo emulator, set `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` and use only `demo-efteqad-rules`:

```text
node functions/scripts/migrate_v2.js --project=demo-efteqad-rules --backup=migration-private/fixture_backup.json
node functions/scripts/migrate_v2.js --project=demo-efteqad-rules --report=migration-private/migration_report.json
node functions/scripts/migrate_v2.js --project=demo-efteqad-rules --apply --checkpoint=migration-private/migration_checkpoint.json --report=migration-private/migration_report.json
node functions/scripts/migrate_v2.js --project=demo-efteqad-rules --apply --resume --checkpoint=migration-private/migration_checkpoint.json --report=migration-private/migration_report.json
node functions/scripts/migrate_v2.js --project=demo-efteqad-rules --apply --restore=migration-private/fixture_backup.json
```

Backup/restore commands are **local demo fixture tools**, covering all root/nested records and supported Firestore value types. Restore replaces that demo database. Private backups may contain names, tokens and notes: store them outside version control; reports/checkpoints contain IDs/reasons, no such values. Production backup/restore requires the managed procedure in the release checklist; these examples must never be run against production.

Apply executes bounded per-record transactions. Atomic local checkpoints record plan version, project, fingerprint, cursor and completed unit paths. Server `migration_v2_receipts` hold source version/fingerprint and committed outcomes in the same transaction as patches. Resume scans and validates server receipts, including commits whose checkpoint was lost, so a checkpoint alone never authorizes skipping or repeating writes. Repeat/resume preserves later business edits; removing receipts to force a rerun is unsafe. Unknown history needs explicit correction/new approved migration, not a forced overwrite. Record limits of 1,000 dependent visits/assignments require manual review rather than partial counter repairs.

Known exact visit/secondary aliases normalize; unknown labels/notes remain preserved. Tracking falls back only to trusted createdAt and sets `trackingStartEstimated=true`; missing/untrusted createdAt sets `createdAtKnown=false` without inventing a date. Historical attendance requires explicit grade, scoped ID or explicit historical roster/year snapshot, never today's child grade. Missing status remains `legacyUnknown`; conflicting canonical targets are reported and retained.

Bootstrap requires an explicit project/real existing Auth UID and existing eligible profile. It defaults to dry-run; it does not create an Auth account:

```text
node functions/scripts/bootstrap_admin.js --project=YOUR_APPROVED_STAGING_PROJECT --uid=EXISTING_AUTH_UID --dry-run
```

Granting the initial administrator in staging/production is an authorized operator action, separately reviewed before `--apply`.

## Release and platform limits

Android preserves `com.example.efteqad` and Firebase registration. Debug uses its normal debug signing. Release requires local ignored `android/key.properties` and a real keystore; missing credentials fail explicitly, with no debug fallback. A valid file must contain nonempty `keyAlias`, `keyPassword`, `storePassword`, `storeFile`; `storeFile` resolves from `android/`. Register real certificate fingerprints before Google Sign-In device acceptance.

iOS URL scheme is copied from the existing public `GoogleService-Info.plist` REVERSED_CLIENT_ID; existing Arabic/English location explanations remain. Xcode signing, APNs credentials/capabilities, physical Google Sign-In/FCM and deep links require an Apple environment. No team/domain/credential was invented. Web/Windows/macOS configuration exists; build success alone does not validate exports, file sharing, notifications or browser authorization domains. Linux Firebase configuration is absent and unsupported.

Local emulator performance evidence (Task 5): 130 visit fixtures yielded 110 bounded records, pages 50/50/10, about 989 ms; 124 attendance-part fixtures yielded 12 own/24 stage records, about 449 ms. These are local documents returned, not billed reads, deployed-index acceptance or first-screen latency. Staging metrics, two-device contention/offline recovery and physical delivery remain release gates. Follow [release checklist](docs/release-checklist.md).
