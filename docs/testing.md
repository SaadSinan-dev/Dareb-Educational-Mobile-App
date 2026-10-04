# Testing and validation

Run from the project root:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

Use the standard release command so Flutter regenerates registration for the correct build mode. Release currently uses the existing debug signing key; compilation does not establish production signing.

## Latest ordinary checks — 2026-10-04

`flutter pub get` completed; `flutter analyze` reported no issues; **227 ordinary tests passed** after cleanup and header extraction. **Debug and technical release APKs built successfully.** The non-mutating Android header device test passed; all eight Arabic/English root-tab captures were manually reviewed. The normal-mode release APK was reinstalled and cold-launched successfully; its logo, Arabic font and login controls rendered, with no fatal or unhandled startup errors. APK bundle inspection confirmed all 70 runtime assets and native branding resources.

## Scope

Ordinary tests use in-memory stores, mock HTTP adapters and sanitized fixtures, without live mutations. Coverage includes session lifecycle, owner isolation, response mapping, repeated multipart answer fields, retries, stale requests, validators, routing, responsive screens and dynamic artwork.

| Matrix | Verified scope |
| --- | --- |
| Portrait | 320, 360, 390, 430, 600 and 768 logical pixels. |
| Header | Four tabs; Arabic RTL/English LTR; safe areas; scales 1.0/1.5/2.0; long titles; 600 × 360 and 768 × 432 landscape. |
| Forms | Small widths and simulated keyboard insets. |
| Assets | Dynamic names, source-icon enum resources, PNG decoding, active font loading and license resources. |
| Platform | Android 15 emulator. Earlier dedicated live QA checked registration/profile, school selection, photo upload, secure sessions, assessments and attendance. Physical devices/iOS remain unverified. |

## Local visual review

```bash
flutter test tool/capture_visual_audit.dart --dart-define=APP_DEMO_MODE=true
```

Renders/metadata go to ignored `build/visual-audit/`. Optional defines: `AUDIT_WIDTHS`, `AUDIT_HEIGHT`, `AUDIT_TEXT_SCALE`, `AUDIT_PHASE`, `AUDIT_ROUTE_ONLY`. Captures use preview data and Flutter rendering; native system decoration is separate. No baseline corpus is required.

Earlier review covered 54 states across six portrait widths and 25 route states at two landscape sizes. Those historical outputs are not maintained documentation. Three representative preview images are retained in the README.

## Explicit live tests

Tests in `integration_test/` run separately on a selected device. Live tests require `LIVE_ACCOUNT_PHONE` or `LIVE_REGISTRATION_PHONE`, plus `LIVE_TEST_OTP`, supplied privately by the runner. Obtain the current code through the approved QA/backend process; never commit values or publish response bodies.

Registration creates an account; image/profile tests modify one. Use a dedicated QA account and approved environment. Some tests use isolated secure-storage keys, but the installed Flutter runner uninstalls the Android application after `flutter test` or a normal `flutter drive` run. This removes all of that package's app data, including its normal secure session. Use a dedicated disposable emulator/application ID for those runners. Backend errors/empty data are evidence, not client successes.

## Authentication persistence audit

See [the authentication/session audit](authentication-session-audit.md) for findings, changed files and measured results. Persistence checks must use `flutter run`, which stops the process while preserving the installation:

```bash
flutter run -d emulator-5554 --no-pub -t integration_test/session_audit_app.dart
```

This entry point runs the real application and adds a debug-only VM service probe. Log in using the existing QA account through the real Login/OTP screens. It neither creates an account nor injects credentials. Use the VM service HTTP URI printed by Flutter:

```bash
dart run tool/session_device_probe.dart <vm-service-uri> snapshot
dart run tool/session_device_probe.dart <vm-service-uri> profile
```

The probe returns only authentication/route status and boolean persistence/header checks. It never returns token values, phone numbers, OTPs or profile bodies. After login, `activation_persisted` must be true, the route must be `/home`, and `profile` must return `profile_loaded: true` and `bearer_verified: true`.

1. Press `r` for hot reload and `R` for hot restart; repeat the snapshot/profile checks after startup resolves.
2. Press `q`, verify the Android process stopped, rerun the same command, and repeat those checks. Stop and launch the installed app with ADB for process-recreation coverage; attach Flutter to obtain its new VM service URI.
3. Run the `network-failure` probe action; authentication and the persisted token must remain present. For cold-start coverage, launch with `--dart-define=SESSION_AUDIT_OFFLINE=true`; expect bootstrap `sessionError`, retained storage, and no Login/Register. Run `retry-network` to revalidate and reach Home.
4. Run `revoked` last. It performs backend logout and retries the actual revoked token, then expects unauthenticated state and empty storage. A standalone `logout` action is also available. Relaunch and verify `/login` with `persisted: false`.

Do not run `flutter test integration_test/session_relaunch_test.dart` against the installed QA account: the runner's cleanup uninstalls the app. That phased widget test can instead be launched with `flutter run -t integration_test/session_relaunch_test.dart`, or run on a disposable test installation.

## Header device captures

The non-mutating preview device test taps the real bottom tabs, compares header geometry in Arabic/English and checks notification detail navigation and return. It uses in-memory sample data, preserving the normal secure session.

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_header_test.dart -d <device-id> --dart-define=APP_DEMO_MODE=true
```

Eight screenshots are written to ignored `build/device-headers/` for manual review. Replace the device selector with one listed by `flutter devices`.
