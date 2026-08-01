# Auth UI Redesign — Login & Register Screens

## Context

`LoginScreen` and `RegisterScreen` (built in Tasks 10–11 of the foundation plan) are
functional but use bare default Material widgets (plain `AppBar`, unstyled `TextField`s,
default `ElevatedButton`). This spec redesigns their visual presentation to match the
layout language of TikTok's real login/register screens (reference screenshots:
`IMG_1361.PNG`, `IMG_1362.PNG`, `IMG_1363.PNG`), adapted to this app's existing dark
theme and email/password-only auth contract.

## Goals

- Give both screens a TikTok-style visual treatment: bold left-aligned title, pill-shaped
  filled inputs, full-width pill submit button, two-tone footer link.
- Keep the app's dark theme (`AppTheme.dark`) — do not introduce a light theme for these
  screens.
- Zero behavior change: same fields, same validation (none beyond what exists today),
  same provider calls, same navigation.

## Non-goals

- No phone-number sign-in, no Facebook/Apple/Google buttons. The backend
  (`AuthRepository.login`/`register`) only supports email + password — adding UI for
  unsupported auth methods would be dead/disabled UI, which this spec explicitly avoids.
- No multi-step flow (choice screen → detail screen) as seen in the reference screenshots.
  Both screens keep their current single-form structure.
- No new files, no new dependencies, no new widget keys.

## Design

### Shared visual language

Both screens reuse `Theme.of(context).colorScheme` tokens instead of hardcoded colors,
so they automatically track `AppTheme.dark`'s seeded TikTok-red primary
(`Color(0xFFFE2C55)`):

- **Title:** `Theme.of(context).textTheme.headlineMedium` with `FontWeight.bold`,
  left-aligned, top padding ~24.
- **Inputs:** `TextField` with a filled, borderless, rounded decoration
  (`filled: true`, `fillColor: colorScheme.surfaceContainerHighest`,
  `border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)`),
  label shown as hint text inside the field.
- **Submit button:** full-width `ElevatedButton` styled with
  `ButtonStyle(shape: StadiumBorder(), backgroundColor: colorScheme.primary, minimumSize: Size(double.infinity, 52))`.
  Same disabled-while-loading / spinner behavior as today, just restyled.
- **Error text:** unchanged position/condition (`authState.hasError`), same red text,
  only spacing adjusted to fit the new layout.
- **Footer link:** a `RichText`/`Text.rich` combining plain text and a `TextSpan` styled
  with `colorScheme.primary` for the actionable phrase, tappable via
  `TapGestureRecognizer` (or kept as the existing `TextButton` if simpler — visual parity
  matters more than the exact widget type).

### `LoginScreen`

- Title: "Log in to TikTok".
- Fields (unchanged keys): `login_email_field`, `login_password_field`.
- Submit button (unchanged key): `login_submit_button`, label "Log in".
- Footer: "Don't have an account? **Register**" → tapping the bold part still calls
  `context.go('/register')`.

### `RegisterScreen`

- Title: "Sign up for TikTok".
- Fields (unchanged keys): `register_username_field`, `register_email_field`,
  `register_password_field`.
- Submit button (unchanged key): `register_submit_button`, label "Register".
- No footer link change needed (none exists today; out of scope to add one).

## Testing

No new tests. This is a pure presentation-layer restyle — no new logic branches, no new
widget keys, no behavior change. Existing tests act as the regression check:

- `test/features/auth/presentation/login_screen_test.dart`
- `test/features/auth/presentation/register_screen_test.dart`
- `test/core/router/app_router_test.dart` (navigates through `LoginScreen`)

All must continue passing unmodified. `flutter analyze` must stay clean.

## Out of scope / future work

- Phone-number and OAuth sign-in, once the backend contract supports them.
- Localizing screen copy to Vietnamese (kept English to match the rest of the app).
