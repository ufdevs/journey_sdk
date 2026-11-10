import 'package:flutter/material.dart';
import 'package:journey_sdk/journey_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize JourneySDK with unified embedded backend
  await JourneySDK.init(
    appId: 'example_app',
    debugLogging: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return JourneyLifecycleWrapper(
      child: MaterialApp(
        title: 'JourneySDK Demo',
        navigatorObservers: [JourneyNavigatorObserver()],
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JourneySDK Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                JourneySDK.track('button_clicked', {'screen': 'HomeScreen'});
              },
              child: const Text('Track Custom Event'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                JourneySDK.trackAd(
                  adType: 'rewarded_interstitial',
                  action: 'reward_earned',
                  rewardAmount: 50,
                  rewardType: 'Credits',
                );
              },
              child: const Text('Track Ad Reward'),
            ),
          ],
        ),
      ),
    );
  }
}
