# Authentication/session audit — 2026-10-04

## Scope and conclusion

The review traced normal Login, `POST auth/active`, `data.token`, secure persistence, fresh bootstrap, profile validation, routing, registration completion, logout, resume and Dio rejection handling. It also covered preview mode and the installed Android storage/test-runner implementations.

The activation token was already stored durably and its write was awaited before navigation. Loss of the Cubit does not itself lose the token. Five defects were reproduced with failing regression tests and corrected. Attribution of the user's particular intermittent incident remains unconfirmed without a successful live login/relaunch sequence or incident response evidence.

## Confirmed causes and fixes

| Defect | Previous behavior | Corrected behavior |
| --- | --- | --- |
| Profile classification | `profileCompleted()` returned false for any successful response whose `data` was not a map. Null, list, string or boolean data incorrectly resumed registration despite a saved token. | Unexpected response shapes throw a retryable failure and preserve the session. Registration resumes only for the existing explicit backend HTTP 400 “no branch” requirement. |
| Registration routing | `/register` remained a public route even for authenticated users, including restored platform/deep-link destinations. | Authenticated users visiting `/register` are redirected to authenticated Home. |
| Credential rejection races | Every authenticated-client 401 unconditionally deleted the current token; repository restoration also cleared it. Pending deletion and a later activation write could complete in the wrong order. | A rejected request carries its authorization into cleanup. Serialized storage operations compare the rejected token with the current token before deletion. Stale 401s cannot revoke a replacement token or reset its Cubit. |
| Android storage reset | The installed secure-storage package defaults `resetOnError` to true and can permanently erase its data following a storage/key error. | Production Android storage uses `resetOnError: false`; platform errors reach the startup retry path. |
| Preview isolation | Preview's authenticated API client still read normal-mode secure credentials and could clear them on HTTP 401. | Preview sends no normal token and cannot revoke the normal session. Preview profile/session preferences remain separate. |

No artificial delay, invented token, forced authenticated state or Home bypass was added to production code. Test tokens occur only in isolated ordinary-test fixtures. The live revocation probe uses the actual backend-revoked token.

## Token storage and lifecycle

| Item | Verified implementation |
| --- | --- |
| Credential model | `AuthSession(phone, token)`. `AuthUser` is presentation/local cache identity and contains no credential. |
| Durable session | `FlutterSecureStorage`, JSON `{"phone": ..., "token": ...}` under `tamkeen.auth.session.v1`. |
| Installation identity | Secure key `tamkeen.auth.installation_id.v1`; logout preserves it. It provides the device ID and stable local owner identity. |
| Android location | Package `com.example.tamkeen2`, app-private `/data/user/0/com.example.tamkeen2/shared_prefs/FlutterSecureStorage.xml`, encrypted by the installed plugin with Android KeyStore-protected key material. Storage filenames were observed on the emulator without printing values. |
| Other platforms | The same logical key goes through platform secure storage; iOS uses Keychain. This audit does not claim live iOS, desktop or web persistence results. |
| Write | `LiveAuthRepository._activate()` extracts only `auth/active` → `data.token`, validates it, and awaits `saveSession()` before returning to the Cubit. Registration retains this credential and confirms completion using `profile/get`. |
| Load | `AuthCubit.restore()` → `LiveAuthRepository.restoreSession()` → the same singleton `AuthSessionStore.readSession()`, on every fresh bootstrap. The interceptor separately awaits a fresh read before each authenticated request. |
| Header | `Authorization: Bearer <persisted token>`. No token is hardcoded in application code. Diagnostics omit values, authorization, OTPs and bodies. |
| Removal | Explicit logout, successful account deletion, malformed/unusable stored JSON, or HTTP 401 for the current token. Empty/whitespace token writes are rejected. Read/platform/network/server failures do not clear a valid credential. |

The installed Android plugin writes encrypted preferences using Android `SharedPreferences.apply()`. Awaiting its platform call establishes API completion, but abrupt power loss before Android flushes disk is not established by ordinary tests. Stopping Flutter, hot restart and Android lifecycle/process restoration still require the real-device matrix below. Uninstalling the application is a different operation that deletes its app data.

## Startup and session resolution

1. `main()` initializes Flutter bindings and registers dependencies before running `LearningApp`.
2. `LearningApp` starts `AppBootstrapCubit`; appearance and authentication restoration run concurrently while only the initializing screen exists.
3. The auth repository reads the durable token and validates it using authenticated `GET profile/get`; it does not rely solely on token existence or assume the opaque token is a JWT.
4. Bootstrap creates the router only after resolution. A completed account follows `Initializing → Authenticated → /home`. No token or a confirmed current-token 401 follows `Initializing → Unauthenticated → /login`.
5. Temporary errors follow `Initializing → sessionError`, retaining storage and offering Retry. Resume failures retain the authenticated destination and expose the error. An explicit backend profile-completion requirement resumes `/register`; discarded Cubit state never makes that decision.

HTTP 403, 429, timeouts, connection errors, TLS errors, server failures and malformed profile responses are not treated as token expiry. Only HTTP 401 confirms rejection under the observed API contract. A revoked token must be confirmed against the backend rather than inferred from its string format.

`AppSessionCoordinator` clears owner-scoped feature caches on actual session/owner changes. It does not delete credentials on widget disposal, app shutdown or startup. Registration's back action explicitly logs out only a pending registration, and successful registration returns a completed user after backend confirmation.

## Changes

- Production: `lib/features/auth/data/auth_session_store.dart`, `lib/features/auth/data/live_auth_repository.dart`, `lib/features/auth/data/postman_auth_data_source.dart`, `lib/core/network/api_client.dart`, `lib/core/di/service_locator.dart`, `lib/core/router/app_router.dart`.
- Ordinary regressions and compatible doubles: `test/auth_session_store_test.dart`, `test/auth_storage_failure_test.dart`, `test/live_auth_repository_test.dart`, `test/network_boundary_test.dart`, `test/app_integration_test.dart`, `test/auth_navigation_test.dart`.
- Device coverage/tooling: `integration_test/startup_session_test.dart`, `integration_test/session_relaunch_test.dart`, `integration_test/session_audit_app.dart`, `tool/session_device_probe.dart`.
- Documentation: this report, `docs/architecture.md`, `docs/testing.md`.

The Cubit, bootstrap and production app entry point were audited and retain their existing restoration gate. The existing isolated startup test rebuilds widgets; that alone is not evidence of process restart. The new VM probe runs the actual app bootstrap under `flutter run` without overriding session storage.

## Measured validation

| Check | Result |
| --- | --- |
| Failing regressions before fixes | Malformed profile → registration, authenticated `/register`, stale 401 deletion, Android automatic reset, pending delete/write race, and preview reading a normal token were reproduced. |
| Focused storage/network/repository suite | 68 tests passed after serial/conditional cleanup; preview-isolation regression separately passed. |
| Ordinary full suite | Final run including the subsequent UI regressions: 251 tests passed. |
| `flutter analyze` | Final run: no issues found. |
| Real durable read | Production secure session existed on the Android 15 emulator; read-only probe returned `persisted: true` without exposing credentials. This does not prove the token was accepted by the backend. |
| Device runner cleanup | The installed Flutter SDK's `IntegrationTestTestDevice.kill()` uninstalls the package after `flutter test`; its normal drive cleanup also uninstalls. The read-only probe was followed by that cleanup, which removed the original saved session. The subsequent restore attempt correctly reported no token and did not exercise valid-session restoration. |
| Actual normal app startup | Normal debug app launches to `/login` with `persisted: false`, resolved unauthenticated bootstrap and no client error after the runner removed its app data. |
| Real QA login and activation persistence | Manual normal Login/OTP completed on the emulator. Probe reported authenticated `/home`, persisted token, and `activation_persisted: true`, confirming the actual activation token equals the durable token. No credentials were guessed and no account was registered during this audit. |
| Stop debug / relaunch / Home | Passed: quit with `q`, started a fresh `flutter run` using the actual app bootstrap, awaited resolution and observed persisted token, authenticated bootstrap, `/home`, two successful profile responses and matching bearer. No app uninstall/data-clear occurred in this sequence. |
| Hot reload / hot restart / Home | Actual `R` hot restart passed: authenticated bootstrap, persisted token, `/home`, two successful profile responses and matching bearer header. Reload was exercised before the observed login; authenticated reload is not separately certified. |
| Android process recreation / Home | Pending real QA login. Not reported as passing. |
| Real backend Profile and bearer check | Passed: successful authenticated `GET profile/get` responses and matching durable-token bearer during Login/restarts, followed by a successful real AccountRepository load, `profile_loaded: true` and `/profile`. An earlier transient request failure preserved the session; retry succeeded. |
| Logout / relaunch | Ordinary tests verify durable removal and guarded Login; live backend/device sequence pending QA login. |
| Invalid/expired token | Ordinary tests verify current-token 401 removal and startup Login. The live probe can test the actual token after backend logout; not yet run. |
| Temporary network failure | Actual authenticated resume probe passed: injected connection failure retained authenticated state and persisted token (`token_preserved: true`) and exposed a session error. Cold offline-startup remains covered by ordinary tests, not certified by a completed live test. |

The normal Login → stop debug → relaunch → authenticated Home sequence passed on the Android emulator. Process-recreation, live logout/relaunch and live revoked-token sequences remain uncertified; their ordinary regressions are not a substitute for those outstanding device checks.
