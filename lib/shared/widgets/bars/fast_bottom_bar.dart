import 'dart:io';

import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// **FastBottomBar** - Platform-adaptive bottom navigation bar for app-wide navigation.
///
/// **Use Case:**
/// Primary navigation component for apps with 2-5 main sections. Automatically adapts to
/// platform conventions (CupertinoTabBar on iOS, BottomNavigationBar on Android) and
/// provides consistent navigation experience.
///
/// **Key Features:**
/// - Auto-adapts to platform design standards
/// - Clean tap interactions without splash effects
/// - Built-in haptic feedback on selection
/// - Supports icons and labels for each tab
/// - Maintains active/inactive state styling
///
/// **Important Parameters:**
/// - `currentIndex`: Currently selected tab index (required)
/// - `onTap`: Callback when tab is selected (required)
/// - `items`: List of navigation items with icon and label (required)
///
/// **Usage Example:**
/// ```dart
/// FastBottomBar(
///   currentIndex: selectedIndex,
///   onTap: (index) => setState(() => selectedIndex = index),
///   items: [
///     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
///     BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
///     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
///   ],
/// )
/// ```
class FastBottomBar extends StatelessWidget {
  final int currentIndex;

  final ValueChanged<int> onTap;

  final List<BottomNavigationBarItem> items;

  const FastBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        items: items,
        // null → system supplies the translucent/liquid-glass material.
        // On iOS 26+ (Xcode 26 SDK) this renders the new Liquid Glass blur;
        // on older SDKs it renders the standard frosted-glass translucency.
        // Do NOT set an opaque color here — that would defeat the effect.
        backgroundColor: null,
        activeColor: OnboardingTheme.goldColor,
        inactiveColor: CupertinoColors.inactiveGray,
        iconSize: 24,
        border: null,
      );
    } else {
      return Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            onTap(index);
          },
          items: items,
          type: BottomNavigationBarType.fixed,
          elevation: 8.0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          iconSize: 24,
        ),
      );
    }
  }
}
