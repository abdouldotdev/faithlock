import 'package:flutter/widgets.dart';

/// Global route observer so screens can react when they're revealed again after
/// a pushed route pops — e.g. the home "Today" dashboard refreshing its stats
/// once a prayer / feature-tour flow finishes and pops back to it.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
