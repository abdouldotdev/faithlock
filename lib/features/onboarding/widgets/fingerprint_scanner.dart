import 'dart:async';
import 'dart:ui';

import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Fingerprint scanner widget with animated scanning effect
class FingerprintScanner extends StatefulWidget {
  final String userName;
  final VoidCallback onComplete;

  const FingerprintScanner({
    super.key,
    required this.userName,
    required this.onComplete,
  });

  @override
  State<FingerprintScanner> createState() => _FingerprintScannerState();
}

class _FingerprintScannerState extends State<FingerprintScanner>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _sealController;
  late Animation<double> _scanAnimation;
  late Animation<double> _sealAnimation;

  bool _isScanning = false;
  bool _scanComplete = false;
  bool _showButton = false;
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 3500), 
      vsync: this,
    );
    _sealController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _sealAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sealController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _scanController.dispose();
    _sealController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final locale = Get.locale?.languageCode ?? 'en';
    if (locale == 'fr') {
      final months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      return '${now.day} ${months[now.month - 1]} ${now.year}';
    }
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    await AnimationUtils.mediumHaptic();

    _hapticTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      AnimationUtils.lightHaptic();
    });

    _scanController.forward();

    await Future.delayed(const Duration(milliseconds: 3500));

    _hapticTimer?.cancel();
    _hapticTimer = null;

    setState(() {
      _scanComplete = true;
      _isScanning = false;
    });

    await AnimationUtils.heavyHaptic();

    await _sealController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Final success haptic
    await AnimationUtils.heavyHaptic();

    // Wait 2 seconds for user to read the covenant, then show button
    await Future.delayed(const Duration(milliseconds: 2000));

    setState(() => _showButton = true);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onLongPressStart: (_) => _startScan(),
        behavior: HitTestBehavior.opaque,
        child: _scanComplete
            ? // Show paper document standalone after scan complete
            AnimatedBuilder(
                animation: _sealAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sealAnimation.value,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD4C4A8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 0,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '✦',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: const Color(0xFF8B7355),
                                  ),
                                ),
                                Text(
                                  'covenant_sacredTitle'.tr,
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2C1810),
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '✦',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: const Color(0xFF8B7355),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Texte du contrat - Style manuscrit
                          Text(
                            'covenant_pledgeText'.trParams({'name': widget.userName}),
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 14,
                              height: 1.8,
                              color: const Color(0xFF3D2817),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.justify,
                          ),

                          const SizedBox(height: 32),

                          // Divider décoratif
                          Center(
                            child: Container(
                              width: 200,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFFB8997F),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Bas du document: Signature, Date, Sceau
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Colonne gauche: Signature et Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Signature
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: const Color(0xFF8B7355),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            widget.userName,
                                            style: TextStyle(
                                              fontFamily: 'Snell Roundhand',
                                              fontSize: 26,
                                              color: const Color(0xFF1A0D08),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'covenant_signature'.tr,
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            fontSize: 10,
                                            color: const Color(0xFF6B5540),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Date
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getCurrentDate(),
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            fontSize: 13,
                                            color: const Color(0xFF2C1810),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'covenant_date'.tr,
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            fontSize: 10,
                                            color: const Color(0xFF6B5540),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Sceau officiel - Style cire
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  // Effet de cire rouge/or
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFD4AF37), // Or
                                      const Color(0xFFC9A962),
                                      const Color(0xFFB8997F),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB8997F)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                    // Ombre interne pour effet 3D
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Cercle intérieur
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF8B7355),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    // Texte du sceau
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 32,
                                          color: const Color(0xFF2C1810),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'covenant_sealed'.tr,
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF2C1810),
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Instructions
                          Center(
                            child: Text(
                              'covenant_sealedBeforeGod'.tr,
                              style: CozyText.body.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CozyColors.primary,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Button appears after 2 seconds
                          if (_showButton) ...[
                            const SizedBox(height: 24),
                            CozyButton(
                              text: 'covenant_readyLockIn'.tr,
                              onTap: widget.onComplete,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              )
            : // Show fingerprint scanner with gold container before scan
            Container(
                width: double.infinity, // Width fixe pour éviter le changement
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  minHeight: 320,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(OnboardingTheme.radiusXLarge),
                  border: Border.all(
                    color: OnboardingTheme.goldColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(OnboardingTheme.radiusXLarge),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            OnboardingTheme.cardBackground,
                            OnboardingTheme.cardBackground
                                .withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Fingerprint icon with scanning animation
                          SizedBox(
                            height: 140,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Fingerprint icon with glow
                                AnimatedOpacity(
                                  opacity: _isScanning ? 1.0 : 0.9,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.fingerprint,
                                    size: 100,
                                    color: CozyColors.primary,
                                  ),
                                ),
                                // Scanning line
                                if (_isScanning)
                                  AnimatedBuilder(
                                    animation: _scanAnimation,
                                    builder: (context, child) {
                                      return Positioned(
                                        top: 120 * _scanAnimation.value,
                                        child: Container(
                                          width: 120,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                OnboardingTheme.goldColor
                                                    .withValues(alpha: 0.9),
                                                Colors.transparent,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: OnboardingTheme.goldColor
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 15,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Instructions
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isScanning
                                  ? 'covenant_scanning'.tr
                                  : 'covenant_holdThumb'.tr,
                              key: ValueKey<String>(
                                  _isScanning ? 'scanning' : 'waiting'),
                              style: CozyText.body.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: CozyColors.primary,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
