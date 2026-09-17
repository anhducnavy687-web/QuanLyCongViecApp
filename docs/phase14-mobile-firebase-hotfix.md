# Phase 1.4 mobile Web initialization hotfix

## Baseline and reproduction

- Baseline: `621ff2e5f250d155b74824a549c34560a5bdafb7`, fetched from
  `origin/claude/stoic-goldberg-qcky72`.
- GitHub Pages deployment succeeded:
  https://github.com/anhducnavy687-web/QuanLyCongViecApp/actions/runs/35191685874
- Worktree starts at that commit on `phase14-mobile-firebase-hotfix`.
- Reproduced on production using Playwright WebKit 26.5 with a new browser
  context: the exact reported generic initialization error is displayed,
  `window.firebase_core` remains undefined and there are no Firebase JS SDK
  requests. This is a desktop WebKit reproduction, not a physical iPhone test.

## Root cause and execution path

`FirebaseAuthService._initializeFirebase` evaluates `Firebase.apps.isEmpty`
before calling `Firebase.initializeApp`. In resolved `firebase_core_web 2.24.1`,
`apps` calls `firebase_core.getApps()` before the JavaScript module is loaded.
Its catch only recognizes the text `of undefined` in the exception/stack.
Chromium's undefined-property message matches; WebKit reports
`undefined is not an object (evaluating 'window.firebase_core.getApps')`,
which was directly reproduced. WebKit therefore rethrows before the SDK loader
runs. The service catches that non-Firebase error and uses the generic message.

This explains the Windows/WebKit difference without assuming a network timeout.
The production core timeout is 8 seconds, not 12. Session restoration also has
an 8-second timeout, in `restoreSession`, after initialization. A TimeoutException
already maps to a different message, so it does not explain this observed text.
The production catch is `catch (e)`, not `catch (_)`, but it did not log details.

## Fix

- Call `Firebase.initializeApp` directly with the unchanged Web options. The
  resolved SDK already reuses the default app with matching options. Never query
  `Firebase.apps` before loading the SDK.
- Retain one in-flight initialization Future. The existing 8-second duration is
  now a UI waiting budget, not a failure/cancellation of the underlying operation.
  After it expires, Login/Demo remain reachable; Retry joins the pending operation.
  A late success becomes available; a real failure releases the operation for retry.
- Do not increase the duration or change Google popup/native sign-in behavior.
- Log initialization/restore stage and Firebase plugin/code/message in debug only;
  redact common tokens, API keys, credentials, emails and request URLs.
- Map timeout, network, configuration, unsupported/unauthorized and unknown errors
  to friendly UI messages without exposing raw exceptions.

The legacy SDK's dynamic-import rejection is not wired to its Dart Completer.
A blocked SDK download can therefore remain pending. The UI explicitly asks the
user to check network/content blocking and reload if Retry cannot recover. The
hotfix does not spawn duplicate initialization attempts to work around that SDK
behavior. A cold reload is needed for a permanently rejected browser module load.

## Compatibility and deployment checks

- Flutter 3.47.4 / Dart 3.13.3 matches the Pages workflow.
- Resolved firebase_core 3.15.2, firebase_auth 5.7.0,
  firebase_core_web 2.24.1 and firebase_auth_web 5.15.3 are unchanged.
- This Core Web version loads Firebase JS 11.9.1. Auth's registered initialization
  callback waits for its initial auth state as part of Core initialization.
- `DefaultFirebaseOptions.web` is correct for Flutter Web on iPhone;
  `currentPlatform` also returns `web` there. Native iOS options are not selected.
- Production response has no CSP header; HTML has no CSP meta policy.
- Release artifact has `<base href="/QuanLyCongViecApp/">`.
- Failure reproduces in a fresh context, so an old service worker is not required.
  Existing users can still have cached assets; physical-device retest must load
  the approved deployment. No service worker/cache configuration was changed.
- A separately reported FlutterFire WebKit dynamic-import race exists, but this
  observed failure occurs before any imports. No speculative SDK upgrades,
  Firebase Console edits, project changes or Storage activation were made.

## Validation

- `flutter pub get`: pass. On Windows, process-local `FLUTTER_WINDOWS=false`
  avoids desktop plugin symlinks for this Web-only validation. A temporary SDK
  junction without spaces avoids a Windows native-hook path parsing issue.
- `flutter analyze`: no issues.
- `flutter test`: 114 tests pass (6 new regression tests).
- `flutter build web --release --base-href "/QuanLyCongViecApp/" --no-web-resources-cdn`: pass.
- `node tool/firebase_web_smoke.cjs`: WebKit cold start and a 10-second SDK
  download delay plus Retry pass; exactly one default app exists in both cases.
  The harness uses a fresh context per case and performs no login or data writes.
  Set `PLAYWRIGHT_MODULE` to an existing Playwright installation if needed and
  install its WebKit runtime (optionally under `PLAYWRIGHT_BROWSERS_PATH`).
- Unit regressions cover the unsafe pre-init getter, app reuse after an Auth
  initialization failure, concurrent calls, slow initialization, late failure,
  successful retry, session restoration timeout/retry, error mapping and redaction.

No physical iPhone success is claimed. Before production approval, this remains
an uncommitted local hotfix. After an approved deployment, verify cold launch,
slow-network Retry and Google sign-in on the user's actual iPhone.
