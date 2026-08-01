# Auth UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle `LoginScreen` and `RegisterScreen` to a TikTok-style visual treatment (bold title, pill inputs, pill submit button, two-tone footer link) on the app's existing dark theme, with zero behavior change.

**Architecture:** Pure presentation-layer edits to two existing files. No new files, no new dependencies, no new widget keys, no provider/logic changes.

**Tech Stack:** Flutter Material widgets only (`TextField`, `ElevatedButton`, `Text.rich`/`TextSpan`, `Theme.of(context).colorScheme`). `flutter/gestures.dart` for `TapGestureRecognizer` on the footer link.

## Global Constraints

- Do not change any existing `Key` values (`login_email_field`, `login_password_field`, `login_submit_button`, `register_username_field`, `register_email_field`, `register_password_field`, `register_submit_button`) — existing tests depend on them.
- Do not change `AuthState`/`AuthRepository` calls or their parameter names/order.
- Reuse `Theme.of(context).colorScheme` tokens (backed by `AppTheme.dark`'s seeded `Color(0xFFFE2C55)` primary) instead of hardcoded hex colors.
- Keep screen copy in English (matches rest of app; source design screenshots are Vietnamese but only their layout/style is being adopted, not their copy).
- No phone-number or OAuth (Facebook/Apple/Google) UI — backend only supports email + password.
- After each task: `flutter analyze` must report "No issues found!" and all existing tests touched by this plan must pass.

---

### Task 1: Restyle `LoginScreen` and fix the router test's stale title assertion

**Files:**
- Modify: `lib/features/auth/presentation/login_screen.dart` (full rewrite of `build`)
- Modify: `test/core/router/app_router_test.dart:35` (assertion depends on the old `AppBar` title text "Login", which this task removes)
- Test (regression check, unmodified): `test/features/auth/presentation/login_screen_test.dart`

**Interfaces:**
- Consumes: `authStateProvider` (`AsyncValue<UserModel?>` with `.hasError`, `.error`, `.isLoading`; notifier method `login({required String email, required String password})`) from `lib/features/auth/presentation/auth_provider.dart`. `context.go('/register')` from `go_router`.
- Produces: `LoginScreen` widget — same public constructor `const LoginScreen({super.key})`, same three `Key`s as before. No new exports.

- [ ] **Step 1: Run the existing widget test to confirm the current baseline passes**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: PASS (2 tests) — this is the pre-change baseline; the same file must still pass unmodified after the restyle.

- [ ] **Step 2: Replace `lib/features/auth/presentation/login_screen.dart`**

```dart
// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(ColorScheme colorScheme, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Log in to TikTok',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                key: const Key('login_email_field'),
                controller: _emailController,
                decoration: _fieldDecoration(colorScheme, 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('login_password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: _fieldDecoration(colorScheme, 'Password'),
              ),
              const SizedBox(height: 20),
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    authState.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                key: const Key('login_submit_button'),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authStateProvider.notifier).login(
                          email: _emailController.text,
                          password: _passwordController.text,
                        ),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Log in',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go('/register'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run the existing widget test to confirm it still passes unmodified**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: PASS (2 tests) — both tests only touch the three `Key`s and the error text, none of which changed.

- [ ] **Step 4: Fix the router test's stale title assertion**

`test/core/router/app_router_test.dart` line 35 currently reads:

```dart
    expect(find.text('Login'), findsOneWidget);
```

This asserted against the old `AppBar(title: Text('Login'))`, which Step 2 removed. Replace it with an assertion against text that still exists in the new `LoginScreen`:

```dart
    expect(find.text('Log in to TikTok'), findsOneWidget);
```

- [ ] **Step 5: Run the router test to confirm it passes**

Run: `flutter test test/core/router/app_router_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Run the full suite and analyzer**

Run: `flutter test`
Expected: all tests PASS (no count regression from before this task).

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/presentation/login_screen.dart test/core/router/app_router_test.dart
git commit -m "feat: restyle LoginScreen with TikTok-style visuals

Bold title, pill-shaped filled inputs, full-width pill submit button,
two-tone footer link — all via Theme.of(context).colorScheme so it
tracks AppTheme.dark's seeded primary color. No behavior or key
changes. Updates app_router_test.dart's stale 'Login' AppBar-title
assertion to match the new title text."
```

---

### Task 2: Restyle `RegisterScreen`

**Files:**
- Modify: `lib/features/auth/presentation/register_screen.dart` (full rewrite of `build`)
- Test (regression check, unmodified): `test/features/auth/presentation/register_screen_test.dart`

**Interfaces:**
- Consumes: `authStateProvider` notifier method `register({required String email, required String password, required String username})` from `lib/features/auth/presentation/auth_provider.dart` (same signature as before — unchanged by Task 1).
- Produces: `RegisterScreen` widget — same public constructor `const RegisterScreen({super.key})`, same four `Key`s as before. No new exports.

- [ ] **Step 1: Run the existing widget test to confirm the current baseline passes**

Run: `flutter test test/features/auth/presentation/register_screen_test.dart`
Expected: PASS (1 test) — pre-change baseline.

- [ ] **Step 2: Replace `lib/features/auth/presentation/register_screen.dart`**

```dart
// lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(ColorScheme colorScheme, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign up for TikTok',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                key: const Key('register_username_field'),
                controller: _usernameController,
                decoration: _fieldDecoration(colorScheme, 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('register_email_field'),
                controller: _emailController,
                decoration: _fieldDecoration(colorScheme, 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('register_password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: _fieldDecoration(colorScheme, 'Password'),
              ),
              const SizedBox(height: 20),
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    authState.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                key: const Key('register_submit_button'),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authStateProvider.notifier).register(
                          email: _emailController.text,
                          password: _passwordController.text,
                          username: _usernameController.text,
                        ),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run the existing widget test to confirm it still passes unmodified**

Run: `flutter test test/features/auth/presentation/register_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 4: Run the full suite and analyzer**

Run: `flutter test`
Expected: all tests PASS (no count regression from Task 1's ending state).

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/register_screen.dart
git commit -m "feat: restyle RegisterScreen with TikTok-style visuals

Bold title, pill-shaped filled inputs, full-width pill submit button —
same visual language as the LoginScreen restyle. No behavior or key
changes."
```

---

## Self-Review Notes

- **Spec coverage:** shared visual language (Task 1 + 2 both use `colorScheme` tokens,
  pill inputs, pill button), `LoginScreen` title/footer (Task 1), `RegisterScreen` title
  (Task 2), zero-behavior-change constraint (verified via unmodified pre-existing tests
  in both tasks), no phone/OAuth UI (neither task adds any), English copy (both tasks use
  English titles/labels).
- **Regression caught during planning:** `app_router_test.dart`'s signed-out test asserts
  `find.text('Login')` against the old `AppBar` title, which Task 1's restyle removes.
  Folded the fix into Task 1 (Step 4) rather than leaving it as a surprise test failure,
  matching how Task 18's `FeedScreen` regression was handled in the foundation plan.
- **Type consistency:** `login({required String email, required String password})` and
  `register({required String email, required String password, required String username})`
  signatures match `auth_provider.dart` exactly (unchanged from the foundation plan) —
  neither task modifies `auth_provider.dart`.
