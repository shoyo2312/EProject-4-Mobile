import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

/// The auth flow runs on a light palette (TikTok's own sign-in look), unlike
/// the dark feed the rest of the app uses — so it keeps its own tokens rather
/// than borrowing NowaColors.
class AuthColors {
  static const bg = Color(0xFFFFFFFF);
  static const field = Color(0xFFF1F1F2);
  static const footer = Color(0xFFF8F8F8);
  static const hairline = Color(0xFFE3E3E4);
  static const ink = Color(0xFF161823);
  static const inkDim = Color(0x99161823); // 60% ink
  static const hint = Color(0xFFA9A9AC);
  static const accent = Color(0xFFFE2C55);
  static const danger = Color(0xFFE23B4A);
}

/// Shared look for the auth flow: white page, grey surface fields, red CTA.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.onBack,
    this.footer,
  });

  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    // Light page => dark status bar glyphs.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AuthColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: onBack == null
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          color: AuthColors.ink,
                        ),
                      ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key, this.centered = false});

  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: sora(
        size: 27,
        weight: FontWeight.w700,
        height: 1.2,
        spacing: -0.6,
        color: AuthColors.ink,
      ),
    );
  }
}

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;

  /// Turns the field into a password field: text is masked and an eye button
  /// appears to reveal it.
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      cursorColor: AuthColors.accent,
      style: work(size: 15, height: 1.2, color: AuthColors.ink),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: work(size: 15, height: 1.2, color: AuthColors.hint),
        filled: true,
        fillColor: AuthColors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AuthColors.hint,
                ),
                tooltip: _obscured ? 'Show password' : 'Hide password',
              )
            : null,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

/// Accent when actionable, washed out when not — the disabled state is a
/// colour change, not a greyed-out Material button.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AuthColors.accent.withValues(alpha: enabled ? 1 : 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: sora(size: 15, color: Colors.white)),
      ),
    );
  }
}

/// One row in the "how do you want to continue?" list: a full-width surface
/// pill with a leading glyph and a centred label.
class AuthOptionButton extends StatelessWidget {
  const AuthOptionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AuthColors.field,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: icon)),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: sora(size: 14.5, weight: FontWeight.w600, color: AuthColors.ink),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

/// Google's "G" without pulling in an icon package or an asset — the letter in
/// Google blue reads well straight on the light pill.
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: sora(size: 20, weight: FontWeight.w700, color: const Color(0xFF4285F4)),
    );
  }
}

class FacebookGlyph extends StatelessWidget {
  const FacebookGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.facebook, size: 24, color: Color(0xFF1877F2));
  }
}

/// The "or" rule between the primary action and the provider list.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(color: AuthColors.hairline, height: 1));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: work(size: 13, color: AuthColors.inkDim)),
        ),
        line,
      ],
    );
  }
}

/// The legal small print that sits above the footer bar on the option screens.
class AuthTermsText extends StatelessWidget {
  const AuthTermsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'By continuing, you agree to our Terms of Service and confirm that you '
      'have read our Privacy Policy.',
      textAlign: TextAlign.center,
      style: work(size: 12, height: 1.5, color: AuthColors.inkDim),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message, style: work(size: 13, color: AuthColors.danger)),
    );
  }
}

class AuthInfoText extends StatelessWidget {
  const AuthInfoText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message, style: work(size: 13, color: AuthColors.accent)),
    );
  }
}

class AuthHelperText extends StatelessWidget {
  const AuthHelperText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: work(size: 13, height: 1.5, color: AuthColors.inkDim),
    );
  }
}

/// A quiet, centred link — "Forgot password?", "Resend code".
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.label,
    required this.onTap,
    this.align = Alignment.center,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final Alignment align;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: align,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: work(
            size: 13,
            weight: accent ? FontWeight.w600 : FontWeight.w400,
            color: accent ? AuthColors.accent : AuthColors.inkDim,
          ),
        ),
      ),
    );
  }
}

/// The bar pinned to the bottom: "Don't have an account? Sign up".
class AuthFooterBar extends StatelessWidget {
  const AuthFooterBar({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AuthColors.footer,
        border: Border(top: BorderSide(color: AuthColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(question, style: work(size: 13.5, color: AuthColors.inkDim)),
          GestureDetector(
            onTap: onTap,
            child: Text(
              ' $actionLabel',
              style: sora(size: 13.5, color: AuthColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
