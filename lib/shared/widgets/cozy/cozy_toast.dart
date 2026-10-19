import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/cozy/cozy.dart';

/// Visual flavor of a [CozyToast].
enum CozyToastVariant { neutral, success, error }

/// Lightweight overlay toast — a crash-free replacement for GetX snackbars.
///
/// GetX's `SnackbarController` keeps a `late` AnimationController that throws a
/// `LateInitializationError` when a queued snackbar is closed during a route
/// pop (the classic "show a snackbar then immediately `Get.back()`" pattern, or
/// popping a screen while a snackbar is still on screen). This toast inserts
/// directly into the **root** [Overlay], so it survives route transitions and
/// never depends on GetX's fragile snackbar queue.
///
/// ```dart
/// CozyToast.show(context, 'Reflection saved', variant: CozyToastVariant.success);
/// ```
class CozyToast {
  CozyToast._();

  static OverlayEntry? _entry;

  /// Shows a toast anchored to the bottom of the screen. A new toast replaces
  /// any currently-visible one. Safe to call right before [Navigator.pop] —
  /// the root overlay outlives the popped route.
  static void show(
    BuildContext context,
    String message, {
    CozyToastVariant variant = CozyToastVariant.neutral,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    // Drop any toast that's still showing so they never stack.
    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CozyToastView(
        message: message,
        variant: variant,
        duration: duration,
        onDismissed: () {
          // Only clear the shared slot if this is still the active toast — a
          // newer toast may have already taken over.
          if (identical(_entry, entry)) _entry = null;
          entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _CozyToastView extends StatefulWidget {
  final String message;
  final CozyToastVariant variant;
  final Duration duration;
  final VoidCallback onDismissed;

  const _CozyToastView({
    required this.message,
    required this.variant,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_CozyToastView> createState() => _CozyToastViewState();
}

class _CozyToastViewState extends State<_CozyToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _c.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Color get _bg => switch (widget.variant) {
        CozyToastVariant.success => CozyColors.primary,
        CozyToastVariant.error => CozyColors.ink,
        CozyToastVariant.neutral => CozyColors.ink,
      };

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24 + media.padding.bottom,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _c,
          child: SlideTransition(
            position: slide,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: ShapeDecoration(
                  color: _bg,
                  shape: CozyTokens.smooth(CozyTokens.radiusMd),
                  shadows: CozyTokens.shadowHard,
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: CozyText.body.copyWith(
                    color: CozyColors.onPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
