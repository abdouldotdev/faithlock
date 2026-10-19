import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/shared/widgets/animations/confetti_celebration.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Encouraging Bible verses for re-lock success (translated via GetX)
List<Map<String, String>> get encouragingVerses => [
      {'text': 'relock_verse1_text'.tr, 'reference': 'relock_verse1_ref'.tr},
      {'text': 'relock_verse2_text'.tr, 'reference': 'relock_verse2_ref'.tr},
      {'text': 'relock_verse3_text'.tr, 'reference': 'relock_verse3_ref'.tr},
      {'text': 'relock_verse4_text'.tr, 'reference': 'relock_verse4_ref'.tr},
      {'text': 'relock_verse5_text'.tr, 'reference': 'relock_verse5_ref'.tr},
      {'text': 'relock_verse6_text'.tr, 'reference': 'relock_verse6_ref'.tr},
      {'text': 'relock_verse7_text'.tr, 'reference': 'relock_verse7_ref'.tr},
      {'text': 'relock_verse8_text'.tr, 'reference': 'relock_verse8_ref'.tr},
      {'text': 'relock_verse9_text'.tr, 'reference': 'relock_verse9_ref'.tr},
      {
        'text': 'relock_verse10_text'.tr,
        'reference': 'relock_verse10_ref'.tr
      },
    ];

/// Screen displayed when re-locking apps after unlock timer expires.
/// Cozy (cream) redesign — no mascot; a chunky lock/checkmark badge carries the
/// moment. Automatically applies shields and navigates back to the main screen.
class RelockInProgressScreen extends StatefulWidget {
  const RelockInProgressScreen({super.key});

  @override
  State<RelockInProgressScreen> createState() => _RelockInProgressScreenState();
}

class _RelockInProgressScreenState extends State<RelockInProgressScreen>
    with SingleTickerProviderStateMixin {
  final ScreenTimeService _screenTimeService = ScreenTimeService();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isRelocking = true;
  bool _relockSuccess = false;
  String _statusMessage = '';

  late Map<String, String> _selectedVerse;

  @override
  void initState() {
    super.initState();

    _statusMessage = 'relock_inProgress'.tr;

    final random = Random();
    _selectedVerse =
        encouragingVerses[random.nextInt(encouragingVerses.length)];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
    _performRelock();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performRelock() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      await _screenTimeService.applyShields();

      setState(() {
        _isRelocking = false;
        _relockSuccess = true;
        _statusMessage = 'relock_success'.tr;
      });

      await Future.delayed(const Duration(seconds: 4));

      if (mounted) {
        Get.offAllNamed('/main');
      }
    } catch (e) {
      debugPrint('❌ Error re-locking apps: $e');

      setState(() {
        _isRelocking = false;
        _relockSuccess = false;
        _statusMessage = 'relock_error'.tr;
      });
    }
  }

  // ── Status badge (replaces the mascot) ─────────────────────────────────────
  Widget _statusBadge() {
    final List<List<dynamic>> icon;
    final Color bg;
    final Color fg;
    if (_isRelocking) {
      icon = HugeIcons.strokeRoundedSquareLock02;
      bg = CozyColors.peach;
      fg = CozyColors.primary;
    } else if (_relockSuccess) {
      icon = HugeIcons.strokeRoundedCheckmarkBadge01;
      bg = CozyColors.primary;
      fg = CozyColors.onPrimary;
    } else {
      icon = HugeIcons.strokeRoundedCancel01;
      bg = CozyColors.surfaceMuted;
      fg = CozyColors.inkMuted;
    }

    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: bg,
        shape: CozyTokens.smooth(
          CozyTokens.radiusLg,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        shadows: CozyTokens.shadowHard,
      ),
      child: HugeIcon(icon: icon, color: fg, size: 44),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Chunky status badge — a lock while re-locking, a checkmark on
                // success. No mascot.
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: _statusBadge(),
                  ),
                ),

                const SizedBox(height: 28),

                // Status message
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Text(
                    _statusMessage,
                    style: CozyText.title.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 14),

                // Loading indicator
                if (_isRelocking)
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: CozyColors.primary,
                      ),
                    ),
                  ),

                // Success message with Bible verse
                if (!_isRelocking && _relockSuccess) ...[
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      'relock_appsProtected'.tr,
                      style: CozyText.body.copyWith(color: CozyColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Cozy verse card
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      decoration: ShapeDecoration(
                        color: CozyColors.surface,
                        shape: CozyTokens.smooth(
                          CozyTokens.radiusLg,
                          side: const BorderSide(
                            color: CozyColors.outline,
                            width: CozyTokens.borderWidth,
                          ),
                        ),
                        shadows: CozyTokens.shadowHard,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '"${_selectedVerse['text']}"',
                            style: CozyText.body.copyWith(
                              fontSize: 17,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                              color: CozyColors.ink,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '— ${_selectedVerse['reference']}',
                            style: CozyText.label.copyWith(
                              color: CozyColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Error message with retry
                if (!_isRelocking && !_relockSuccess) ...[
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      'relock_errorOccurred'.tr,
                      style: CozyText.body.copyWith(color: CozyColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 22),
                  CozyButton(
                    text: 'retry'.tr,
                    fullWidth: false,
                    onTap: () {
                      setState(() {
                        _isRelocking = true;
                        _statusMessage = 'relock_inProgress'.tr;
                      });
                      _performRelock();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (_relockSuccess) {
      return ConfettiCelebration(child: scaffold);
    }

    return scaffold;
  }
}
