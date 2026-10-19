import 'package:faithlock/config/logger.dart';
import 'package:faithlock/features/faithlock/screens/bible/cozy_bible_home_screen.dart';
import 'package:faithlock/features/faithlock/screens/cozy_home_screen.dart';
import 'package:faithlock/features/profile/screens/cozy_profile_screen.dart';
import 'package:faithlock/navigation/models/bottom_nav_item.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  static NavigationController get to => Get.find();

  final RxInt _currentIndex = 0.obs;
  final RxList<BottomNavItem> _navigationItems = <BottomNavItem>[].obs;

  int get currentIndex => _currentIndex.value;

  /// Reactive tab index — lets tab screens react to becoming visible (the shell
  /// keeps every tab mounted in an IndexedStack, so `initState` alone can't tell
  /// when a tab is actually shown).
  RxInt get currentIndexRx => _currentIndex;

  List<BottomNavItem> get navigationItems => _navigationItems;

  @override
  void onInit() {
    super.onInit();
    _initializeNavigationItems();
  }

  void _initializeNavigationItems() {
    _navigationItems.value = [
      BottomNavItem(
        label: 'Today',
        route: '/stats',
        page: const CozyHomeScreen(),
      ),
      BottomNavItem(
        label: 'Bible',
        route: '/bible',
        page: const CozyBibleHomeScreen(),
      ),
      // Index 2 is the "Pray" action slot — the bottom nav intercepts taps on
      // this index to open the prayer selector (see MainScreen), so this page
      // is never displayed. A placeholder keeps the IndexedStack child count
      // aligned with the four nav slots. (Library will live elsewhere.)
      BottomNavItem(
        label: 'nav_pray'.tr,
        route: '/pray',
        page: const SizedBox.shrink(),
      ),
      BottomNavItem(
        label: 'nav_profile'.tr,
        route: '/profile',
        page: CozyProfileScreen(),
      ),
    ];
  }

  void changePage(int index) {
    if (index < 0 || index >= _navigationItems.length) {
      logger.error('Invalid navigation index: $index');
      return;
    }

    _currentIndex.value = index;
  }

  Widget get currentPage => _navigationItems[currentIndex].page;

  Future<bool> onWillPop() async {
    if (currentIndex != 0) {
      changePage(0);
      return false;
    }
    return true;
  }
}
