/// **FastButton** - Universal cross-platform button with multiple styles and states.
///
/// **Use Case:** 
/// Primary action button for forms, CTAs, and interactions. Adapts to platform design 
/// conventions while providing consistent API. Supports different visual styles for 
/// various action types (primary, destructive, secondary).
///
/// **Key Features:**
/// - Cross-platform adaptation (CupertinoButton on iOS, Material buttons on Android)
/// - Multiple button styles: filled, outlined, plain, destructive
/// - Loading and disabled states with proper visual feedback
/// - Icon support with text
/// - Built-in haptic feedback
/// - Customizable colors, padding, and border radius
///
/// **Important Parameters:**
/// - `text`: Button text (can use with `child` for custom content)
/// - `onTap`: Callback when button is pressed (required for enabled state)
/// - `style`: Button style (filled, outlined, plain, destructive)
/// - `isLoading`: Shows loading spinner, disables interaction
/// - `isDisabled`: Disables button with visual feedback
/// - `backgroundColor`: Custom background color
/// - `textColor`: Custom text color
/// - `icon`: Optional icon widget displayed before text
/// - `width/height`: Custom button dimensions
///
/// **Usage Examples:**
/// ```dart
/// // Primary action button
/// FastButton(text: 'Save', onTap: () => save())
///
/// // Destructive action
/// FastButton(text: 'Delete', style: FastButtonStyle.destructive, onTap: () => delete())
///
/// // With icon and loading state
/// FastButton(
///   text: 'Upload', 
///   icon: Icon(Icons.upload),
///   isLoading: isUploading,
///   onTap: () => upload()
/// )
/// ```

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_corner/smooth_corner.dart';
import '../../../core/constants/export.dart';
import 'package:flutter/services.dart';

/// Button style for FastButton
enum FastButtonStyle {
  filled, // Default filled button
  destructive, // Destructive action (red)
  outlined, // Outlined button
  plain, // Plain text button
}

class FastButton extends StatelessWidget {
  final Widget? child;
  final String? text;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool isDisabled;
  final Color? disabledColor;
  final Color? loadingColor;
  final Widget? icon;
  final double? elevation;

  /// Button style (filled, destructive, outlined, plain)
  final FastButtonStyle style;

  /// Whether to add haptic feedback on tap (default: true)
  final bool hapticFeedback;

  const FastButton({
    super.key,
    this.backgroundColor,
    this.child,
    this.text,
    this.textColor,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.isDisabled = false,
    this.disabledColor,
    this.loadingColor,
    this.icon,
    this.elevation,
    this.style = FastButtonStyle.filled,
    this.hapticFeedback = true,
  });

  /// Default corner radius for the squircle curve.
  static const double _smoothRadius = 20.0;

  /// True iOS-style squircle (smooth continuous corners) used across all
  /// platforms/styles. Honors a caller-supplied [borderRadius] when provided.
  OutlinedBorder _smoothBorder({BorderSide side = BorderSide.none}) {
    return SmoothRectangleBorder(
      smoothness: 0.6,
      side: side,
      borderRadius: borderRadius ?? BorderRadius.circular(_smoothRadius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final bool isEnabled = !isDisabled && !isLoading && onTap != null;

    return isIOS
        ? _buildIOSButton(context, isEnabled)
        : _buildMaterialButton(context, isEnabled);
  }

  Widget _buildIOSButton(BuildContext context, bool isEnabled) {
    final colors = _getIOSColors(context, isEnabled);
    final buttonContent = _buildButtonContent(context, true);

    if (style == FastButtonStyle.outlined) {
      return Container(
        width: width,
        height: height ?? 42,
        decoration: ShapeDecoration(
          shape: _smoothBorder(
            side: BorderSide(
              color: isEnabled
                  ? colors.backgroundColor
                  : CupertinoColors.inactiveGray.resolveFrom(context),
              width: 1,
            ),
          ),
        ),
        child: CupertinoButton(
          onPressed: isEnabled ? _handleTap : null,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: buttonContent,
        ),
      );
    } else if (style == FastButtonStyle.plain) {
      return CupertinoButton(
        onPressed: isEnabled ? _handleTap : null,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: buttonContent,
      );
    } else {
      // Filled and destructive styles — true squircle corners.
      // CupertinoButton only accepts a BorderRadius, so the shape is painted
      // by a ShapeDecoration and the button just handles tap + press fade.
      // Full-width + comfortable height by default (primary CTA look).
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 56,
        child: CupertinoButton(
          onPressed: isEnabled ? _handleTap : null,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          borderRadius: BorderRadius.zero,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: isEnabled
                  ? colors.backgroundColor
                  : (disabledColor ??
                      CupertinoColors.inactiveGray.resolveFrom(context)),
              shape: _smoothBorder(),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              alignment: Alignment.center,
              child: buttonContent,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMaterialButton(BuildContext context, bool isEnabled) {
    final colors = _getMaterialColors(context, isEnabled);
    final buttonContent = _buildButtonContent(context, false);

    if (style == FastButtonStyle.outlined) {
      return OutlinedButton(
        onPressed: isEnabled ? _handleTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textColor,
          side: BorderSide(color: colors.backgroundColor),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: _smoothBorder(),
          minimumSize: Size(width ?? 48, height ?? 48),
        ),
        child: buttonContent,
      );
    } else if (style == FastButtonStyle.plain) {
      return TextButton(
        onPressed: isEnabled ? _handleTap : null,
        style: TextButton.styleFrom(
          foregroundColor: colors.textColor,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: _smoothBorder(),
          minimumSize: Size(width ?? 48, height ?? 48),
        ),
        child: buttonContent,
      );
    } else {
      // Filled and destructive styles
      return ElevatedButton(
        onPressed: isEnabled ? _handleTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.backgroundColor,
          foregroundColor: colors.textColor,
          elevation: elevation ?? 1,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: _smoothBorder(),
          minimumSize: Size(width ?? double.infinity, height ?? 56),
        ),
        child: buttonContent,
      );
    }
  }

  Widget _buildButtonContent(BuildContext context, bool isIOS) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: isIOS
            ? const CupertinoActivityIndicator(radius: 10)
            : CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  loadingColor ?? FastColors.staticWhite,
                ),
              ),
      );
    }

    final colors = isIOS
        ? _getIOSColors(context, !isDisabled && !isLoading && onTap != null)
        : _getMaterialColors(
            context, !isDisabled && !isLoading && onTap != null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        if (child != null)
          child!
        else
          Flexible(
            child: Text(
              text ?? "Button",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
      ],
    );
  }

  ({Color backgroundColor, Color textColor}) _getIOSColors(BuildContext context, bool isEnabled) {
    if (!isEnabled) {
      return (
        backgroundColor: disabledColor ?? CupertinoColors.inactiveGray.resolveFrom(context),
        textColor: FastColors.staticWhite,
      );
    }

    switch (style) {
      case FastButtonStyle.destructive:
        return (
          backgroundColor: backgroundColor ?? CupertinoColors.destructiveRed.resolveFrom(context),
          textColor: textColor ?? FastColors.staticWhite,
        );
      case FastButtonStyle.outlined:
      case FastButtonStyle.plain:
        return (
          backgroundColor: backgroundColor ?? CupertinoColors.activeBlue.resolveFrom(context),
          textColor: textColor ?? CupertinoColors.activeBlue.resolveFrom(context),
        );
      case FastButtonStyle.filled:
        return (
          backgroundColor: backgroundColor ?? CupertinoColors.activeBlue.resolveFrom(context),
          textColor: textColor ?? FastColors.staticWhite,
        );
    }
  }

  ({Color backgroundColor, Color textColor}) _getMaterialColors(
      BuildContext context, bool isEnabled) {
    if (!isEnabled) {
      return (
        backgroundColor: disabledColor ?? Theme.of(context).disabledColor,
        textColor: FastColors.staticWhite,
      );
    }

    switch (style) {
      case FastButtonStyle.destructive:
        return (
          backgroundColor: backgroundColor ?? Colors.red,
          textColor: textColor ?? FastColors.staticWhite,
        );
      case FastButtonStyle.outlined:
      case FastButtonStyle.plain:
        return (
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          textColor: textColor ?? Theme.of(context).primaryColor,
        );
      case FastButtonStyle.filled:
        return (
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          textColor: textColor ?? FastColors.staticWhite,
        );
    }
  }

  void _handleTap() {
    if (hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onTap?.call();
  }
}
