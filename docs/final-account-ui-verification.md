# Final account UI verification

## Changes

- `lib/features/faq/presentation/screens/faq_page.dart`: live and preview FAQ now use `PageLayout`, which composes the existing course/material `AppHeader`. Loading, retry, expansion and backend content remain unchanged.
- `lib/features/content/presentation/screens/policy_page.dart`: Privacy uses the same `PageLayout`/`AppHeader`, with its existing CMS content. Terms retains its existing layout.
- `lib/features/profile/presentation/widgets/account_summary.dart`: displayed avatar always uses `assets/images/avatar.png`, at its supplied 190 × 166 dimensions with `BoxFit.contain`. Removing the extra oval crop preserves the illustration's circle, shadow and protruding book. Backend name/statistics and photo-upload callback remain intact; the backend image URL is no longer used for this display.
- `test/account_widgets_test.dart`: avatar source, dimensions, fit, absence of oval clipping, backend name and tap callback regression.
- `test/final_account_ui_test.dart`: shared header geometry, localized back placement, actual back navigation, privacy content and profile rendering across Arabic/English, live/preview and widths 320, 430, 768 and 1024.

The shared header implementation is unchanged. `lib/core/widgets/app_header.dart` remains the single source of truth for these screens and course/material screens. Existing safe-area behavior, centered title, primary background, corner radius, typography, icon allocation and maximum 768-pixel content width are reused, not copied.

## Reference and comparison

The original supplied `Profile Page.png` was found in the educational-app export archive in Downloads. `docs/asset-provenance.json` identifies the bundled avatar's extraction from that exact reference: x=122, y=169, width=190, height=166 at reference width 430. The existing asset is reused without replacement or editing. Its built-in outline and shadow provide the shape; an additional circular clip would incorrectly cut off the book.

Rendered screenshots are in ignored `build/ui-final/`: `course-`, `faq-`, `privacy-` and `profile-` for both locales and all four widths. Generate them with:

```powershell
flutter test --no-pub test/final_account_ui_test.dart --dart-define=UI_CAPTURE=true
```

Header rectangles match the course layout exactly at every tested size and direction. RTL leading action appears on the right; LTR on the left. Back actions return to the previous route. The shared header's intentional single-line ellipsis remains in place for long titles at small widths; there is no render overflow. Avatar source, dimensions and complete crop match the supplied asset. The profile card remains centered and responsive, with its existing positioning transform retained.

## Validation

- Focused header/account/live-content tests: 19 passed.
- Screenshot matrix: passed; Arabic RTL and English LTR, widths 320/430/768/1024, live and preview. No framework overflow exceptions.
- Existing responsive root-header tests additionally cover 320–768 widths, short landscape and text scales 1/1.5/2; existing route tests cover rotation and larger text.
- `flutter analyze --no-pub`: no issues found.
- `flutter test --no-pub`: 251 tests passed.
- `flutter build apk --debug --no-pub`: succeeded, `build/app/outputs/flutter-apk/app-debug.apk`.

Backend integration is covered with deterministic repositories in widget tests. The Android emulator also successfully loaded the real authenticated account, opened `/profile`, and displayed the supplied avatar alongside the backend name/statistics; the screenshot is `build/ui-final/profile-device.png`. This is not a claim that every backend endpoint succeeded on the emulator.
