import 'package:flutter/material.dart';

import '../../../shared/widgets/cozy/cozy.dart';
import '../controllers/grace_garden_controller.dart';

/// Judah — the app's lion mascot, here as the garden's humble companion/gardener.
///
/// IMPORTANT (spec §3): Judah is a created HELPER creature. The "Lion of Judah"
/// is a title of Christ (Rev 5:5), so Judah must NEVER be presented as, or
/// depicted as, God / Jesus / the Holy Spirit — only as a friend who tends
/// alongside you. Uses the existing mascot GIFs in assets/mascot/.
enum JudahMood { neutral, happy, praying, pointing, encouraging, proud, sad, sleeping }

const Map<JudahMood, String> _judahGif = {
  JudahMood.neutral: 'assets/mascot/judah_neutral.gif',
  JudahMood.happy: 'assets/mascot/judah_happy.gif',
  JudahMood.praying: 'assets/mascot/judah_praying.gif',
  JudahMood.pointing: 'assets/mascot/judah_pointing.gif',
  JudahMood.encouraging: 'assets/mascot/judah_encouraging.gif',
  JudahMood.proud: 'assets/mascot/judah_proud.gif',
  JudahMood.sad: 'assets/mascot/judah_sad.gif',
  JudahMood.sleeping: 'assets/mascot/judah_sleeping.gif',
};

/// Corner companion: Judah + an optional speech line. The animated speech-line
/// entrance from the prior placeholder is preserved.
class JudahCompanion extends StatefulWidget {
  final GraceGardenController c;
  final String? line;
  final JudahMood mood;
  final double size;

  const JudahCompanion({
    super.key,
    required this.c,
    this.line,
    this.mood = JudahMood.neutral,
    this.size = 72,
  });

  @override
  State<JudahCompanion> createState() => _JudahCompanionState();
}

class _JudahCompanionState extends State<JudahCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gif = _judahGif[widget.mood] ?? _judahGif[JudahMood.neutral]!;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -3 * _bob.value),
                child: child,
              ),
              child: Image.asset(
                gif,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
            ),
            if (widget.line != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedSwitcher(
                  duration: CozyTokens.base,
                  child: Container(
                    key: ValueKey(widget.line),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: ShapeDecoration(
                      color: CozyColors.surface,
                      shape: CozyTokens.smooth(CozyTokens.radiusMd,
                          side: const BorderSide(
                              color: CozyColors.outline,
                              width: CozyTokens.borderWidthThin)),
                    ),
                    child: Text(widget.line!, style: CozyText.subtitle),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        width: widget.size,
        height: widget.size,
        decoration: ShapeDecoration(
          color: CozyColors.primaryLight,
          shape: CozyTokens.smooth(CozyTokens.radiusPill,
              side: const BorderSide(
                  color: CozyColors.outline, width: CozyTokens.borderWidth)),
        ),
        alignment: Alignment.center,
        child: const Text('🦁', style: TextStyle(fontSize: 30)),
      );
}
