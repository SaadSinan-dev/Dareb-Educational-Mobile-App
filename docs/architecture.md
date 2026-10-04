# Application architecture

Independent features own domain contracts, data adapters and presentation Cubits; related account-backed views share the typed `account` facade intentionally. Screens render typed state and bind callbacks. Transport parsing and raw responses remain in the data layer.

| Owner | Responsibility |
| --- | --- |
| `application` | Bootstrap gates router creation until preferences/session restoration finish. Session coordination resets feature state on authenticated owner changes. |
| `auth` | Secure sessions, verification/activation, registration draft, reference lookups, profile completion and auth state. |
| `courses`, `home`, `search` | Catalog/subject models, owner-scoped preview progress, home overview and debounced search with separate lifecycles. |
| `lessons`, `assessments`, `history` | Media/comment/attendance state, typed questions/results and independent exam/activity history. |
| `account` and supporting features | Profile/account adapter and state; focused profile, settings, content, gallery, FAQ, contact, subscription, notification and achievement composition. |

## Request boundaries

```text
Screen → Cubit → domain capability → repository/data adapter → ApiClient → REST API
```

GetIt wiring is centralized in `lib/core/di/service_locator.dart`. App/route composition supplies Cubits and narrow capabilities. Adapters map nullable/nested fields into typed models; presentation does not own JSON schemas.

Request generations and closed-state checks reject stale completions. Search debounce belongs to SearchCubit. Contact submission has independent operation state. Immutable collections prevent callers from changing shared state accidentally.

Attendance retry retains the confirmed write and retries a failed follow-up. Assessment submission is not repeated after confirmation or while another submission is pending. New assessments reset answers and confirmation state.

## Session and configuration

Normal mode uses the backend. `AuthSessionStore` persists the activation token and submitted phone as JSON under `tamkeen.auth.session.v1` in secure platform storage; preferences are separate. Activation awaits the write before authenticated state is emitted. Session reads, writes and removals are serialized; HTTP 401 cleanup removes only the token used by the rejected request. Android storage errors propagate to retry without automatically resetting credentials.

Bootstrap resolves `GET profile/get` before creating the router. A successful profile response opens Home, an explicit backend profile-completion requirement resumes registration, and missing/rejected credentials open Login. Temporary network, server, storage and malformed-response errors retain credentials and show a startup retry screen. Resume checks preserve the existing authenticated destination during temporary failures. Authenticated users cannot return to the registration route, and preview requests cannot read or revoke normal-mode credentials.

`AppConfig` owns the non-secret API address and explicit preview define. Product builds cannot enable preview repositories. Preview entitlements/progress are owner-scoped and do not become normal-mode access decisions.

## Navigation and shared UI

`StatefulShellRoute.indexedStack` owns the four root tabs. Selection uses `goBranch`; details use GoRouter. Back from a secondary root tab returns Home. Auth redirects are independent of tab selection.

`core/widgets/app_header.dart` contains `AppHeader` and its notification artwork. It receives title/leading/actions and owns layout only. `PageLayout` owns safe-area/page composition and existing routing callbacks. Root catalogs preserve their header through loading/errors; Gallery and Profile place their scrollable bodies below it. Home preview welcome content is a feature widget, not a second header.

Theme files own typography, spacing, colors, radii and controls. ARB files own product copy; unknown server content is displayed as returned.

Each root route has its own `ScaffoldMessenger`, so messages attach to the visible tab rather than the shell or hidden tabs. Profile modal routes use non-opaque GoRouter pages and a dim barrier; each modal also owns a message scope. Navigation still changes the indexed branch or pushes an existing GoRouter detail route.

`AppTheme.lightFor` / `darkFor` select bundled Noto Sans Arabic or Roboto from the saved locale. Text roles inherit their font family; screen-specific sizes and weights retain the design tokens.

The gallery adapter retains embedded remote image URLs from `galleries/all`. Album details reload that documented endpoint and select the album by ID, because the supplied collection has no separate detail endpoint. Remote media uses ordinary image requests without bearer headers; image load failures expose retry instead of local artwork. Privacy always reads `pages/privacy-policy`, including preview builds; CMS content is converted to inert selectable text, with empty/error/retry states.
