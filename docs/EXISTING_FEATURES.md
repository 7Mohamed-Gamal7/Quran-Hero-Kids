# Existing Features and Current Status

**As of:** 2026-10-22

Statuses describe implementation in this checkout—not planned architecture or release readiness.

| Area | Status | Evidence and boundary |
|---|---|---|
| Parent identity in backend | **Implemented, live config absent** | `backend/src/QuranHero.Api/Auth/FirebaseAuthenticationExtensions.cs` validates Firebase JWT authority/issuer/audience/lifetime when configured; otherwise auth fails closed. |
| Family ownership | **Implemented** | `ChildrenController` and `StudySessionsController` derive owner UID from verified claims; application services scope reads/writes by owner. Integration tests use test-only auth, not real Firebase-signed tokens. |
| Parent Firebase client auth | **Absent** | No FlutterFire initialization, registration/sign-in/sign-out UI, restored session gate, or Firebase-backed `TokenProvider`. Firebase platform options are absent. |
| Protected API client | **Implemented, fail-closed** | `mobile/lib/src/core/network/api_client.dart` refuses a missing API URL or token; provider wiring currently returns `MissingTokenProvider`. |
| Child profiles | **Implemented** | Flutter screens/repository and authenticated API support list/create/edit/archive. No separate child account exists. |
| Active child selection | **Partial** | Shared in-memory selection is used by family and learning/session flows; archiving the selected child falls back to another active profile or clears the selection, and starting a session on the default profile records it as active. Not persisted or scoped to parent identity across restart. |
| Study session capture/history | **Implemented, network-dependent** | Timer, session kind/duration, stable UUID event ID, history, and retry with the same payload are present. Retry drafts remain screen-memory-only. |
| Offline delivery | **Absent** | No durable outbox, background sync, retry-backoff queue, or conflict UI. |
| Dashboard progress | **Placeholder / partial** | Home shows hard-coded zero progress and prototype child naming; not derived from backend session history. |
| Quran text/audio | **Blocked / absent** | `docs/product/content-sources.md` records no owner approval. No source integration or bundled text/audio exists. |
| Tests and achievements | **Placeholder** | Screens state activities are not enabled without approved content and persisted progress. |
| Production migrations | **Separate procedure implemented** | API does not auto-apply production migrations; reviewed SQL is a separate operations step. No production database was accessed. |
| Android Internet permission | **Source manifest fixed in audit slice** | Main manifest previously omitted `INTERNET`; debug/profile manifests included it. Release merged-manifest/build verification remains pending. |
| Continuous integration | **Absent in checkout** | `.github/workflows/` does not exist; `.github` has a pull request template. |
| Privacy deletion/export | **Policy/design only** | Security docs call for deletion/export and retention; no end-to-end implementation is evidenced. |
