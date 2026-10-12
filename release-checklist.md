# Release checklist — Efteqad

This is an operator procedure, not evidence of a completed deployment. No production migration, backup, account grant, deployment, signing-key creation or physical-device acceptance was executed for Task 6.

## Compatible rollout

- [ ] Select explicit staging/production projects and registered application IDs. Record deployed backend/client/Rules revisions and obtain deployment/migration authorization.
- [x] Local Timestamp attendance reader/decoder integration repaired and covered by real callable-created finalized data followed by a Rules-authorized Cairo-day query (Task 7). Repeat against deployed staging indexes/readers after migrating legacy string dates; this local result is not staging rollout acceptance.
- [ ] Ship compatible backend and readers in staging first. Current clients depend on the trusted callables; deploying Rules alone can break old clients. Keep restrictive authorization throughout; never introduce an allow-all window.
- [ ] Build required indexes and await readiness. Test real grade/assignment/date/cursor query shapes and denied cross-scope reads against deployed indexes/Rules.
- [ ] Arrange a write freeze during the migration window. Document app/backend version compatibility and stop unsupported old clients before coordinated final Rules tightening.
- [ ] Complete backup, restore rehearsal, dry-run review, apply/resume and business validation in staging, then release the compatible client and coordinate final Rules/old-client cutover. Production follows only after its separate approval.

## Backup, migration, recovery

- [ ] Choose a restricted encrypted managed backup bucket with retention/access controls and enough capacity. Keep tokens/private records out of Git and human audit reports. Record backup timestamp, project, database, storage URI and operator.
- [ ] With the selected project explicit, run a managed Firestore export; example operator template: `gcloud firestore export gs://APPROVED_BUCKET/APPROVED_PREFIX --project=APPROVED_PROJECT`. Do not execute placeholders or use the local fixture JSON as a production backup.
- [ ] Restore the export into an isolated approved staging/recovery database/project and compare document/nested collection counts, representative Timestamp/GeoPoint/reference/private fields, assignments, task links, attendance scopes and counters. Record actual results. Managed import template: `gcloud firestore import gs://APPROVED_BUCKET/APPROVED_PREFIX --project=APPROVED_RECOVERY_PROJECT`.
- [ ] Run migration dry-run with explicit `--project`, `--report` and `--checkpoint` paths outside Git. Dry-run writes no database/checkpoint; only the explicitly requested report is written. Review IDs/reasons for unknown tracking, visit/custom labels, historical grade/status and conflicting targets. Reject a run against the wrong project.
- [ ] Approve expected counter/roster/alias/date changes. Resolve oversized units separately; do not silently truncate dependent records. Historical ambiguity stays `legacyUnknown` until a trusted correction is approved. Never infer a prior school year from a child's current grade.
- [ ] Apply and rehearse crash/resume in staging. Keep the same plan/checkpoint and server receipts. Re-run with `--apply --resume`; verify edits made after completed units survive. Verify all expected parts use the same root canonical sessionId and Timestamp date, actual grades, task link, type and status. Do not erase receipts to force migration over new data.
- [ ] Preserve raw/general notes and custom user text. Verify `legacyNotes`, `secondaryTypeCustomLabel`, trackingStartEstimated and createdAtKnown match reader semantics. Confirm missing createdAt did not produce an invented origin/date.
- [ ] Bootstrap only a real existing Auth UID and eligible profile, default dry-run first. Explicit project and subsequent operator-approved apply are required; Auth UID is checked by the CLI before grant.

If rollback is needed, stop writes and capture post-migration changes first. Restoring an old full backup may discard later legitimate writes; decide how to retain/replay them. Restore to an isolated database and verify before changing live readers. Restore a coordinated backend/client/Rules version set that reads the selected schema; checking out an old Git tag alone does not repair database compatibility. Keep migration receipts/checkpoints paired with their backup epoch. The fixture restore command deliberately restores only `demo-efteqad-rules` with `FIRESTORE_EMULATOR_HOST`.

## Quality and performance evidence

```text
flutter gen-l10n
dart run tool/audit_localization.dart
flutter analyze --no-pub
flutter test --no-pub
firebase emulators:exec --only auth,firestore,functions --project demo-efteqad-rules --config firebase.json "npm --prefix functions test"
node --check functions/scripts/migrate_v2.js
node --check functions/scripts/bootstrap_admin.js
```

- [ ] Record command/exit/count/runtime/log and source revision, not just checkmarks. Node 22 package+lock matches tested host; [Firebase's runtime documentation](https://firebase.google.com/docs/functions/manage-functions#set_nodejs_version) lists support. Existing SDK upgrade notices remain disclosed; do not conflate them with failing tests.
- [ ] Distinguish direct business-worker tests from real scheduled Pub/Sub invocation, and injected Auth/FCM boundaries from device acceptance.
- [ ] Task 7 runs integrated Auth→pending→approval/grade→import/assignment→task/notification→two-device attendance/finalization→visit→language/theme restart→logout/account replacement→reauth/deletion. Use demo emulator or approved staging, never a real production account for destructive acceptance.
- [ ] Measure staging first-screen latency, query counts/documents returned, billing reads and populated-grade fanout separately. Local Task 5 counts/timings in README are synthetic emulator measurements. Confirm deployed composite indexes, SDK cache/pending UI and bounded retry; document network/device and dataset size.

## Android signing

- [ ] Keep applicationId `com.example.efteqad` and existing Firebase registration unless an explicit separate registration change is approved.
- [ ] Supply a real private keystore and ignored `android/key.properties` locally. `storeFile` resolves relative to `android/`; use four nonempty fields: keyAlias, keyPassword, storePassword, storeFile. Check actual alias/certificate/password with the signing tools without exposing secrets in logs.
- [ ] Register real SHA-1/SHA-256 fingerprints and verify physical Google Sign-In. Debug build remains usable. An unsigned release must fail; failure is an expected gate, not successful release acceptance.
- [ ] Run `flutter build appbundle --release` with authorized credentials, inspect the certificate and artifact, and record the result. Never use a debug fallback/fake key to satisfy release acceptance.
- [ ] Audit tracked filenames and content patterns for keystore/private PEM/service-account credentials without printing values. This is a scoped repository scan, not comprehensive secret certification.

## Apple, web and desktop

- [ ] iOS: confirm existing plist CLIENT_ID/REVERSED_CLIENT_ID/BUNDLE_ID in the correct registered app; Info.plist URL scheme comes from that public config. Existing localized location-purpose strings stay valid. On macOS/Xcode verify capabilities, provisioning/team, APNs key upload, background delivery, permission denial, Google Sign-In and universal/deep links. Do not invent a team/domain or treat this Windows host as an Apple build environment.
- [ ] Android/iOS physical tests: two-device presence merge, lost-response retry, token rotation, logout/credential loss, account replacement, generic localized lockscreen content and notification resource denial.
- [ ] Web: validate configured Firebase authorized domains, OAuth redirect, exports/downloads, browser notifications and service-worker deployment. A compiled web bundle does not prove those behaviors.
- [ ] Windows/macOS: test plugins, file picker/sharing/export and notification behavior on actual target hosts. Linux has no Firebase configuration and is unsupported. Do not announce full platform support from unit tests or public config alone.
