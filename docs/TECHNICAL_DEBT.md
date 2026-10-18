# Technical Debt and Blockers

**As of:** 2026-10-18 · Priorities are relative to a controlled beta and do not imply release approval.

| Priority | Finding | Impact | Evidence / prerequisite |
|---|---|---|---|
| P0 | Flutter client has no Firebase Auth integration | Parent cannot obtain a genuine Firebase ID token; protected calls correctly fail closed. | `mobile/lib/src/core/auth/token_provider.dart`, `network_providers.dart`, `api_client.dart`; pub.dev package install currently blocked by tool permission. |
| P0 | No real Firebase client configuration or live test environment | Cannot verify generated options, email/password provider, token issuer/audience alignment, or end-to-end API behavior. | No generated options/platform files found; requires owner-controlled project configuration and API environment. |
| P0 | Firebase project ID must match backend configuration | Mismatch causes valid client sessions to fail API authorization. | Backend reads `Firebase:ProjectId` in auth and non-development startup validation. |
| P1 | Active child is in-memory and not owner-keyed | Selection is lost after restart; future persisted/cache state could bleed across parent changes unless scoped. | `activeChildIdProvider`; auth state must exist before safe UID-bound restoration. |
| P1 | Study session retry is not durable | Process termination loses an unsent draft; no offline guarantee exists. | `study_session_screen.dart`; outbox needs retention/encryption decisions. |
| P1 | Quran content is not approved or integrated | Learning screens cannot offer real surah/ayah/audio content. | `docs/product/content-sources.md`; owner approval and rights review are mandatory. |
| P1 | Delete/export/retention is not executable | Families lack a verified lifecycle path for child/account data. | `docs/architecture/security.md`, `docs/architecture/data-model.md`; requires policy, market/legal review, and implementation. |
| P1 | Release manifest networking needed explicit declaration | Release API/Firebase traffic may be unavailable without INTERNET in the merged app manifest. | `mobile/android/app/src/main/AndroidManifest.xml` now declares INTERNET; next Android release build must verify merge. |
| P2 | Home progress and child name are prototype values | UI can imply account-specific progress where none is persisted or derived. | `mobile/lib/src/screens.dart`; replace when backed metrics and account data are available. |
| P2 | No CI workflow is present | Formatting, tests, dependency checks, and builds are not automatically gated. | No `.github/workflows/`; confirm workflow permissions/configuration before adding workflows. |
| P2 | Flutter lockfile drift from local SDK | Modified lockfile downgraded transitive versions and changed committed Dart >=3.11 floor to local resolution >=3.8. | `mobile/pubspec.lock`; preserve until deliberate resolution with compatible SDK and authorized Firebase dependencies. |
| P2 | Backend auth tests do not verify Firebase signatures | Tests prove authorization/ownership with synthetic test identity, not Firebase signature/issuer verification. | `backend/tests/QuranHero.Api.Tests/Infrastructure/IntegrationTestFactory.cs`; live verification is an external gate. |
| P2 | Accessibility and release-device breadth not established | Current tests do not establish full screen-reader, scaling, platform, or device coverage. | Targeted accessibility and release checks remain before beta; local tests are not device certification. |
