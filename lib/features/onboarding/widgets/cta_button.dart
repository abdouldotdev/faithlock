import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Enhanced CTA button for onboarding with micro-interactions
class OnboardingCTAButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const OnboardingCTAButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
  });

  @override
  State<OnboardingCTAButton> createState() => _OnboardingCTAButtonState();
}

class _OnboardingCTAButtonState extends State<OnboardingCTAButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.mediumImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = GetPlatform.isIOS;
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: isEnabled
                    ? LinearGradient(
                        colors: isIOS
                            ? [
                                CupertinoColors.systemBlue,
                                CupertinoColors.systemBlue.darkColor,
                              ]
                            : [
                                Colors.blue,
                                Colors.blue.shade700,
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: !isEnabled
                    ? (isIOS ? CupertinoColors.systemGrey3 : Colors.grey[400])
                    : null,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color:
                              (isIOS ? CupertinoColors.systemBlue : Colors.blue)
                                  .withValues(alpha: _isPressed ? 0.6 : 0.3),
                          blurRadius: _isPressed ? 20 : 15,
                          offset: Offset(0, _isPressed ? 8 : 5),
                        ),
                      ]
                    : [],
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CupertinoActivityIndicator(
                          color: Colors.white,
                          radius: 12,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color:
                                  isEnabled ? Colors.white : Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                            child: Text(widget.text),
                          ),
                          if (widget.text.toLowerCase().contains('begin'.tr.toLowerCase()) ||
                              widget.text.toLowerCase().contains('start'.tr.toLowerCase())) ...[
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 300),
                              turns: _isPressed ? 0.1 : 0.0,
                              child: Icon(
                                isIOS
                                    ? CupertinoIcons.arrow_right
                                    : Icons.arrow_forward,
                                color:
                                    isEnabled ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
