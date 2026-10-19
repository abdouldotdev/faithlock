import 'package:faithlock/features/companion/services/companion_voice_model_installer.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Loading dialog shown after first-run setup (when voice mode is on) while the
/// neural voice model downloads + unpacks. Pops `true` when ready, `false` if
/// the user taps "use basic voice" (the download keeps going in the background).
class CompanionVoiceDownloadDialog extends StatefulWidget {
  const CompanionVoiceDownloadDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CompanionVoiceDownloadDialog(),
    );
  }

  @override
  State<CompanionVoiceDownloadDialog> createState() =>
      _CompanionVoiceDownloadDialogState();
}

class _CompanionVoiceDownloadDialogState
    extends State<CompanionVoiceDownloadDialog> {
  double _progress = 0;

  final PostHogService _analytics = PostHogService.instance;

  void _track(String status) {
    if (_analytics.isReady) {
      _analytics.events
          .trackCustom('companion_voice_download', {'status': status});
    }
  }

  @override
  void initState() {
    super.initState();
    _track('started');
    CompanionVoiceModelInstaller().ensureInstalled(
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    ).then((_) {
      if (!mounted) return;
      _track('completed');
      Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    final unpacking = _progress >= 0.9 && _progress < 1.0;
    return Dialog(
      backgroundColor: CozyColors.background,
      shape: CozyTokens.smooth(
        CozyTokens.radiusLg,
        side: const BorderSide(
          color: CozyColors.outline,
          width: CozyTokens.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CozyTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: ShapeDecoration(
                color: CozyColors.peach,
                shape: CozyTokens.smooth(
                  20,
                  side: const BorderSide(
                    color: CozyColors.outline,
                    width: CozyTokens.borderWidth,
                  ),
                ),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedVolumeHigh,
                  color: CozyColors.ink,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: CozyTokens.space20),
            Text('Setting up your voice',
                style: CozyText.title, textAlign: TextAlign.center),
            const SizedBox(height: CozyTokens.space8),
            Text(
              unpacking
                  ? 'Almost there — unpacking…'
                  : 'Downloading the natural voice. Just once — it stays on your phone after.',
              style: CozyText.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CozyTokens.space20),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: unpacking ? null : _progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: CozyColors.surfaceMuted,
                color: CozyColors.primary,
              ),
            ),
            const SizedBox(height: CozyTokens.space8),
            Text('$pct%', style: CozyText.label),
            const SizedBox(height: CozyTokens.space16),
            TextButton(
              onPressed: () {
                _track('skipped');
                Navigator.of(context).pop(false);
              },
              child: Text('Use basic voice for now',
                  style: CozyText.body.copyWith(color: CozyColors.inkMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
