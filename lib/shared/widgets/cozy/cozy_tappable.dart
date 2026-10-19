import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/theme/cozy/cozy.dart';

/// Adds the cozy press feel to any child: a subtle scale-down on tap-down
/// plus optional haptic feedback. Disabled when [onTap] is null.
class CozyTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool hapticFeedback;
  final double pressedScale;

  const CozyTappable({
    super.key,
    required this.child,
    this.onTap,
    this.hapticFeedback = true,
    this.pressedScale = 0.97,
  });

  @override
  State<CozyTappable> createState() => _CozyTappableState();
}

class _CozyTappableState extends State<CozyTappable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_enabled) return;
    if (widget.hapticFeedback) HapticFeedback.lightImpact();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? _handleTap : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: CozyTokens.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
