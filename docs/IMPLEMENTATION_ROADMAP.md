# Implementation Roadmap

**Status date:** 2026-10-18. This is the forward-looking backlog; `docs/TASKS.md` remains the execution history and daily verification ledger.

## Phase 0 — Baseline and safe release foundations

- [x] Verify checkout, test/lint baselines, documentation gaps, content gate, and existing user changes.
- [x] Correct Android main manifest to declare INTERNET permission; still verify merged release manifest/build.
- [ ] Resolve Flutter lockfile deliberately with the supported Dart/Flutter SDK; avoid unrelated dependency downgrades.
- [ ] Establish CI for .NET and Flutter after confirming workflow permissions.

**Exit:** Checks are reproducible; release manifest merge is verified; CI gates tests, formatting, and dependency checks without secrets.

## Phase 1 — Parent authentication (P0)

1. Obtain authorization through the active package-install permission gate; add only `firebase_core` and `firebase_auth` from pub.dev.
2. Register/configure real Firebase platform apps and generate FlutterFire options outside committed secrets; enable email/password in the owner-controlled project. Do not fabricate options or tokens.
3. Implement optional bootstrap that detects absent options and shows an explicit configuration-required state; no protected shell or API call when unconfigured/signed out.
4. Add parent email/password registration, sign-in, sign-out, restored auth-state observation, safe errors, and a Firebase-backed `TokenProvider` using the current user's Firebase ID token.
5. On sign-out or UID change, clear/invalidate account-scoped Riverpod state. Add fake-driven tests for unconfigured startup, transitions, token retrieval, and no-token request refusal.
6. Align client Firebase project ID with backend `Firebase:ProjectId`; smoke-test only with a real project and non-production API environment.

**Exit:** No fake auth; protected requests carry only genuine Firebase ID tokens; signed-out/unconfigured requests remain blocked; automated tests pass; live auth results are reported separately from fake-based tests.

## Phase 2 — Family state and data lifecycle

- Persist active child selection paired with parent UID; restore only for matching UID and a current, non-archived child. Clear on logout/account switch/stale selection. **Partial (2026-10-21):** archiving the active child now selects the first remaining active profile or clears selection when none remain; persistent UID-scoped restoration still awaits parent auth.
- Define and implement account/child export, deletion, retention, and archive semantics; review applicable markets before beta.
- Add privacy-safe account-scoped caching only where justified.

**Exit:** No previous account data remains visible after identity transition; lifecycle paths have tests and truthful user-facing states.

## Phase 3 — Approved learning content

- Wait for explicit owner selection and approval of source terms in `docs/product/content-sources.md`.
- Separately verify rights for each recitation; document source/version/attribution/checksum and allowed update/offline path.
- Only then implement content index/player and license-compliant offline sync; test exact source integrity and network recovery.

**Exit:** Source/audio rights are approved and documented; no generated or silently normalized Quran text; tests prove content integrity.

## Phase 4 — Progress and durable offline learning

- Replace hard-coded dashboard values with backend-derived metrics.
- Add a durable, appropriately protected outbox for pending study events, stable idempotency keys, retry/backoff, and visible sync status.
- Implement tests, goals, achievements, and rewards only when content/session rules are defined and server-authoritative where needed.

**Exit:** Restart/network failure does not silently lose accepted work; metrics trace to persisted events; no unapproved content appears.

## Phase 5 — Controlled beta readiness

- Complete CI, dependency/secret scanning, security/privacy review, family ownership tests, accessibility checks, Android/iOS release builds, monitoring, backup/restore, and incident/rollback procedures.
- Configure Firebase/API/database environments using owner-managed secrets. Keep migrations separate, reviewed, and explicitly authorized.
- Complete market-specific legal/store review and closed-beta smoke tests before release publication.

**Exit:** Beta checklist is evidenced; no deployment, paid cloud creation, production migration, build publication, or store change without explicit authorization.
