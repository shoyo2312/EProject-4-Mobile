import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';

/// The camera screen from the design.
///
/// Video-service has no upload endpoint wired into the app yet, so the
/// controls are presentational: the shutter toggles its own recording state
/// and nothing is sent anywhere. Everything else — layout, tokens, gestures —
/// is the finished screen, ready to hand a real capture pipeline.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  String _len = '60s';
  bool _recording = false;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        const StripedPlaceholder(label: 'camera preview', fontSize: 12),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99060508),
                Color(0x00060508),
                Color(0x00060508),
                Color(0xD9060508),
              ],
              stops: [0, 0.3, 0.6, 1],
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          top: top + 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                key: const Key('create_close_button'),
                onTap: widget.onClose,
                child: Glass(
                  radius: 12,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
              Glass(
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.audiotrack,
                        size: 14,
                        color: NowaColors.supportInk,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Add sound',
                        style: sora(size: 12.5, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Positioned(
          left: 14,
          top: top + 70,
          child: Column(
            children: [
              for (final t in const [
                ['Flip', 'w'],
                ['Speed', 's'],
                ['Filter', 'g'],
                ['Timer', 'd'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Glass(
                    radius: 15,
                    opacity: 0.45,
                    child: SizedBox(
                      width: 52,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: t[1] == 'g'
                                    ? const LinearGradient(
                                        colors: [
                                          NowaColors.accent,
                                          NowaColors.support,
                                        ],
                                      )
                                    : null,
                                color: t[1] == 'g'
                                    ? null
                                    : t[1] == 's'
                                        ? NowaColors.supportInk
                                            .withValues(alpha: 0.9)
                                        : Colors.white.withValues(
                                            alpha: t[1] == 'w' ? 0.85 : 0.55,
                                          ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t[0],
                              style: sora(
                                size: 9.5,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 44,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final l in ['15s', '60s', '3m'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _len = l),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: l == _len
                                ? NowaColors.accent.withValues(alpha: 0.9)
                                : const Color(0x73141218),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l,
                            style: sora(
                              size: 12,
                              weight: l == _len ? FontWeight.w600 : FontWeight.w500,
                              color: l == _len
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const StripedPlaceholder(radius: 13, band: 5),
                  ),
                  const SizedBox(width: 34),
                  GestureDetector(
                    key: const Key('create_record_button'),
                    onTap: () => setState(() => _recording = !_recording),
                    child: Container(
                      width: 82,
                      height: 82,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _recording
                            ? NowaColors.accent.withValues(alpha: 0.35)
                            : NowaColors.accent,
                        boxShadow: [
                          BoxShadow(
                            color: NowaColors.accent.withValues(alpha: 0.25),
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: _recording ? 30 : 68,
                        height: _recording ? 30 : 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_recording ? 9 : 34),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                  Glass(
                    radius: 23,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(Icons.center_focus_weak, size: 19),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _recording
                    ? 'Recording · $_len'
                    : 'Hold to record, tap for hands-free',
                style: sora(
                  size: 12,
                  weight: FontWeight.w500,
                  color: _recording
                      ? NowaColors.accent
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload is not connected yet',
                style: work(
                  size: 11,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
