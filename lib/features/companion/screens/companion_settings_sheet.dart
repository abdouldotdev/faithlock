import 'package:faithlock/features/companion/models/companion_settings.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Bottom sheet for the Companion's settings — translation + voice mode.
/// Used as the first-run setup (non-dismissible) and the in-chat gear.
/// Returns the updated [CompanionSettings], or null if dismissed.
class CompanionSettingsSheet extends StatefulWidget {
  final CompanionSettings initial;
  final bool firstRun;

  const CompanionSettingsSheet({
    super.key,
    required this.initial,
    this.firstRun = false,
  });

  static Future<CompanionSettings?> show(
    BuildContext context, {
    required CompanionSettings initial,
    bool firstRun = false,
  }) {
    return showModalBottomSheet<CompanionSettings>(
      context: context,
      isScrollControlled: true,
      // Keep the (tall, scroll-controlled) sheet clear of the status bar /
      // notch — the inner SafeArea alone doesn't inset a sheet that grows to
      // full height on first run.
      useSafeArea: true,
      isDismissible: !firstRun,
      enableDrag: !firstRun,
      backgroundColor: CozyColors.background,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(CozyTokens.radiusLg)),
      ),
      builder: (_) =>
          CompanionSettingsSheet(initial: initial, firstRun: firstRun),
    );
  }

  @override
  State<CompanionSettingsSheet> createState() => _CompanionSettingsSheetState();
}

class _CompanionSettingsSheetState extends State<CompanionSettingsSheet> {
  late int _versionIndex;
  late bool _voice;

  @override
  void initState() {
    super.initState();
    final idx = kCompanionVersions
        .indexWhere((v) => v.name == widget.initial.bibleVersion);
    _versionIndex = idx >= 0 ? idx : 0;
    _voice = widget.initial.voiceEnabled;
  }

  void _save() {
    Navigator.of(context).pop(widget.initial.copyWith(
      bibleVersion: kCompanionVersions[_versionIndex].name,
      voiceEnabled: _voice,
      configured: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CozyTokens.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.firstRun
                  ? 'companionSettings_meetTitle'.tr
                  : 'companionSettings_title'.tr,
              style: CozyText.title,
            ),
            const SizedBox(height: CozyTokens.space4),
            Text(
              widget.firstRun
                  ? 'companionSettings_firstRunSub'.tr
                  : 'companionSettings_sub'.tr,
              style: CozyText.subtitle,
            ),
            const SizedBox(height: CozyTokens.space24),
            Text('companionSettings_bibleTranslation'.tr, style: CozyText.label),
            const SizedBox(height: CozyTokens.space12),
            for (int i = 0; i < kCompanionVersions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: CozyTokens.space8),
                child: CozyChoiceCard(
                  title: kCompanionVersions[i].name,
                  // Compact rows: drop the subtitle and use a smaller leading
                  // chip so each card stays short.
                  leading: const CozyIconChip(
                    icon: HugeIcons.strokeRoundedBookOpen01,
                    size: 44,
                    iconSize: 22,
                  ),
                  selected: i == _versionIndex,
                  onTap: () => setState(() => _versionIndex = i),
                ),
              ),
            const SizedBox(height: CozyTokens.space12),
            Text('companionSettings_voice'.tr, style: CozyText.label),
            const SizedBox(height: CozyTokens.space12),
            _voiceToggle(),
            const SizedBox(height: CozyTokens.space24),
            CozyButton(
              text: widget.firstRun
                  ? 'companionSettings_start'.tr
                  : 'companionSettings_save'.tr,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceToggle() {
    return GestureDetector(
      onTap: () => setState(() => _voice = !_voice),
      child: Container(
        padding: const EdgeInsets.all(CozyTokens.space16),
        decoration: ShapeDecoration(
          color: CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusMd,
            side: const BorderSide(
              color: CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: _voice
                  ? HugeIcons.strokeRoundedVolumeHigh
                  : HugeIcons.strokeRoundedVolumeOff,
              color: CozyColors.ink,
              size: 24,
            ),
            const SizedBox(width: CozyTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('companionSettings_readAloud'.tr,
                      style: CozyText.heading),
                  Text('companionSettings_readAloudSub'.tr,
                      style: CozyText.subtitle),
                ],
              ),
            ),
            Switch.adaptive(
              value: _voice,
              activeTrackColor: CozyColors.primary,
              onChanged: (v) => setState(() => _voice = v),
            ),
          ],
        ),
      ),
    );
  }
}
