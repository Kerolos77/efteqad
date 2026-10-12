# Efteqad remaining blueprint implementation plan

> **For agentic workers:** Use superpowers:subagent-driven-development; task briefs and progress in .superpowers/sdd/2026-10-08-completion. User approved implementation and same-directory independent branch.

**Goal:** Close remaining local-code acceptance gaps from the original blueprint and recheck without replacing the Flutter/Firebase feature structure.
**Architecture:** Preserve features, repositories, services and models. Trusted writes use callable backend; Router and generated localization become the single UI entry points.
**Tech Stack:** Existing pinned Flutter/Dart/Firebase/go_router/Bloc; no broad SDK upgrades.
**Spec:** docs/superpowers/plans/2026-10-07-efteqad-blueprint.md sections2,4,5 and docs/superpowers/plans/2026-10-08-blueprint-recheck.md.

## Global Constraints
- Work on codex/complete-blueprint in current directory as user selected. Preserve pre-existing MakhdomModel trackingStartDate edit.
- ar-EG/en-US. User-entered content is never automatically translated.
- Preserve applicationId, existing Firebase registration, feature structure, and layouts except translation/error/navigation fixes.
- No production deployment, account operation, or migration. Emulators use demo-efteqad-rules.
- Tests exercise production contracts; RED then GREEN; full local quality gate at end.
- Release/device/staging acceptance must be documented honestly when environment lacks credentials/devices.

## Review Focus
- Pending/deleting/cross-grade users cannot invoke privileged writes or access unassigned children.
- Retried writes and partial imports never duplicate or overwrite subsequent data; concurrent last intent remains consistent.
- Cold links, role/grade/user changes and notification taps cannot retain stale protected views.
- All displayed application strings use generated resources; real screens support both directions and200% scale.
- Legacy schema, no-data analytics, migration resume and release absence of signing key fail transparently.

### Task 1 — Trusted operations and Rules
**Files:** functions/src/access.js, tasks.js, assignments.js, visits.js, attendance.js, imports.js, admin_operations.js; firestore.rules, firestore.indexes.json; functions/test/.
**Interfaces:** createTask({operationId,taskData}); assignMakhdoms({ids,targetKhademId,expectedAssignments,operationId}); recordVisit({operationId,makhdomId,visitDate,visitType,notes}); updateVisitNotes({visitId,notes}); finalizeAttendance({sessionId,grade,taskId}); importRows({importId,grade,rows}); archiveMakhdom({makhdomId,operationId}).
- [ ] Write failing tests for pending/cross-scope/unassigned writes, recipient grade/active, retry IDs, duplicate assign IDs, empty latest notes, task linkage/finalized mutations.
- [ ] Observe failures using node tests and Rules emulator.
- [ ] Implement trusted transactions and scope validation; roles/outbox/counters server-owned; retain safe legacy readers; minimal roster creation/update.
- [ ] Verify backend suite and emulator. Commit only task-owned files and report contracts needed by Dart.

### Task 2 — Wire client data flows, attendance, device/deletion/import retries
**Files:** lib/core/services/firestore_service.dart, device_registration_service.dart, notification_service.dart, auth_service.dart; core repositories/models; feature attendance, tasks, visits, assignment, Excel; functions/src/notifications.js/account_deletion.js and tests.
- [ ] Write failing repository/UI contract tests and durable worker tests (no duplicate repeat, no stale account device bind, partial delivery retry).
- [ ] Wire actual UI to Task1 callables; retain operationId/importId and per-row ledger; serialize presence changes, enforce task/finalized scope; roster model contains minimal fields only.
- [ ] Implement leases/scheduled bounded retries for outbox/deletion; status semantics and recent-auth/last-admin guard; cleanup errors gate account transition.
- [ ] Run suites and emulator; report no live execution. Commit.

### Task 3 — Session and full Router
**Files:** core/router/session; features auth/settings/common/drawer/admin cards/tasks/history/attendance and router tests.
- [ ] Reproduce cold-link/deleting/grade2+3 tabs/resource deletion/downgrade/logoutBack failures.
- [ ] Replace all page Navigator routes with Router while retaining modal pop; validate live resources/scope, reset shells on scope changes, preserve safe intended URI; unify push intent.
- [ ] Test real router/widgets/session; analyze; commit.

### Task 4 — Generated localization and preferences
**Files:** lib/l10n, core/localization/settings/errors/widgets, main.dart, feature string sites, tool/audit_localization.dart; tests.
- [ ] Write failing real-screen AR/EN/200% tests and source audit fixtures.
- [ ] Transfer manual resources to ARB/gen-l10n; keep context.tr compatibility; translate remaining displayed literals/errors; ICU plurals/codes/formatting and locale/device/account precedence before first frame.
- [ ] Audit AST user-facing strings with narrow documented allowlist; placeholders/ICU; backend recipient templates.
- [ ] gen-l10n, audit, tests, analyze; commit.

### Task 5 — Analytics, history and query performance
**Files:** analytics/history services/models/widgets; MakhdomModel; repositories and StreamBuilders.
- [ ] Reproduce service-only streak, tracking start, zero-data insufficient, population mismatch, distinct dates, common90-day window and query error handling.
- [ ] Finish existing tracking edit across copy/map/serialization; finalized service-only warning, mass independent, stable dates, same eligible population; live child history; wire server period/cursors/unread/cache metadata and retries.
- [ ] Test calculations/real query contracts/widgets; commit.

### Task 6 — Migration, release and operational docs
**Files:** functions/scripts/migrate_v2.js/bootstrap_admin.js and tests; android signing; README/docs/release-checklist; iOS config if verifiable.
- [ ] Reproduce resume/apply retry safety, legacy aliases/notes/counts and ambiguous historic grade behavior using emulator fixtures.
- [ ] Checkpoint/report/resume; grade-doc/roster migration without guessing historic grade; explicit estimated tracking, preserve legacy unknown/user notes; dry-run default.
- [ ] Fail release without signing credentials; preserve applicationId; document backup/restore/staging rollout/platform prerequisites; verify available builds/config without deployment.
- [ ] Run tests and commit.

### Task 7 — Integrated acceptance and final review
**Files:** integration_test/app_flows_test.dart, dev dependency/config; meaningful widget/repository/Functions integration fixtures; completion report.
- [ ] Replace placeholder and cover role transitions/task→notification→attendance/visits/import/restart/logout/deletion on emulator-capable boundaries.
- [ ] Run gen-l10n, localization audit, flutter analyze, flutter test and full Firebase emulator suite.
- [ ] Independent whole-branch review; address findings with RED→GREEN and green suites; update all original65 checkbox dispositions with evidence.
- [ ] Record device/staging-only limitations without inventing verification; commit local result, no merge/push/deploy.

