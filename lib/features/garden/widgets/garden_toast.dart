import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/cozy/cozy.dart';
import '../controllers/grace_garden_controller.dart';

/// OWNER: Dev2 (Experience & Flow).
///
/// Bottom toast that surfaces journey/practice messages (grace-framed, no
/// numbers). Reads controller.toast and slides up with a soft fade. Each message
/// auto-dismisses after a few seconds — but only if a newer message hasn't
/// replaced it, so the progressive sim feed never flickers.
class GardenToast extends StatefulWidget {
  final GraceGardenController c;
  const GardenToast({super.key, required this.c});

  @override
  State<GardenToast> createState() => _GardenToastState();
}

class _GardenToastState extends State<GardenToast> {
  static const _dwell = Duration(milliseconds: 3200);

  Worker? _worker;
  Timer? _dismiss;

  @override
  void initState() {
    super.initState();
    // Each new toast (re)arms the auto-dismiss. We capture the message so the
    // timer only clears it if it's still the one showing.
    _worker = ever<String?>(widget.c.toast, _arm);
  }

  void _arm(String? msg) {
    _dismiss?.cancel();
    if (msg == null) return;
    _dismiss = Timer(_dwell, () {
      if (widget.c.toast.value == msg) widget.c.setToast(null);
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _dismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = widget.c.toast.value;
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: msg == null
                ? const SizedBox(key: ValueKey('none'), height: 0)
                : _Bubble(key: ValueKey(msg), msg: msg),
          ),
        ),
      );
    });
  }
}

class _Bubble extends StatelessWidget {
  final String msg;
  const _Bubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: ShapeDecoration(
        color: CozyColors.ink,
        shape: CozyTokens.smooth(CozyTokens.radiusPill),
        shadows: CozyTokens.shadowSoft,
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: CozyText.body.copyWith(color: CozyColors.surface),
      ),
    );
  }
}
