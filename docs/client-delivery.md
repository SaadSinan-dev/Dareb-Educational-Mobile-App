# Client testing delivery — 2026-10-05

## Artifact and signing

- Build: `flutter build apk --release`, default `lib/main.dart`, normal backend mode. No demo defines, fake sessions or test entry points.
- Delivery artifact: `build/delivery/Dareb-client.apk`, excluded from Git.
- Version: 1.0.0 (1); application ID: `com.example.tamkeen2`.
- Size: 59,436,917 bytes (56.68 MiB).
- SHA-256: `1b406947bfabcb029792a5e2503d594560a447dc9c5d056bfacc99cd39828bbb`.
- APK signature verification passed. Signer: Android Debug; release compilation is non-debuggable. The existing Gradle configuration deliberately signs release with the local debug key.

This is an installable technical release for client testing, **not production-store-ready**. A privately managed production/upload keystore and an appropriate release signing configuration are required for store delivery; neither was created or committed. Rebuilding with another machine's debug key can change the signer and prevent an in-place upgrade. Preserve the key privately when distributing follow-up test builds.

## Repository

The intended existing remote is `https://github.com/SaadSinan-dev/Dareb-Educational-Mobile-App`; the delivery branch is `main`. The original push failure was reproduced: `main` had no upstream. The remote initially had no refs or commits; the upstream-configured dry run succeeded without changing the remote or rewriting history.

Tracked application/configuration/assets/tests/documentation total approximately 4.12 MiB, with no file exceeding 1 MiB. Generated builds, APKs, SDK/IDE metadata, caches, logs, local environments and signing material were already untracked/ignored. Ignore coverage was extended to temporary archives. Tracked credential-pattern scans found no actual API tokens, private keys or private credentials. Only repository metadata/documentation changed during delivery; application code and design were not modified.

## Validation

| Check | Result |
| --- | --- |
| `flutter pub get` | Passed; lockfile unchanged. |
| `flutter analyze` | No issues found. |
| `flutter test` | 253 tests passed. |
| `flutter build apk --release` | Passed; 122.5-second build. |
| APK verification/install | Signature verified; installed successfully on Android 15 emulator, with ARM64/ARMv7/x86_64 native libraries. |
| Launch and retained session | Passed: installed release recognized the existing QA session and opened authenticated Home. |
| Close/reopen restoration | Passed: force-stopped the release process and relaunched; authenticated Home returned without Login or registration. |
| Home/API/materials swipe | Passed: real backend material names displayed; an actual horizontal touch swipe moved the row and revealed Mathematics/Biology. |
| Gallery | Album list/detail loaded; sampled albums contain zero images. Image zoom could not be exercised with that server data. |
| Profile | Real account profile loaded with the bundled design avatar. |
| FAQ | Authenticated question/answer list loaded successfully. |
| Privacy | CMS value rendered; independent `GET /pages/privacy-policy` returned HTTP 200. The current CMS value contains only the policy title, not a full policy. |
| Arabic/English | Switched to English LTR in the installed release, checked translated UI/leading positions, then restored Arabic RTL. |
| Course/lesson | Opened a real six-lesson course and document lesson; document URL and discussion/attendance controls rendered. |
| Exam | Sampled quiz lesson reports: “This lesson has no exam questions in the server response.” It is not reported as successful exam completion. |
| Exam/activity history | Both tabs loaded the real backend empty state, “No records yet.” No assessment/activity submission was performed. |
| Video | Sampled lesson-detail responses rendered document resources. End-to-end video playback was not verified; historical resolver HTTP 500 results remain documented in the README and are not claimed as a new release measurement. |
| Logout/relaunch | Passed: confirmed logout, stopped/relaunched the app, and verified Login/phone input with no authenticated Home. |
| Fresh release Login/OTP | Awaiting manual QA entry on the emulator; phone/OTP are not captured, hardcoded or committed. |
| Fresh registration | Not repeated on the already-registered QA account; automated registration tests pass. No extra backend account was created for delivery. |

An unauthenticated diagnostic `GET /faqs/all` returned HTTP 401, as expected for a protected endpoint; the installed app's authenticated FAQ request succeeded. Empty data or unavailable backend content was not replaced with preview data, and no application behavior was changed to hide smoke-test limitations. Physical devices and iOS were not tested.

## Rebuild and handoff

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
New-Item -ItemType Directory -Path build/delivery -Force
Copy-Item build/app/outputs/flutter-apk/app-release.apk build/delivery/Dareb-client.apk
Get-FileHash build/delivery/Dareb-client.apk -Algorithm SHA256
```

Distribute the APK privately for client testing. Keep generated APKs and private QA evidence outside Git; screenshots/UI dumps are intentionally not published with the source.
