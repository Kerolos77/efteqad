# Task 5 — truthful analytics/history and bounded queries

Implementation completed for independent parent review on `codex/complete-blueprint`, base `bbf808f`.
Product/test commit: `b5d3f9512736f8a2eb0f94dce0e567413d4ac93e` (49 explicitly owned files; see task-5-owned-files.json). The preexisting user MakhdomModel tracking edit was preserved and integrated. The two unrelated untracked blueprint audit documents were not staged or modified. No SDK/dependency upgrade, production operation, migration apply, deployment, or credential change.

## Production behavior

- Shared production attendance opportunities use finalized service sessions, strict valid ISO local dates, active children, matching grades, and inclusive tracking start. Each child/date/type appears once across root/grade duplicates. Numerator and denominator use exactly the same eligible child IDs; out-of-grade/archived/untracked attended IDs cannot produce rates above100%.
- Service streaks ignore mass. Mass has a separate nullable rate and cannot create service absence or reset a service streak. Draft, legacyUnknown, future, malformed dates and earlier tracking sessions are excluded. Unrecorded dates are not absences. maxWeeks selects distinct chronological service dates.
- Zero eligible service produces nullable rates, insufficient history, and an explicit insufficient segmentation bucket. UI displays localized insufficiency instead of zero or an at-risk classification. Single completed eligible service has a known rate. History's visit-related comparison deduplicates the next service Friday even with multiple preceding visits.
- Visits and attendance comparisons use the same selected window; lifetime visitCount is not used to classify visited/unvisited groups. Last visit sorts visitDate,createdAt,ID descending. General notes, latest selected-window visit report, and legacyNotes are displayed separately.
- Group/history defaults include exactly90 local dates (asOf minus89 days through asOf); for injected2026-10-16 this is2026-07-19–2026-10-16. Bounds are displayed using generated localized resources. History30-day/custom/all-time and admin all-time are explicit; all KPIs and trend/relation calculations use the selected bounds. asOf is injectable on history/admin analytics; pure calculations receive asOf.
- History consumes Task3's live authorized widget model and rebinds its grade query on profile changes, with no stale fallback. Record actions use the current model. QueryContent owns stable subscriptions, cancels prior scopes and creates a new read on retry. Routed stage/grade/me/tasks reads handle loading, error, empty and SDK provenance before consuming lists. SessionState.grade is captured while active, avoiding retained-shell profile access during logout.
- Absence notification success displays returned server recipientName/receipt rather than stale assigned name; failures use localized AppFailure. Backend rejects excluded/userless recipients under the existing Task1 contract.

## Queries and pagination

- Grade/servant attendance: collectionGroup grades, grade==own, inclusive ISO date range, date DESC. Stage uses the same grade-part schema, grade IN1st/2nd/3rd and the same bounds/order. It does not infer a finalized stage root from partially completed grade parts. Existing grade/date COLLECTION_GROUP index covers these actual shapes.
- Visits: makhdomId for child history; grade for grade admin; stage scope otherwise; Timestamp visitDate>=local start and visitDate<day after selected end; visitDate/createdAt/documentID DESC. Existing manifest indexes cover these shapes, including implicit descending documentID on makhdomId and notification indexes. No index/Rules changes were required.
- Servant comparisons read each currently assigned child's authorized makhdomId window, including other authorized authors. At most4 get requests in flight. Scope cancellation prevents later groups; in-flight SDK gets finish. Any child error rejects the combined analysis rather than becoming empty. This comparison is a one-shot bounded read: assignment-set changes, a locally recorded visit, or explicit refresh reload it. Admin/history analysis remain live SDK listeners.
- History timeline and inbox call fetchVisitPage/fetchNotificationPage with document cursors and50-row pages. Analysis uses a separate full selected-window query, never the first timeline page as all-time KPIs. PagedContent retries a failed later page from the last successful cursor without duplicating existing items and invalidates stale generations on scope changes.
- Inbox is paged rather than a full lifetime notification listener; reopening or successful mark-all-read refreshes pages. Notification taps await read confirmation and display failures; successful marks update the local card. Unread badge uses an independent recipientId/isRead=false query and distinguishes loading/error from zero. mark-all-read is awaited/caught and chunks200 unread documents; retry resumes remaining unread chunks.
- SnapshotList carries SDK isFromCache/hasPendingWrites from includeMetadataChanges reads to AsyncContent. Cache data says it awaits server confirmation, not that connectivity is necessarily offline. Cached retained pages continue showing cache provenance even after another server page arrives. PresenceCubit metadata-only confirmation behavior was not changed.

## Task 6 model/migration contract

- Existing trackingStartDate/effectiveTrackingStartDate/isTrackingEstimated/copyWith(clearTrackingStartDate)/toMap/fromMap are preserved. `trackingStartEstimated` is a bool marker for materialized migration fallback. isTrackingEstimated is true when the date is absent OR markertrue. Ordinary copy/map preserves it; explicit copyWith tracking date clears the marker unless explicitly suppliedtrue. Clearing returns the estimated createdAt fallback.
- `createdAtKnown` is bool, defaulttrue in the constructor. fromMap infers false when createdAt is missing/unparseable or markerfalse; toMap/copyWith retainfalse even with the compatibility synthetic createdAt DateTime value. Analytics excludes unknown origins until an explicit trusted tracking date exists. A migration must not invent a tracking date for unknown createdAt; leave trackingStartDate unset and createdAtKnownfalse. A real legacy createdAt fallback may be materialized with trackingStartEstimatedtrue.
- Backend saveMakhdomProfile derives trackingStartEstimated=false for an explicit non-null date andtrue on clearing. Clients cannot override trackingStartEstimated/createdAtKnown or counters/assignment fields. New server profiles/imports set createdAtKnowntrue. Ordinary estimated model profile serialization omits trackingStartDate to avoid unintentionally converting an estimate into an explicit override.
- `secondaryTypeCustomLabel` is nullable user text preserved in model/map/copy/profile patch/backend/import payload, the custom editor, card labels and Excel export. Canonical secondaryType stays separate; unknown legacy user labels remain user text. `legacyNotes` is separate nullable legacy mixed-note text. Removed unused localized gradeDisplayName and its specific audit exemption; legacy getter use still fails the audit.

## RED → GREEN evidence

- Initial production calculation RED:8 failures in task5_analytics_contract_test (mass resets service streak; mass-only false alert; tracking counts2vs1; legacyUnknown/malformed counts2vs0; zero rate0vsnull; mixed numerator133.333vs100; maxWeeks duplicate dates; missing-createdAt roundtrip0vsnull). Focused calculation/history GREEN20 tests.
- Production query RED requested includeMetadataChanges but emittedfalse; GREEN query result carries SDK cache/pending metadata. Client payload RED task-5-profile-red.log dropped custom label; GREEN preserves label and migration estimate.
- Backend RED task-5-backend-red.log:3 tests,1 pass2 fail (import label dropped; callable rejects customlabel). Focused backend/query GREEN6 tests, including actual Rules/query/cursor fixtures.
- Widget RED masked history permission failure and no-data impact null crash. Cache RED task-5-cache-red.log lost provenance when a server page followed retained cache; GREEN3 real widget cases including cursor retry and listener cancellation. Final focused task-5-focused-final.log22 passed, including production chunk recovery250 unread →200 confirmed/50 failed/50 retried, live grade/default window, and same-window visit classification.
- First broad gate task-5-flutter-final.log314 passed25 failed:6 router/inbox/history cases;16 history AR/EN layout cases;3 audit subprocess30-second timeouts under concurrently running analyzer/emulator/audit. These are not hidden. Repairs use SessionState.grade, active scope guards, stable task query identity, a page adapter only at the controlled inbox fixture boundary, and localized compact insufficient KPI values. Scoped repaired router/visit-label tests passed; final history matrix36 passed for AR/EN100%/200%. Sequential full suite resolved all failures without raising timeouts.
- Final signed-value RED task-5-zero-difference-red.log4 passed1 failed: zero lacked numeric percentage points; negative and positive already passed. GREEN task-5-zero-difference-green.log5 passed, including actual -100.0/0.0/100.0 widget rendering, permission errors and insufficiency. This last change only replaces the equality-wording ternary with the existing localized numeric renderer.

## Final quality gate

- `flutter test --no-pub --reporter expanded --concurrency=2`: task-5-flutter-final2.log / .exit0, **339 passed,0 failed**, before the final single-renderer zero-display fix. Per parent instruction, post-fix covering widget verification replaces another full run: task-5-zero-difference-green.log / .exit0, **5 passed**, including3 newly added signed cases. Do not describe the full339 run as post-zero.
- `flutter analyze --no-pub`: task-5-analyze-post-zero.log / .exit0, **No issues**,15.7s after the final renderer change.
- `flutter gen-l10n` generated all9 added resource keys. `dart run tool/audit_localization.dart`: task-5-audit-post-zero.log / .exit0, **686 resources,89 AST files,2306 literals/interpolations,223 UI/legacy candidates,768 generated references,0 issues**.
- Full local backend: task-5-backend-final.log / .exit0, **107 passed,0 failed/cancelled/skipped**. Command: process-local JAVA_HOME=C:/Program Files/Android/Android Studio/jbr, firebase emulators:exec --only 'firestore,functions' --project demo-efteqad-rules --config D:/work/flutter/efteqad/firebase.json 'npm --prefix functions test'. No backend changes followed this passing gate. Node22 host vs deployment engine20 remains the prior environment limitation, without an SDK upgrade.
- Formatting completed and git diff/cached diff --check passed before the49-file implementation commit. A routine dartfix attempted an unrelated dependency addition; that exact addition was removed and pubspec/lock are unchanged.

## Synthetic local emulator measurement and limits

Final107-test run recorded actual local emulator query documents returned (NOT staging/billed reads): visit fixture130 docs →110 bounded results, pages50/50/10, no gaps/duplicates at tied visitDate/createdAt/documentID; three-page sequence989ms. Attendance fixture124 grade parts →own12 and stage24 bounded results; combined authorized/denied query checks449ms. The earlier focused run recorded the same counts at1045ms/391ms. These timings include local Rules/query overhead and are not first-screen-load or production benchmarks. Servant fanout is one bounded query per current assigned child with four concurrent requests, so total query count scales with assigned population.

Staging read/billing/latency measurement remains unverified until deployment is authorized. Existing100MB bounded cache is not a shared-phone privacy guarantee. Emulators do not prove deployed composite indexes or physical-device/offline/platform acceptance. No live Firebase operations were performed.

Documentation/report commit follows the implementation commit; its SHA is delivered in the parent handoff to avoid a self-referential report hash.

## Review fix round 1

All four Important findings in task-5-review.md are fixed: custom secondary aliases preserve and display user labels through editor/card/export; calendar day construction gives exact inclusive local-date windows and next-day query cutoffs across Cairo DST; every admin calculation receives the injected clock/window; cached/pending provenance banners wrap at 360px and 200% in Arabic and English.

Focused covering commands (each `flutter test --no-pub --reporter expanded` followed by the listed files):

- `test/task5_review_labels_test.dart test/core/services/excel_service_test.dart`: task-5-fix1-labels-green.log, **30 passed**.
- `test/task5_review_calendar_test.dart test/task5_analytics_contract_test.dart test/task5_window_test.dart test/features/admin/makhdom_history_service_test.dart`: task-5-fix1-calendar-green.log, **22 passed**.
- `test/task5_review_admin_clock_test.dart test/features/localization_widget_matrix_test.dart`: task-5-fix1-clock-banner-green.log, **47 passed**.

`dart run tool/audit_localization.dart`: task-5-fix1-audit-final.log / .exit0, **686 resources, 90 AST files, 2312 literals/interpolations, 223 UI/legacy candidates, 768 generated references, 0 issues**. `flutter analyze --no-pub`: task-5-fix1-analyze-final.log / .exit0, **No issues found**, 15.2s; this final pass follows the labels-test brace correction and a narrowly documented sealed-Query ignore on the existing SDK test probe. No further product behavior changed after the covering runs. Full Flutter/backend gates were not repeated for this fix round; deployment and physical-device limits above remain outstanding.

## Review fix round 2 — calendar test portability

Removed the unconditional Cairo-only setUpAll assertions. Generic history, live/page query bounds, and selected-window visit checks use local calendar fixtures and remain unskipped on every host. The separate Cairo DST test requires the 2026 spring/fall offsets (+3, +3, +2); other hosts explicitly skip it with that reason. A pure host-gate test verifies Cairo offsets are accepted and UTC offsets return false without failing setup. No host timezone, dependency, or product code changed.

- `flutter test --no-pub --reporter expanded test/task5_review_calendar_test.dart test/task5_analytics_contract_test.dart test/task5_window_test.dart test/features/admin/makhdom_history_service_test.dart`: task-5-fix2-calendar-green.log / .exit0, **24 passed**.
- `flutter test --no-pub --reporter expanded test/task5_review_calendar_test.dart`: task-5-fix2-calendar-host-green.log / .exit0, **7 passed, 0 skipped** on the existing Cairo-compatible host, explicitly including the 25-hour query and UTC late-hour visit assertions. The earlier Cairo run with 22 passing tests remains recorded in fix round 1. Actual execution on a UTC host was not performed; only the pure UTC gate case was exercised here. Cairo-specific coverage is conditional on compatible host offsets.
- `flutter analyze --no-pub`: task-5-fix2-analyze-final.log / .exit0, **No issues found**, 14.8s.

This test-only round did not repeat the full Flutter suite, backend, or localization audit.
