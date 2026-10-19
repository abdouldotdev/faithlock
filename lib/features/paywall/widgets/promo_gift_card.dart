import 'package:faithlock/app_routes.dart';
import 'package:faithlock/services/live_activity/promo_live_activity_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// In-app entry point for the welcome offer — drop it on the home screen.
///
/// This card is the **only** thing that starts the Live Activity: the user
/// taps "Reserve mine", which is an explicit, informed opt-in to a countdown
/// they will then see on their Lock Screen. Nothing arms itself silently.
///
/// Renders as a zero-height box for subscribers and for anyone who already
/// used their one reservation.
class PromoGiftCard extends StatefulWidget {
  const PromoGiftCard({super.key});

  @override
  State<PromoGiftCard> createState() => _PromoGiftCardState();
}

class _PromoGiftCardState extends State<PromoGiftCard> {
  final PromoLiveActivityService _service = PromoLiveActivityService.instance;

  bool _eligible = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final eligible = await _service.isEligible();
    if (mounted) setState(() => _eligible = eligible);
  }

  Future<void> _reserve() async {
    if (_busy) return;
    setState(() => _busy = true);

    await _service.reserveOffer();

    if (!mounted) return;
    setState(() {
      _busy = false;
      _eligible = false;
    });

    await Get.toNamed<void>(
      AppRoutes.promoOffer,
      arguments: <String, dynamic>{'source': 'home_card'},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CozyTokens.space8),
      child: CozyCard(
        padding: const EdgeInsets.all(18),
        onTap: _busy ? null : _reserve,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: ShapeDecoration(
                color: CozyColors.peach,
                shape: CozyTokens.smooth(
                  CozyTokens.radiusSm,
                  side: const BorderSide(
                    color: CozyColors.outline,
                    width: CozyTokens.borderWidthThin,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: const Text('🎁', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: CozyTokens.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A small gift, just for you',
                      style: CozyText.heading, maxLines: 1),
                  const SizedBox(height: 4),
                  Text(
                    'Reserve it and keep it for 8h',
                    style: CozyText.subtitle,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: CozyTokens.space8),
            if (_busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CozyColors.primary,
                ),
              )
            else
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: CozyColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
