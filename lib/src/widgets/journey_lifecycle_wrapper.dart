import 'package:flutter/widgets.dart';
import '../../journey_sdk.dart';

/// Wraps the root app widget to automatically listen to app pause/resume lifecycle states
class JourneyLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const JourneyLifecycleWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<JourneyLifecycleWrapper> createState() => _JourneyLifecycleWrapperState();
}

class _JourneyLifecycleWrapperState extends State<JourneyLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        JourneySDK.handleLifecycleChange('resumed');
        break;
      case AppLifecycleState.paused:
        JourneySDK.handleLifecycleChange('paused');
        break;
      case AppLifecycleState.inactive:
        JourneySDK.handleLifecycleChange('inactive');
        break;
      case AppLifecycleState.detached:
        JourneySDK.handleLifecycleChange('detached');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
