import 'package:flutter/widgets.dart';
import '../../journey_sdk.dart';
import '../core/time_utils.dart';

/// Flutter NavigatorObserver that automatically tracks screen route changes and dwell times.
class JourneyNavigatorObserver extends RouteObserver<PageRoute<dynamic>> {
  String? _currentRouteName;
  DateTime? _lastScreenEntryTime;

  /// Prefer explicit RouteSettings.name; fall back to runtimeType for unnamed routes.
  String? resolveRouteName(Route<dynamic>? route) {
    if (route == null) return null;
    final named = route.settings.name;
    if (named != null && named.trim().isNotEmpty && named != '/') {
      return named;
    }
    // MaterialPageRoute / CupertinoPageRoute without name — use widget type if possible
    final settingsName = route.settings.name;
    if (settingsName != null && settingsName.trim().isNotEmpty) {
      return settingsName;
    }
    final typeName = route.runtimeType.toString();
    // Skip generic opaque names that aren't useful
    if (typeName.startsWith('_')) return null;
    return typeName;
  }

  void _sendScreenView(Route<dynamic>? route, {Route<dynamic>? previousRoute}) {
    final String? routeName = resolveRouteName(route);
    if (routeName == null || routeName == _currentRouteName) return;

    final now = TimeUtils.utcNow();
    int? dwellTimeSeconds;
    if (_lastScreenEntryTime != null) {
      dwellTimeSeconds = now.difference(_lastScreenEntryTime!).inSeconds;
    }
    _lastScreenEntryTime = now;

    final prevName = _currentRouteName;
    _currentRouteName = routeName;

    JourneySDK.trackScreen(
      screenName: routeName,
      previousScreenName: prevName,
      metadata: {
        if (dwellTimeSeconds != null && dwellTimeSeconds > 0)
          'dwellTimeSeconds': dwellTimeSeconds,
        if (route?.settings.arguments != null) 'hasArguments': true,
        if (previousRoute != null)
          'navigationAction': previousRoute == route ? 'unknown' : 'transition',
      },
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route, previousRoute: previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sendScreenView(newRoute, previousRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sendScreenView(previousRoute, previousRoute: route);
    // Explicit back navigation signal
    final from = resolveRouteName(route);
    final to = resolveRouteName(previousRoute);
    if (from != null) {
      JourneySDK.track(
        'navigation_back',
        {
          'from': from,
          if (to != null) 'to': to,
        },
        'navigation',
      );
    }
  }
}