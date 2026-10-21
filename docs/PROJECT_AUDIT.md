# Quran Hero Kids — Project Audit

**Audit date:** 2026-10-18 (Africa/Cairo)  
**Checkout:** branch `feat/firebase-parent-auth-audit`, commit `cd7720d650a995e0233cf0d38d8c5766286414b0` (`docs: record active child selection milestone`)  
**Remote baseline:** `origin/master` matched the checkout at audit time.  
**Scope:** inspection of current implementation and docs plus fresh local checks. This is not a production, Firebase, privacy-law, licensing, or deployment certification.

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

## Verified implementation status

- Backend validates Firebase JWT authority, issuer, audience, and lifetime when configured; unconfigured Firebase auth fails closed. Controllers derive owner UID from verified claims and call owner-scoped services.
- Flutter defines a `TokenProvider`, but production wiring returns `MissingTokenProvider`; `ApiClient` blocks before sending if the token is absent/empty.
- Firebase client initialization, parent email/password screens, sign-out, and auth gate are absent. No FlutterFire-generated options or platform app config were found.
- Child profiles support list/create/edit/archive; study sessions have stable event IDs and backend idempotency. Active-child choice and retry drafts are memory-only; there is no durable outbox.
- Dashboard progress, tests, and achievements include placeholders. Follow-up on 2026-10-19 corrected the home action copy so it no longer implies that a surah/recitation index is available; metrics remain prototype values.
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

## Priority findings

1. **P0 — Flutter parent Firebase auth is absent.** Preserve fail-closed behavior. Add Firebase only after the active install permission gate allows it and real generated options are provided/configured.
2. **P0 — Android release networking.** Main manifest now declares INTERNET; verify the merged release manifest during the next Android build.
3. **P1 — Account-scoped state.** Active-child selection and pending retries are not persisted/account-keyed. UID-bound restoration and account-switch invalidation need an auth state first.
4. **P1 — Content approval remains a hard gate.** Do not fetch, generate, or package Quran text/audio before owner approval of source terms and separate recitation rights.
5. **P1 — Documentation was stale.** `docs/TASKS.md` had old branch/hash and test counts; this audit reconciles current facts and preserves historical entries.
6. **P2 — Release/privacy readiness.** No CI workflows exist. Deletion/export/retention, release-device testing, live Firebase validation, accessibility breadth, monitoring, and operational recovery are not established by the local checks above.

See [EXISTING_FEATURES.md](EXISTING_FEATURES.md), [TECHNICAL_DEBT.md](TECHNICAL_DEBT.md), and [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md) for detailed status and sequencing.
