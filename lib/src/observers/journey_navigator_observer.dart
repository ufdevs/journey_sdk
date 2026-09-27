import 'package:flutter/widgets.dart';
import '../../journey_sdk.dart';

/// Flutter NavigatorObserver that automatically tracks screen route changes and dwell times into JourneySDK
class JourneyNavigatorObserver extends RouteObserver<PageRoute<dynamic>> {
  String? _currentRouteName;
  DateTime? _lastScreenEntryTime;

  void _sendScreenView(Route<dynamic>? route, {Route<dynamic>? previousRoute}) {
    final String? routeName = route?.settings.name;
    if (routeName != null && routeName != _currentRouteName && routeName.trim().isNotEmpty) {
      final now = DateTime.now();
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
          if (route?.settings.arguments != null)
            'hasArguments': true,
        },
      );
    }
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
  }
}
