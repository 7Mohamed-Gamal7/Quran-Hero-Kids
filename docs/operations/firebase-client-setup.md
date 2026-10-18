# Firebase Client Setup — Parent Email/Password Auth

This guide describes prerequisites for the Flutter client. It contains no project IDs, API keys, or credentials. Do not commit service-account material or private credentials.

## Current state

As of 2026-10-18, Firebase client auth is **not implemented** in Flutter. The `TokenProvider` is deliberately missing-token, and the API client refuses protected calls without a non-empty ID token. No generated FlutterFire options or Firebase platform app configuration were found. Firebase package installation was blocked by the active tool permission gate; do not infer that conversational approval overrode that decision.

## Owner-controlled setup prerequisites

1. Obtain authorization through the active package-install permission gate, then add `firebase_core` and `firebase_auth` from pub.dev. Review the lockfile using a compatible Flutter/Dart SDK.
2. In the owner-controlled Firebase project, register the Android app (`com.quranherokids.quran_hero_kids`) and iOS app (expected bundle identifier `com.quranherokids.quranHeroKids`; verify the Xcode project before registration).
3. Enable Email/Password in Firebase Authentication. Do not enable anonymous auth as a fallback.
4. Generate FlutterFire platform options using the official configuration workflow. Keep generated config files untracked unless the owner explicitly chooses a safe public-client config policy; never commit service-account keys or private credentials.
5. Configure backend `Firebase:ProjectId` to the same Firebase project. Non-development backend startup already requires this setting and a database connection string.
6. Supply a non-production API URL for smoke testing. Do not use production credentials/data or run production migrations for local tests.

## Required client behavior when implemented

- Check for generated Firebase options before initialization. Missing configuration must show a setup-required state and must not enter protected family screens.
- Use Firebase email/password registration, sign-in, sign-out, and restored auth-state events; deliver the current user's ID token through the existing `TokenProvider` boundary.
- Do not persist ID tokens manually, log tokens/passwords/email, create fake tokens, or call protected endpoints if auth is absent.
- Clear account-scoped client state on sign-out and UID change.

## Smoke-test checklist (requires owner configuration)

- Fresh unconfigured build displays setup-required state and sends no protected API request.
- Register/sign in with a non-production parent account; verify auth restoration after restart.
- Confirm the API request has a Firebase-issued Bearer ID token and backend issuer/audience project matches. Never paste the token into logs or source control.
- Sign out; confirm child/session state is cleared and a protected API request is blocked.
- Switch to a second test parent; confirm no first-parent child/session state is visible.
- Record device/OS, app version, backend environment, and pass/fail outcomes without storing credentials or personal data.

No live Firebase or API smoke test has been performed as part of this audit.
