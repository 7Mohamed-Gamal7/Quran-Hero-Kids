# Quran Hero Kids — Project Audit

**Original audit date:** 2026-10-18 (Africa/Cairo)
**Original checkout:** branch `feat/firebase-parent-auth-audit`, commit `cd7720d650a995e0233cf0d38d8c5766286414b0` (`docs: record active child selection milestone`)
**Original remote baseline:** `origin/master` matched the checkout at audit time.
**Latest follow-up:** 2026-11-05; see dated follow-up sections below. Current execution history and test results are tracked in [`docs/TASKS.md`](TASKS.md).
**Scope:** the dated sections record local source/document checks and tests as performed. This is not a production, Firebase, privacy-law, licensing, or deployment certification.

## Checkout and preserved changes

At audit start, two pre-existing modifications were present:

- `mobile/test/features/children/presentation/child_profiles_screen_test.dart`: replaces an exact runtime-type button finder with `find.bySubtype<FilledButton>()`, matching the `FilledButton.icon` concrete subtype.
- `mobile/pubspec.lock`: 17 transitive entries changed by `flutter pub get` under Flutter 3.38.5 / Dart 3.10.4. The committed file requires Dart `>=3.11.0-0`; the local resolution downgraded several packages and rewrote the SDK floor. This remains preserved and is not considered intentional dependency work.

This audit adds Android INTERNET permission to the main manifest and audit/setup docs. Firebase dependency installation and auth code were not added: the pub.dev install was denied by the active tool permission gate. No Firebase credentials, Quran source data, cloud resources, or production changes were introduced.

## Repository map

- `mobile/`: Flutter/Riverpod client, REST client, family profile CRUD, and study session UI/repository.
- `backend/src/QuranHero.Api`: ASP.NET Core .NET 8 API, Firebase JWT authentication, owner-scoped controllers, health endpoint, and development/testing OpenAPI.
- `backend/src/QuranHero.Application`, `QuranHero.Domain`, `QuranHero.Infrastructure`: application services/contracts, domain types, EF Core persistence, and Azure SQL migration.
- `backend/tests/QuranHero.Api.Tests`: API integration tests. The test factory uses a test authentication scheme and synthetic identity headers; it does not verify Firebase token signatures against a live project.
- `docs/`: product, source approval, architecture, data model, security, migration procedure, task history, and plan.
- `.github/`: pull request template only; no `.github/workflows/` directory exists.

## Verified implementation status at the original audit (2026-10-18)

- Backend validates Firebase JWT authority, issuer, audience, and lifetime when configured; unconfigured Firebase auth fails closed. Controllers derive owner UID from verified claims and call owner-scoped services.
- Flutter defines a `TokenProvider`, but production wiring returns `MissingTokenProvider`; `ApiClient` blocks before sending if the token is absent/empty.
- Firebase client initialization, parent email/password screens, sign-out, and auth gate are absent. No FlutterFire-generated options or platform app config were found.
- Child profiles support list/create/edit/archive; study sessions have stable event IDs and backend idempotency. Active-child choice and retry drafts are memory-only; there is no durable outbox.
- At the original 2026-10-18 audit, dashboard metrics, tests, and achievements included placeholders. Later dated follow-ups superseded the dashboard metrics: it now reads session count/duration from the server summary and greets by the active profile; daily goals, streaks, tests, and achievements remain unimplemented.
- `docs/product/content-sources.md` states that no source is approved. No Quran content or audio was fetched or added.
- Main Android manifest previously omitted INTERNET while debug/profile manifests contain it. This audit adds the permission to the main manifest; merged release-manifest verification remains pending.
- Production database migrations are separate from application startup and documented in `docs/operations/database-migrations.md`. No database was accessed or migrated.

## Fresh verification on 2026-10-18

| Check | Result | Scope / caveat |
|---|---|---|
| `cd mobile && flutter test` | **Passed: 15 tests** | Full suite after the existing finder correction. |
| `cd mobile && dart format --output=none --set-exit-if-changed lib test` | **Passed: 23 files unchanged** | Formatting check. |
| `cd mobile && flutter analyze` | **Passed: no issues** | Flutter 3.38.5 / Dart 3.10.4. |
| `dotnet test QuranHeroKids.sln` | **Passed: 38/38** | Local tests; auth integration uses test scheme. |
| `dotnet format whitespace QuranHeroKids.sln --verify-no-changes` | **Passed** | No formatting changes required. |
| `dotnet list QuranHeroKids.sln package --vulnerable --include-transitive` | **Passed: no vulnerable packages reported** | Against configured NuGet sources; not a security certification. |
| `git diff --check` | **Passed** | At audit checkpoint. |
| Firebase package installation | **Blocked** | `flutter pub add firebase_core firebase_auth` was denied by the active permission gate. No workaround was attempted. |
| Live Firebase/API test | **Not run / blocked** | No real Firebase options, test account, deployed API URL, or matching environment configuration. |
| Android release build/merged manifest | **Not run** | Source manifest corrected; 2026-10-19 attempt stopped before Gradle because Android SDK is absent in the active environment. No APK/AAB claim is made. |

## Follow-up verification on 2026-10-20

- `dotnet test`: **38/38 passed**; .NET whitespace verification passed; NuGet vulnerability scan reported no vulnerable packages against the configured sources.
- Flutter: **17 tests passed**, analyzer reported no issues, and formatter found no changes in 23 Dart files.
- Targeted widget tests at 320×640 with 200% text scaling found a 52px horizontal overflow in the daily-goal title row and both horizontal (188px) and vertical (70px) overflow in the child-profile dialog. The title is now width-constrained; the dialog is scrollable and its age-band field is expanded with shorter labeling. The full suite passes. These targeted checks do not establish overall accessibility or release-device readiness.
- Repository visibility was reported by GitHub as public (`isPrivate: false`); no visibility change was made because authorization to change it was not provided.

## Follow-up verification on 2026-10-21

- Repository was synchronized before work: `master` matched `origin/master` at `6e0241c`, and the worktree was clean.
- Baseline passed: 38 .NET tests, 17 Flutter tests, Flutter analyze and Dart format; final verification after the change passed 38 .NET tests and 19 Flutter tests, analyzer/format, .NET whitespace verification, and NuGet vulnerability scan (no vulnerable packages reported by configured sources).
- A regression test first reproduced an inconsistent family UI after archiving the selected child: the active marker disappeared while the in-memory ID still referenced an archived profile. On successful archive, selection now moves to the first remaining profile or clears when none remain. Tests cover both cases. Selection remains memory-only and is not account-scoped pending parent authentication.

## Follow-up verification on 2026-10-22

- Repository was synchronized before work: `master` matched `origin/master` at `e67407c`, and the worktree was clean. Full structural/documentation/test/dependency review found Firebase setup/install permission, Quran source approval, CI workflow permission, and Android SDK/build verification still gated or unavailable; no gates were bypassed.
- Baseline passed: .NET **38/38**, Flutter **19/19**, Flutter analyzer/formatter, .NET whitespace verification, and NuGet vulnerability scan (none reported by configured sources). Final Flutter suite after the UI-state change passed **19/19**, analyzer had no issues, and Dart format found no changes in 23 files.
- A red widget assertion reproduced that the first profile displayed by learning when no explicit selection exists was not reflected in shared family state after starting a session. Session start now records the actual child ID to shared in-memory selection; it adds no persistence or child data. Existing active-child state remains non-durable and not UID-scoped.

## Follow-up verification on 2026-10-23

- Repository synchronized cleanly at `6bf5d2f`; structural review covered backend/mobile source layout, tests, dependencies, current plan and product/security/content/data/operations documentation.
- Baseline passed: .NET **38/38**, Flutter **19/19**, analyzer and format, .NET whitespace check, and NuGet vulnerability scan (none reported against configured sources).
- Added a widget test for the study-session screen at **320×640** with **200% text scaling**. Target screen tests passed **4/4**; the full Flutter suite passed **20/20**, analyzer reported no issues, and formatter found no changes in 23 Dart files. This is targeted widget coverage, not full accessibility certification or physical-device validation.
- Firebase remains blocked on real owner configuration and the package permission gate; Quran source/audio remain subject to explicit owner selection and terms approval; no `.github/workflows/` exist; Android release build/merged-manifest verification was not attempted in this session. No external content was downloaded or called and no credentials/resources were created.

## Follow-up verification on 2026-10-24

- Repository synchronized cleanly at `dd7ec41`. Structural review covered tracked source, tests, dependencies, workflows, project plan, and product, architecture, security, data, content, and operations documents.
- Added a semantics widget test for the bottom navigation. It verifies the Arabic labels for Home and Learning, button role, tap action, and selected state for the active destination against the Flutter SDK semantics tree. Full Flutter tests passed **21/21**; analyzer reported no issues; formatter found no changes in 23 Dart files.
- .NET tests passed **38/38**, whitespace formatting passed, and the NuGet scan reported no vulnerable packages from configured sources. These local checks do not constitute accessibility certification or a live-service security review.
- Read-only GitHub API reported repository `admin` and `push` permissions, but did not establish workflow-specific token permission. Because creating workflow files was previously denied, no workflow write was attempted. Firebase config/install permission and Quran text/audio approval remain gates; no credentials, content, or cloud resources were created.
- The same read-only GitHub response reported the repository visibility as **public**. No visibility change was made; owner direction is still needed on whether that is intentional. This check did not establish that secrets or sensitive data were exposed.

## Follow-up verification on 2026-10-25

- Repository synchronized cleanly at `7b3763a`; structural, task-ledger, documentation, and dependency review confirmed Firebase setup/install, Quran content approval, CI workflow permission, and repository-visibility direction remain outstanding.
- A new semantics test reproduced duplicate spoken/textual duration: the node exposed both its explicit `المدة 00:00` label and the descendant's `00:00` text. The timer's explicit live-region semantics now exclude descendant semantics, leaving one accessible label; test coverage confirms it updates from `00:00` to `00:03` while the session runs. Study-session tests passed **5/5**; full Flutter suite passed **22/22**, analyzer had no issues, and formatter found no changes across 23 Dart files.
- .NET tests passed **38/38**, whitespace format verification passed, and NuGet scan reported no vulnerable packages from configured sources. `git diff --check` and local documentation-link verification passed before final documentation commit. No backend, API, database, Quran content, credentials, or cloud resources changed.
- GitHub read-only check again reported the repository as **public** and account permission as admin/push; workflow-specific write permission was not established. No visibility or workflow settings were changed.

## Follow-up verification on 2026-10-26

- Repository synchronized cleanly at `76ea711`. Structural review covered the tracked backend/mobile/docs layout, .NET and Flutter projects/tests, and workflow state (no `.github/workflows/` directory); product, architecture, security, data, content, operations, and task-ledger docs were reviewed.
- A widget semantics test found that the child age-band field showed the visual helper `اختياري`, but Flutter's semantics label did not expose that optionality. The dropdown now publishes `اختياري` as a semantic hint, merged with the field's dropdown semantics. The test verifies the child-name label, age-band label, optional hint, and button role. Target child-profile suite passed **7/7**; full Flutter suite passed **23/23**, analyzer reported no issues, and formatter found no changes across 23 files.
- .NET baseline passed **38/38**, whitespace format verification passed, and NuGet scan reported no vulnerable packages from configured sources. No child data fields, API, database, dependencies, Quran content, or cloud resources changed.
- Read-only GitHub API again reported `visibility: public` and `admin`/`push` repository permission. Workflow-specific token permission remains unestablished; no visibility or workflow settings were modified.

## Follow-up verification on 2026-10-27

- Repository began clean and synchronized on `master` at `b6de83e`; source structure, task ledger, current plan, product/security/data/content/operations docs, tests, and dependencies were reviewed. No `.github/workflows/` directory exists.
- The home dashboard no longer presents hard-coded daily-goal, streak, or point zeros. For a selected active child, it derives saved-session count and total duration from the existing session-history provider; it clearly caps the summary at the API's default latest 30 records. No-selection, loading, and error/retry states are explicit. Goals, streaks, points, and the greeting name remain unbacked; P2.2 is partial, not complete.
- A widget test selects a fake child and verifies the requested child ID, two saved sessions, and a derived duration of 2m40s; home tests also verify the no-selection state. Targeted home suite passed **5/5**; full Flutter suite passed **24/24**, analyzer had no issues, and formatter found no changes across 23 Dart files. .NET baseline passed **38/38**, whitespace format verification passed, and NuGet scan reported no vulnerable packages from configured sources; backend/API/database were unchanged. No live Firebase or API test was possible because real auth/configuration remains absent.
- GitHub read-only API reported the repository **public** with admin/push permission; no visibility or workflow setting was changed. No credentials, Quran text/audio, dependencies, or cloud resources were added.

## Follow-up verification on 2026-10-28

- Repository began clean and synchronized on `master` at `fcca389`; structural review covered 140 tracked files, backend/mobile source and tests, dependencies, current plan, README, product, architecture, privacy/security, data, content, and operations docs. No new cloud resources or workflows were created.
- Added protected `GET /api/v1/children/{childId}/study-sessions/summary`. Application service verifies the active child belongs to the authenticated parent before returning an aggregate; EF calculates count and 64-bit total duration across all saved sessions without applying the list endpoint's 30-record default. Empty summaries return zero values. Integration tests verified 31 saved sessions are summarized as 31/496 seconds while the list returns 30, zero-session behavior, 401 anonymous rejection, and 404 for another parent. OpenAPI documents Bearer and 200/401/404.
- Targeted summary/API-contract tests passed **3/3**; full .NET suite passed **40/40**, .NET whitespace verification passed, and NuGet audit reported no vulnerable packages from configured sources. Flutter baseline before this backend-only slice passed **24/24**, analyze had no issues, and format found no changes across 23 Dart files. The mobile home screen is not yet connected to the new endpoint and still displays the last-30-session preview; P2.2 remains partial. No schema migration, live Firebase/API test, Quran content, credentials, or dependency changes.

## Follow-up verification on 2026-10-29

- Repository began clean and synchronized on `master` at `3d0fad9`; structural review covered 140 tracked files, backend/mobile source and tests, dependencies, plan, README, product, architecture, security/privacy, data, content, and operations docs. No `.github/workflows/` exists in this checkout.
- Flutter now calls the owner-scoped `GET /api/v1/children/{childId}/study-sessions/summary` for the home dashboard. Detailed session history remains on its existing list endpoint. Successful session recording invalidates both the history and summary providers so the dashboard refreshes. A widget test uses a 31-session/496-second aggregate while the fake list contains only two records, proving the home does not derive totals from the 30-item list. REST tests verify path, Bearer header, and JSON decoding; study-session tests verify summary reload after save.
- Targeted Flutter tests passed **14/14**; full Flutter suite passed **25/25**, analyzer reported no issues, and format found no changes across 23 Dart files. .NET baseline passed **40/40**, whitespace verification passed, and NuGet audit reported no vulnerable packages from configured sources. No backend, database, schema, or dependency changed today. P2.2 remains partial because goals, streaks, points, greeting identity, and genuine Firebase/API connectivity are not complete or live-tested.
- Firebase installation/configuration and Quran source approval remain blocked as recorded in `docs/TASKS.md`; no content, credentials, cloud resource, workflow, or external service was used.

## Follow-up verification on 2026-10-30

- The home greeting now derives the name from the active child ID and the loaded family-profile provider, falling back to a generic greeting when no matching profile is available. The prototype name dialog/state was removed, and the home CTA now navigates to Family profile management. No child data model, backend, API, database, or dependency changed.
- Drafted [`docs/product/progress-timezone-design.md`](product/progress-timezone-design.md) with proposed owner-timezone, DST, delayed-session, daily-goal, and streak rules. It is explicitly design-only: no backend contract/schema was added, and P2.1 still needs parent timezone configuration and product decisions.
- Regression tests verify the active profile name alongside all-session totals and that the management CTA opens Family. The targeted home test file passed **5/5**; full Flutter suite passed **25/25**, `flutter analyze` reported no issues, and `dart format --output=none --set-exit-if-changed lib test` passed. A final full-suite rerun after the icon polish is recorded in `docs/TASKS.md`.
- .NET was unchanged; the latest prior full baseline passed **40/40** with .NET whitespace verification and NuGet audit reporting no vulnerable packages from configured sources. No live API/Firebase test was possible because production client auth/configuration remains absent. Quran source approval, CI workflow permissions, and the owner decision on public repository visibility remain open; no content, credentials, workflows, cloud resources, or repository settings were changed.

## Follow-up verification on 2026-11-01

- Repository synchronization began on `feat/home-active-child-greeting` at `d4ba05f`; `origin/master` was `d11d722`. A seven-area structural review covered backend, Flutter/UX, security/privacy, tests, dependencies/platform setup, documentation/task history, and repository layout. Six local backend/test files comprised the in-progress idempotency slice; no unrelated worktree changes were present.
- A concurrent integration test first reproduced an unhandled `DbUpdateException` when two requests attempted the same `(ChildId, ClientEventId)`. The repository now re-reads the persisted winner after a failed insert and returns it to the service for payload comparison: matching retries return HTTP 200, conflicting payloads return 409, and one session remains. OpenAPI and regression tests cover the duplicate response and both concurrent outcomes. Code was saved as `0009cf7`.
- Targeted session/OpenAPI tests passed **14/14**; full .NET suite passed **42/42**. `.NET format whitespace --verify-no-changes`, `git diff --check`, and NuGet vulnerability audit passed; NuGet reported no vulnerable packages against the current source. The API test fixture uses SQLite in-memory; no live SQL Server/Azure SQL concurrency test was run. Flutter did not change; its latest recorded full suite remains **25/25** with analyzer/format passing on 2026-10-30.
- Firebase client auth/configuration and the package permission gate remain unresolved; Quran text/audio source terms still require the owner's explicit choice/approval; no CI workflows exist and workflow permission is unconfirmed; repository visibility was not changed and owner direction remains outstanding. No credentials, child PII, Quran text/audio, production DB, or paid cloud resource was used.

## Follow-up verification on 2026-11-02

- Repository synchronized at `master` / `origin/master` `c33abf9` with a clean worktree before changes. A seven-area structural review covered backend, Flutter/UX, security/privacy, tests, dependencies/platform setup, project documentation, and repository structure.
- Static review found that `ApiConfig` accepted `http` even though `ApiClient` attaches an Authorization Bearer header and the security baseline requires TLS. The configuration now accepts only HTTPS URLs; tests cover HTTPS acceptance, HTTP and malformed URL rejection, and that an HTTP URL is rejected before the client transport is called (so no bearer request is sent).
- Targeted Flutter networking tests passed **8/8**; full Flutter suite passed **29/29**, analyzer reported no issues, formatter found no changes in **24** Dart files, and `git diff --check` passed. Backend did not change; the latest full .NET run remains the recorded **42/42** from 2026-11-01. No live API/TLS endpoint or certificate was tested.
- P3.2 remains open for rate limiting, CORS/security headers, data lifecycle, logging review, threat modeling, and broader isolation tests. Firebase setup/install permission, Quran-source approval, CI workflow permission, and owner direction on public repository visibility remain unresolved. No credentials, Quran content, production services, or paid resources were used.

## Follow-up verification on 2026-11-03

- Repository fetch confirmed a clean, synchronized `master` / `origin/master` at `9cee6a3` before work. A seven-area structural review covered backend, Flutter/UX, security/privacy, tests, dependencies/platforms, documentation, and repository inventory. A candidate concern about numeric session-kind parsing was not treated as an API vulnerability: request validation includes a regular expression and `[ApiController]` automatic model validation; no backend change was made.
- Review found a confirmed state-reporting issue in `ChildProfilesController`: mutation and subsequent list reload shared one `try`, so a successful server create/edit/archive followed by a failed list refresh returned `false` and could prompt duplicate writes. The controller now reports write success and derives a temporary visible profile list from the confirmed mutation response when refresh fails. Regression tests cover create, edit, and archive.
- The controller + family-screen tests passed **10/10**; full Flutter suite passed **32/32**, `flutter analyze` reported no issues, Dart formatter found no changes in **25** files, and `git diff --check` passed.
- .NET baseline: the first targeted `StudySessionsEndpointTests` run reported **12 passed / 1 failed** with SQLite error `unable to delete/modify user-function due to active statements` while initializing a connection in the conflicting concurrent retry test. The failing test then passed alone (**1/1**) and the complete targeted class passed on rerun (**13/13**); backend source was not changed. This is a potentially intermittent fixture/concurrency issue requiring follow-up, not a reproducible test failure. The full .NET suite was not run today; latest recorded complete suite remains **42/42** on 2026-11-01. Follow up under P3.7 in `docs/TASKS.md`.
- Firebase client configuration/install permission, Quran-source owner approval, CI workflow permission, production-provider testing, privacy lifecycle controls, and owner direction on public repository visibility remain open. No Quran content, credentials, live API, production database, or paid resources were used.

## Follow-up verification on 2026-11-04

- Repository fetch confirmed clean, synchronized `master` / `origin/master` at `a985b16` before changes. A seven-area structural review covered backend, Flutter/Riverpod, security/privacy, tests, dependencies/platform setup, docs/task history, and architecture/release readiness. Higher-impact auth, approved-content, session-outbox, deletion/export, signing, CI, and environment-validation work remains gated by credentials, approvals, policy, or owner-managed environments; no external resource was used.
- Mobile review found `ApiClient` caught request-send exceptions but read `response.stream.bytesToString()` outside the network handling boundary. A new test first failed with a raw `SocketException` after simulated HTTP headers; the read now shares the transport `try` and the failure maps to `ApiFailureType.network`. HTTP status handling and JSON decode errors remain separate.
- Static release/operations review found that Android `buildTypes.release` currently selects the debug signing configuration (`mobile/android/app/build.gradle.kts:32-37`), and `/health` returns a constant `ok` without checking database readiness (`backend/src/QuranHero.Api/Program.cs:63-67`). Both were recorded as open release gates; no build or service check was run, and no signing key or database environment was accessed.
- Targeted networking tests passed **13/13**; complete Flutter suite passed **33/33**; `flutter analyze` reported no issues; formatter found no changes in **25** files; `git diff --check` passed. .NET tests were not run because no backend code changed. P3.7's intermittent SQLite test fixture issue remains open.
- Documentation review found the original audit's dashboard status was stale and the Dart debt row conflated project and lockfile constraints. The audit now labels the 2026-10-18 snapshot and notes the later summary/greeting implementation. The debt record now accurately states `pubspec.yaml` Dart `>=3.4.0`, while `pubspec.lock` requires Dart `>=3.8.0-0` and Flutter `>=3.18.0-18.0.pre.54`; neither manifest nor lockfile was changed. Local Markdown links were checked; none are broken.
- No Firebase credentials, Quran content/source calls, production database, live endpoint, paid resource, or child PII was used. No deployment/build publication is claimed.

## Follow-up verification on 2026-11-05

- Repository fetch confirmed a clean, synchronized `master` / `origin/master` at `3df92df` before work. A seven-area review covered backend/API reliability, Flutter state and UX, child privacy/security, test quality, dependencies/platform configuration, documentation, and release readiness.
- Mobile review confirmed that `ApiClient._errorMessage` returned server-supplied `detail/title/message`, and the child-profile screen displayed `ApiException.message` verbatim. A regression test first failed with an injected internal SQL path and synthetic child name. The client now selects stable Arabic user-facing messages from the HTTP status code; the numeric `statusCode` remains available on the exception. Tests cover 400, 401, 403, 404, 409, 422, 500, and an unrecognized code, and assert the injected detail is not returned.
- Network tests passed **20/20**; full Flutter tests passed **40/40**; `flutter analyze` reported no issues; formatter found no changes in **25** files; `git diff --check` passed. .NET tests were not run because backend code did not change.
- The review also confirmed open gates already tracked: release signing uses the debug configuration, `/health` is liveness-only and does not check DB readiness, Firebase client auth lacks approved installation/configuration, and no Quran content source is approved. A specific coverage gap for HTTP 409 and malformed successful responses in the study-session REST repository was recorded as P3.9. README now documents Flutter tests and analysis commands.
- No Firebase credentials, Quran source/content, production database, live endpoint, paid resource, or child PII was used. No Android release artifact or deployment is claimed.

## Priority findings from the original audit (2026-10-18)

1. **P0 — Flutter parent Firebase auth is absent.** Preserve fail-closed behavior. Add Firebase only after the active install permission gate allows it and real generated options are provided/configured.
2. **P0 — Android release networking.** Main manifest now declares INTERNET; verify the merged release manifest during the next Android build.
3. **P1 — Account-scoped state.** Active-child selection and pending retries are not persisted/account-keyed. UID-bound restoration and account-switch invalidation need an auth state first.
4. **P1 — Content approval remains a hard gate.** Do not fetch, generate, or package Quran text/audio before owner approval of source terms and separate recitation rights.
5. **P1 — Documentation was stale.** `docs/TASKS.md` had old branch/hash and test counts; this audit reconciles current facts and preserves historical entries.
6. **P2 — Release/privacy readiness.** No CI workflows exist. Deletion/export/retention, release-device testing, live Firebase validation, accessibility breadth, monitoring, and operational recovery are not established by the local checks above.

See [EXISTING_FEATURES.md](EXISTING_FEATURES.md), [TECHNICAL_DEBT.md](TECHNICAL_DEBT.md), and [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md) for detailed status and sequencing.
